// scan_storage.dart
// Local storage management for questionnaire scans

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScanResult {
  final String id;
  final String category; // 'residential' or 'commercial'
  final DateTime timestamp;
  final Map<String, dynamic> questionnaireData;
  final Map<String, dynamic> predictionResult;
  final String projectName;

  ScanResult({
    required this.id,
    required this.category,
    required this.timestamp,
    required this.questionnaireData,
    required this.predictionResult,
    required this.projectName,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'],
      category: json['category'],
      timestamp: DateTime.parse(json['timestamp']),
      questionnaireData: json['questionnaireData'],
      predictionResult: json['predictionResult'],
      projectName: json['projectName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'questionnaireData': questionnaireData,
      'predictionResult': predictionResult,
      'projectName': projectName,
    };
  }

  // Getters for easy access to prediction data
  String get concreteGrade => predictionResult['prediction']?['concrete_grade'] ?? 'N/A';
  String get confidence => predictionResult['prediction']?['confidence_percentage'] ?? 'N/A';
  String get estimatedCost {
    try {
      // Debug: Print the entire prediction result structure
      print('🔍 Checking cost in predictionResult: ${predictionResult.keys}');
      
      // Check for cost_estimation object (new format)
      if (predictionResult['cost_estimation'] != null) {
        final costEstimation = predictionResult['cost_estimation'];
        print('💰 Found cost_estimation: ${costEstimation.keys}');
        
        if (costEstimation['total_estimated_cost'] != null) {
          final cost = costEstimation['total_estimated_cost'];
          print('✅ Found cost: $cost');
          return _formatIndianCurrency(cost);
        }
      }
      
      // Check for direct total_estimated_cost (alternative format)
      if (predictionResult['total_estimated_cost'] != null) {
        final cost = predictionResult['total_estimated_cost'];
        print('✅ Found direct cost: $cost');
        return _formatIndianCurrency(cost);
      }
      
      // Check if it's in the prediction object
      if (predictionResult['prediction']?['total_estimated_cost'] != null) {
        final cost = predictionResult['prediction']['total_estimated_cost'];
        print('✅ Found cost in prediction: $cost');
        return _formatIndianCurrency(cost);
      }
      
      // Check for any field with 'cost' in the name
      for (var key in predictionResult.keys) {
        if (key.toLowerCase().contains('cost')) {
          print('💡 Found cost-related field: $key = ${predictionResult[key]}');
          if (predictionResult[key] is Map) {
            final costMap = predictionResult[key] as Map;
            for (var subKey in costMap.keys) {
              if (subKey.toLowerCase().contains('total') || subKey.toLowerCase().contains('estimated')) {
                print('✅ Using: $subKey = ${costMap[subKey]}');
                return _formatIndianCurrency(costMap[subKey]);
              }
            }
          }
        }
      }
      
      print('❌ No cost data found in any expected location');
      print('📋 Full prediction result keys: ${predictionResult.keys}');
      return 'Cost data not available';
    } catch (e) {
      print('❌ Error getting cost: $e');
      return 'Cost data not available';
    }
  }

  // Helper method to format currency in Indian numbering system
  String _formatIndianCurrency(dynamic cost) {
    try {
      // Extract numeric value from string if needed
      String costStr = cost.toString();
      
      // Remove currency symbols and text
      costStr = costStr.replaceAll(RegExp(r'[^\d.]'), '');
      
      double amount = double.parse(costStr);
      
      // Multiply by 10 to add an extra zero (increase cost)
      amount = amount * 10;
      
      // Format in Indian numbering system
      if (amount >= 10000000) {
        // Crores
        double crores = amount / 10000000;
        return '₹${crores.toStringAsFixed(2)} Cr';
      } else if (amount >= 100000) {
        // Lakhs
        double lakhs = amount / 100000;
        return '₹${_formatWithCommas(lakhs.toStringAsFixed(2))} L';
      } else if (amount >= 1000) {
        // Thousands
        double thousands = amount / 1000;
        return '₹${_formatWithCommas(thousands.toStringAsFixed(2))} K';
      } else {
        return '₹${amount.toStringAsFixed(0)}';
      }
    } catch (e) {
      print('❌ Error formatting currency: $e');
      return cost.toString();
    }
  }

  // Format number with Indian comma system (XX,XX,XXX)
  String _formatWithCommas(String number) {
    List<String> parts = number.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';
    
    // Remove leading zeros after decimal if they exist
    if (decimalPart == '.00') {
      decimalPart = '';
    }
    
    // For Indian format: last 3 digits, then groups of 2
    if (integerPart.length <= 3) {
      return integerPart + decimalPart;
    }
    
    String lastThree = integerPart.substring(integerPart.length - 3);
    String remaining = integerPart.substring(0, integerPart.length - 3);
    
    // Add commas for every 2 digits in the remaining part
    String formatted = '';
    for (int i = remaining.length - 1; i >= 0; i -= 2) {
      if (i == 0) {
        formatted = remaining[i] + formatted;
      } else {
        formatted = remaining.substring(i - 1, i + 1) + ',' + formatted;
      }
    }
    
    return formatted + ',' + lastThree + decimalPart;
  }

  String get builtUpArea => questionnaireData['built_up_area']?.toString() ?? 'N/A';
  String get buildingType => questionnaireData['building_type'] ?? 'N/A';
  String get floors => questionnaireData['floors'] ?? 'N/A';
}

class ScanStorage {
  static const String _scansKeyPrefix = 'questionnaire_scans_';
  
  // Get user-specific key
  static String _getUserScansKey(String userId) {
    return '$_scansKeyPrefix$userId';
  }

  // Save a new scan result for a specific user
  static Future<void> saveScan(ScanResult scan, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserScansKey(userId);
      List<String> existingScans = prefs.getStringList(userKey) ?? [];
      
      // Add new scan to the beginning of the list (most recent first)
      existingScans.insert(0, jsonEncode(scan.toJson()));
      
      // Keep only the last 20 scans to avoid excessive storage
      if (existingScans.length > 20) {
        existingScans = existingScans.take(20).toList();
      }
      
      await prefs.setStringList(userKey, existingScans);
      print('✅ Scan saved successfully for user $userId: ${scan.projectName}');
    } catch (e) {
      print('❌ Error saving scan: $e');
    }
  }

  // Load all saved scans for a specific user
  static Future<List<ScanResult>> loadScans(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserScansKey(userId);
      List<String> scanStrings = prefs.getStringList(userKey) ?? [];
      
      List<ScanResult> scans = scanStrings.map((scanString) {
        return ScanResult.fromJson(jsonDecode(scanString));
      }).toList();
      
      print('📂 Loaded ${scans.length} saved scans for user $userId');
      return scans;
    } catch (e) {
      print('❌ Error loading scans: $e');
      return [];
    }
  }

  // Delete a specific scan for a user
  static Future<void> deleteScan(String scanId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserScansKey(userId);
      List<String> existingScans = prefs.getStringList(userKey) ?? [];
      
      existingScans.removeWhere((scanString) {
        final scan = ScanResult.fromJson(jsonDecode(scanString));
        return scan.id == scanId;
      });
      
      await prefs.setStringList(userKey, existingScans);
      print('🗑️ Scan deleted successfully for user $userId: $scanId');
    } catch (e) {
      print('❌ Error deleting scan: $e');
    }
  }

  // Update an existing scan for a user
  static Future<void> updateScan(ScanResult updatedScan, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserScansKey(userId);
      List<String> existingScans = prefs.getStringList(userKey) ?? [];
      
      for (int i = 0; i < existingScans.length; i++) {
        final scan = ScanResult.fromJson(jsonDecode(existingScans[i]));
        if (scan.id == updatedScan.id) {
          existingScans[i] = jsonEncode(updatedScan.toJson());
          break;
        }
      }
      
      await prefs.setStringList(userKey, existingScans);
      print('✏️ Scan updated successfully for user $userId: ${updatedScan.projectName}');
    } catch (e) {
      print('❌ Error updating scan: $e');
    }
  }

  // Clear all scans for a specific user
  static Future<void> clearAllScans(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserScansKey(userId);
      await prefs.remove(userKey);
      print('🧹 All scans cleared for user $userId');
    } catch (e) {
      print('❌ Error clearing scans: $e');
    }
  }

  // Check if a scan name already exists for a user (excluding a specific scan ID for updates)
  static Future<bool> scanNameExists(String projectName, String userId, {String? excludeScanId}) async {
    try {
      final scans = await loadScans(userId);
      return scans.any((scan) => 
        scan.projectName.toLowerCase() == projectName.toLowerCase() && 
        scan.id != excludeScanId
      );
    } catch (e) {
      print('❌ Error checking scan name: $e');
      return false;
    }
  }
}