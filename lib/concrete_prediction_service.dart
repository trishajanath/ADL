// concrete_prediction_service.dart
// Add this to your Flutter app to integrate with the backend

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ConcretePredictionService {
  // 🔧 DEVELOPMENT CONFIGURATION
  // For testing on same device (simulator/emulator):
  // static const String baseUrl = "http://localhost:8000";
  
  // 🌐 NETWORK CONFIGURATION  
  // For testing on real device (phone), using local network IP:
  static const String baseUrl = "http://127.0.0.1:8000";
  
  // Model for prediction request
  static Future<Map<String, dynamic>> predictConcreteGrade({
    required String buildingType,
    required String floors,
    required String soilType,
    required String seismicZone,
    required String exposure,
    required String loadType,
    required int builtUpArea,
  }) async {
    try {
      print('🔍 Making prediction request...');
      
      final requestData = {
        'building_type': buildingType,
        'floors': floors,
        'soil_type': soilType,
        'seismic_zone': seismicZone,
        'exposure': exposure,
        'load_type': loadType,
        'built_up_area': builtUpArea,
      };
      
      print('📤 Request data: ${jsonEncode(requestData)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/predict'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 30));

      print('📨 Response status: ${response.statusCode}');
      print('📨 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Prediction failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Prediction error: $e');
      throw Exception('Failed to get prediction: $e');
    }
  }

  // Check if the ML model is loaded and ready
  static Future<Map<String, dynamic>> checkModelStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/model/status'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Status check failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to check model status: $e');
    }
  }

  // Test connection to the backend
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
}

// Example function to use in your existing widgets
Future<void> examplePredictionUsage() async {
  try {
    print('🧪 Testing prediction service...');
    
    // Test connection first
    bool isConnected = await ConcretePredictionService.testConnection();
    if (!isConnected) {
      print('❌ Cannot connect to backend server');
      return;
    }
    print('✅ Connection successful');

    // Check model status
    var status = await ConcretePredictionService.checkModelStatus();
    print('📊 Model status: ${status['model_loaded']}');

    // Make prediction
    final result = await ConcretePredictionService.predictConcreteGrade(
      buildingType: 'House',
      floors: 'G+2',
      soilType: 'Any',
      seismicZone: 'Zone III',
      exposure: 'Moderate',
      loadType: 'Regular Household',
      builtUpArea: 1500,
    );

    print('✅ Prediction Result:');
    print('   Grade: ${result['prediction']['concrete_grade']}');
    print('   Confidence: ${result['prediction']['confidence_percentage']}');
    print('   Cost: ${result['cost_estimation']['total_estimated_cost']}');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}

/*
HOW TO USE IN YOUR EXISTING FLUTTER APP:

1. Add this file to your lib/ folder
2. In your widget where you want to make predictions, import this file:
   import 'concrete_prediction_service.dart';

3. Use it in your questionnaire submission or button press:

   // Example usage in a button onPressed:
   onPressed: () async {
     try {
       showDialog(
         context: context,
         barrierDismissible: false,
         builder: (_) => AlertDialog(
           content: Row(
             children: [
               CircularProgressIndicator(),
               SizedBox(width: 16),
               Text('Getting prediction...'),
             ],
           ),
         ),
       );

       final result = await ConcretePredictionService.predictConcreteGrade(
         buildingType: selectedBuildingType,
         floors: selectedFloors,
         soilType: selectedSoilType,
         seismicZone: selectedSeismicZone,
         exposure: selectedExposure,
         loadType: selectedLoadType,
         builtUpArea: builtUpArea,
       );

       Navigator.pop(context); // Close loading dialog

       // Show results
       showDialog(
         context: context,
         builder: (_) => AlertDialog(
           title: Text('Prediction Result'),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text('Concrete Grade: ${result['prediction']['concrete_grade']}'),
               Text('Confidence: ${result['prediction']['confidence_percentage']}'),
               Text('Estimated Cost: ${result['cost_estimation']['total_estimated_cost']}'),
             ],
           ),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(context),
               child: Text('OK'),
             ),
           ],
         ),
       );
     } catch (e) {
       Navigator.pop(context); // Close loading dialog
       
       showDialog(
         context: context,
         builder: (_) => AlertDialog(
           title: Text('Error'),
           content: Text('Failed to get prediction: $e'),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(context),
               child: Text('OK'),
             ),
           ],
         ),
       );
     }
   }
*/