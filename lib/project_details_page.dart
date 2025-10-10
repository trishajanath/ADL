import 'package:flutter/material.dart';
import 'package:my_app/models/project.dart';
import 'package:my_app/projects_service.dart';
import 'package:my_app/widgets/task_list.dart';

class ProjectDetailsPage extends StatefulWidget {
  final int projectId;

  const ProjectDetailsPage({super.key, required this.projectId});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  Future<ProjectDetails>? _projectDetailsFuture;

  @override
  void initState() {
    super.initState();
    _loadProjectDetails();
  }

  void _loadProjectDetails() {
    setState(() {
      _projectDetailsFuture = ProjectsService.getProjectDetails(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjectDetails,
          ),
        ],
      ),
      body: FutureBuilder<ProjectDetails>(
        future: _projectDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProjectDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final projectDetails = snapshot.data!;
            final project = projectDetails;
            final tasks = projectDetails.tasks;

            return RefreshIndicator(
              onRefresh: () async {
                _loadProjectDetails();
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildProjectHeader(project),
                  const SizedBox(height: 24),
                  TaskList(tasks: tasks, projectId: project.id, onTaskUpdated: _loadProjectDetails),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No project details found.'));
          }
        },
      ),
    );
  }

  Widget _buildProjectHeader(Project project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  project.location,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip('Budget', ProjectsService.formatCurrency(project.budget), Icons.account_balance_wallet),
              _buildInfoChip('Type', project.projectType, Icons.category),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoChip('Status', project.status, Icons.info_outline, color: ProjectsService.getStatusColor(project.status)),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              project.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon, {Color? color}) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color ?? Colors.blueGrey),
      label: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
      backgroundColor: (color ?? Colors.blueGrey).withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}