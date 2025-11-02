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
  String get estimatedCost => predictionResult['cost_estimation']?['total_estimated_cost'] ?? 'N/A';
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