import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  static const String _apiKey = 'AIzaSyDjpw8FsfA36zkG6et4Mi7x-sqbf9mWKuc';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  
  static Future<void> listAvailableModels() async {
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey'),
      );
      
      print('Available models response: ${response.statusCode}');
      print('Models: ${response.body}');
    } catch (e) {
      print('Error listing models: $e');
    }
  }

  static Future<String> sendMessage(String message, {String? predictionContext}) async {
    http.Response? response;
    try {
      final contextualMessage = predictionContext != null 
        ? 'Based on this concrete prediction: $predictionContext\n\nUser question: $message'
        : message;

      response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': contextualMessage
            }]
          }]
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return 'API Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      print('Chatbot error: $e');
      print('Response status: ${response?.statusCode}');
      print('Response body: ${response?.body}');
      return 'Error: $e';
    }
  }
}