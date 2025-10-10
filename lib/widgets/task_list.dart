import 'package:flutter/material.dart';
import 'package:my_app/models/task.dart';
import 'package:my_app/projects_service.dart';

class TaskList extends StatefulWidget {
  final int projectId;
  final List<ProjectTask> tasks;
  final VoidCallback onTaskUpdated;

  const TaskList({
    super.key,
    required this.projectId,
    required this.tasks,
    required this.onTaskUpdated,
  });

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  late Map<String, List<ProjectTask>> _groupedTasks;

  @override
  void initState() {
    super.initState();
    _groupTasks();
  }

  @override
  void didUpdateWidget(TaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks) {
      _groupTasks();
    }
  }

  void _groupTasks() {
    _groupedTasks = {};
    for (var task in widget.tasks) {
      final phase = task.phase;
      if (!_groupedTasks.containsKey(phase)) {
        _groupedTasks[phase] = [];
      }
      _groupedTasks[phase]!.add(task);
    }
  }

  Future<void> _toggleTaskStatus(ProjectTask task, bool newStatus) async {
    try {
      // optimistic update
      setState(() {
        task.isCompleted = newStatus;
        _groupTasks();
      });
      await ProjectsService.updateTaskStatus(widget.projectId, task.id, newStatus);
      widget.onTaskUpdated();
    } catch (e) {
      // revert on failure
      setState(() {
        task.isCompleted = !newStatus;
        _groupTasks();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No tasks found for this project. The checklist might still be generating.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Checklist',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._groupedTasks.entries.map((entry) {
          final phase = entry.key;
          final tasks = entry.value;
          return _buildPhaseSection(phase, tasks);
        }).toList(),
      ],
    );
  }

  Widget _buildPhaseSection(String phase, List<ProjectTask> tasks) {
    int completedCount = tasks.where((t) => t.isCompleted).length;
    double progress = tasks.isNotEmpty ? completedCount / tasks.length : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              phase,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        children: tasks.map((task) => _buildTaskTile(task)).toList(),
      ),
    );
  }

  Widget _buildTaskTile(ProjectTask task) {
    return ListTile(
      title: Text(
        task.taskName,
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted ? Colors.grey : null,
        ),
      ),
      leading: Checkbox(
        value: task.isCompleted,
        onChanged: (bool? value) {
          if (value != null) {
            _toggleTaskStatus(task, value);
          }
        },
      ),
    );
  }
}