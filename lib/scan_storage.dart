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
  static const String _scansKey = 'questionnaire_scans';

  // Save a new scan result
  static Future<void> saveScan(ScanResult scan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> existingScans = prefs.getStringList(_scansKey) ?? [];
      
      // Add new scan to the beginning of the list (most recent first)
      existingScans.insert(0, jsonEncode(scan.toJson()));
      
      // Keep only the last 20 scans to avoid excessive storage
      if (existingScans.length > 20) {
        existingScans = existingScans.take(20).toList();
      }
      
      await prefs.setStringList(_scansKey, existingScans);
      print('✅ Scan saved successfully: ${scan.projectName}');
    } catch (e) {
      print('❌ Error saving scan: $e');
    }
  }

  // Load all saved scans
  static Future<List<ScanResult>> loadScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> scanStrings = prefs.getStringList(_scansKey) ?? [];
      
      List<ScanResult> scans = scanStrings.map((scanString) {
        return ScanResult.fromJson(jsonDecode(scanString));
      }).toList();
      
      print('📂 Loaded ${scans.length} saved scans');
      return scans;
    } catch (e) {
      print('❌ Error loading scans: $e');
      return [];
    }
  }

  // Delete a specific scan
  static Future<void> deleteScan(String scanId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> existingScans = prefs.getStringList(_scansKey) ?? [];
      
      existingScans.removeWhere((scanString) {
        final scan = ScanResult.fromJson(jsonDecode(scanString));
        return scan.id == scanId;
      });
      
      await prefs.setStringList(_scansKey, existingScans);
      print('🗑️ Scan deleted successfully: $scanId');
    } catch (e) {
      print('❌ Error deleting scan: $e');
    }
  }

  // Update an existing scan
  static Future<void> updateScan(ScanResult updatedScan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> existingScans = prefs.getStringList(_scansKey) ?? [];
      
      for (int i = 0; i < existingScans.length; i++) {
        final scan = ScanResult.fromJson(jsonDecode(existingScans[i]));
        if (scan.id == updatedScan.id) {
          existingScans[i] = jsonEncode(updatedScan.toJson());
          break;
        }
      }
      
      await prefs.setStringList(_scansKey, existingScans);
      print('✏️ Scan updated successfully: ${updatedScan.projectName}');
    } catch (e) {
      print('❌ Error updating scan: $e');
    }
  }

  // Clear all scans
  static Future<void> clearAllScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scansKey);
      print('🧹 All scans cleared');
    } catch (e) {
      print('❌ Error clearing scans: $e');
    }
  }
}