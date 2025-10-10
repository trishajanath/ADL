import 'task.dart';
import 'expense.dart';

class Project {
  final int id;
  final String name;
  final String location;
  final String projectType;
  final double budget;
  final String createdAt;
  final String status;
  final String description;

  Project({
    required this.id,
    required this.name,
    required this.location,
    required this.projectType,
    required this.budget,
    required this.createdAt,
    required this.status,
    this.description = '',  // Default empty string for description
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      name: json['name'] as String,
      location: json['location'] as String,
      projectType: json['project_type'] as String,
      budget: (json['budget'] as num).toDouble(),
      createdAt: json['created_at'] as String,
      status: json['status'] as String? ?? 'Planning',  // Default status if null
      description: json['description'] as String? ?? '',  // Default empty string if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'project_type': projectType,
      'budget': budget,
      'created_at': createdAt,
      'status': status,
      'description': description,
    };
  }
}

class ProjectDetails extends Project {
  final List<ProjectTask> tasks;
  final List<Expense> expenses;

  ProjectDetails({
    required Project project,
    required this.tasks,
    required this.expenses,
  }) : super(
          id: project.id,
          name: project.name,
          location: project.location,
          projectType: project.projectType,
          budget: project.budget,
          createdAt: project.createdAt,
          status: project.status,
          description: project.description,
        );

  factory ProjectDetails.fromJson(Map<String, dynamic> json) {
    final projectData = json['project'] as Map<String, dynamic>;
    final tasksData = json['tasks'] as List;
    final expensesData = json['expenses'] as List;
    final project = Project.fromJson(projectData);
    final tasks = tasksData.map((taskJson) => ProjectTask.fromJson(taskJson)).toList();
    final expenses = expensesData.map((expenseJson) => Expense.fromJson(expenseJson)).toList();

    return ProjectDetails(
      project: project,
      tasks: tasks,
      expenses: expenses,
    );
  }
}