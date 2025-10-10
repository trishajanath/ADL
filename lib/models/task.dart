class ProjectTask {
  final int id;
  final String phase;
  final String taskName;
  bool isCompleted;
  final String createdAt;
  final String? completedAt;

  ProjectTask({
    required this.id,
    required this.phase,
    required this.taskName,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
  });

  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    return ProjectTask(
      id: json['id'] as int,
      phase: json['phase'] as String,
      taskName: json['task_name'] as String,
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
      createdAt: json['created_at'] as String,
      completedAt: json['completed_at'] as String?,
    );
  }
}
