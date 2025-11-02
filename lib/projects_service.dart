// lib/projects_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:my_app/models/project.dart';

class ProjectsService {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  /// Create a new project
  static Future<Map<String, dynamic>?> createProject({
    required String name,
    required String location,
    required String projectType,
    required double budget,
    String description = '',
    required String userId,
  }) async {
    try {
      print('🏗️ Creating new project: $name for user $userId');
      print('📝 Request body: name=$name, location=$location, type=$projectType, budget=$budget, user_id=$userId');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/projects'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'location': location,
          'project_type': projectType,
          'budget': budget,
          'description': description,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Project created successfully: ${data['project_id']}');
        print('📋 Response data: $data');
        return data;
      } else {
        print('❌ Failed to create project: ${response.statusCode}');
        print('Error response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Error creating project: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get all projects for a specific user
  static Future<List<Project>> getProjects(String userId) async {
    try {
      print('📂 Fetching projects for user $userId...');
      print('🔗 API URL: $_baseUrl/api/v1/projects?user_id=$userId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/projects?user_id=$userId'),
      );

      print('📥 Response status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final List<dynamic> projectsData = data['projects'] ?? [];
          print('📊 Raw projects data: $projectsData');
          
          List<Project> projects = projectsData
              .map((json) => Project.fromJson(json))
              .toList();
          
          print('✅ Retrieved ${projects.length} projects');
          if (projects.isNotEmpty) {
            print('📋 First project: ${projects[0].name}');
          }
          return projects;
        } else {
          print('❌ API returned success=false');
          return [];
        }
      } else {
        print('❌ Failed to get projects: ${response.statusCode}');
        print('Error body: ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      print('❌ Error getting projects: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get a specific project by ID
  static Future<Project?> getProject(int projectId) async {
    try {
      print('📂 Fetching project $projectId...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/projects/$projectId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          Project project = Project.fromJson(data['project']);
          print('✅ Retrieved project: ${project.name}');
          return project;
        } else {
          print('❌ API returned success=false');
          return null;
        }
      } else if (response.statusCode == 404) {
        print('❌ Project not found: $projectId');
        return null;
      } else {
        print('❌ Failed to get project: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting project: $e');
      return null;
    }
  }

  /// Format currency for display
  static String formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  /// Format date for display
  static String formatDate(String isoDate) {
    try {
      DateTime date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  /// Get status color based on project status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'planning':
        return Colors.blue;
      case 'in progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'on hold':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get status icon based on project status
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'planning':
        return Icons.design_services;
      case 'in progress':
        return Icons.construction;
      case 'completed':
        return Icons.check_circle;
      case 'on hold':
        return Icons.pause_circle;
      default:
        return Icons.help;
    }
  }

  /// Get project details including tasks
  static Future<ProjectDetails> getProjectDetails(int projectId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/v1/projects/$projectId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return ProjectDetails.fromJson(data['data']);
      } else {
        throw Exception('Failed to load project details: API returned success false');
      }
    } else {
      throw Exception('Failed to load project details: ${response.statusCode}');
    }
  }

  /// Update task status
  static Future<void> updateTaskStatus(int projectId, int taskId, bool isCompleted) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/projects/$projectId/tasks/$taskId?is_completed=$isCompleted'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update task status: ${response.statusCode}');
    }
  }

  /// Add a new expense to a project
  static Future<void> addExpense({
    required int projectId,
    required String description,
    required double amount,
    required String category,
    required String date,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/projects/$projectId/expenses'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'description': description,
        'amount': amount,
        'category': category,
        'date': date,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add expense: ${response.statusCode}');
    }
  }

  /// Delete a project
  static Future<bool> deleteProject(int projectId, String userId) async {
    try {
      print('🗑️ Deleting project $projectId for user $userId');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/v1/projects/$projectId?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Project deleted successfully');
          return true;
        } else {
          print('❌ Delete failed: ${data['message']}');
          return false;
        }
      } else {
        print('❌ Failed to delete project: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting project: $e');
      return false;
    }
  }
}