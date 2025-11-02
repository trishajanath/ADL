import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  /// Check if an email already exists in the system
  static Future<bool> checkEmailExists(String email) async {
    try {
      print('🔍 Checking if email exists: $email');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/users/check-email?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final exists = data['exists'] as bool;
        print('${exists ? '✅' : '❌'} Email $email ${exists ? 'exists' : 'is available'}');
        return exists;
      } else {
        print('❌ Failed to check email: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error checking email: $e');
      return false;
    }
  }

  /// Register a new user
  static Future<Map<String, dynamic>?> registerUser({
    required String email,
    required String name,
    String? password,
    String authProvider = 'email',
  }) async {
    try {
      print('📝 Registering user: $name ($email) via $authProvider');
      
      final body = {
        'email': email,
        'name': name,
        'auth_provider': authProvider,
      };
      
      // Add password for email registration
      if (authProvider == 'email' && password != null) {
        body['password'] = password;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ User registered successfully');
        return data;
      } else if (response.statusCode == 409) {
        print('❌ Email already exists');
        return {'error': 'Email already exists'};
      } else {
        print('❌ Failed to register user: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error registering user: $e');
      return null;
    }
  }

  /// Update user's last login time
  static Future<Map<String, dynamic>?> loginUser(String email, {String? password}) async {
    try {
      print('🔑 Logging in user: $email');
      
      final body = {'email': email};
      if (password != null) {
        body['password'] = password;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('${data['success'] ? '✅' : '❌'} ${data['message']}');
        return data;
      } else {
        print('❌ Failed to login: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error during login: $e');
      return null;
    }
  }
}
