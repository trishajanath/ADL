// lib/projects_page.dart
import 'package:flutter/material.dart';
import 'models/project.dart' show Project;
import 'widgets/project_card.dart';
import 'projects_service.dart';
import 'project_details_page.dart';
import 'auth_service.dart';
import 'scan_storage.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  List<Project> _projects = [];
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user email as identifier, default to 'anonymous' if not logged in
      final userEmail = _authService.userIdentifier;
      print('👤 Current user email: $userEmail');
      print('👤 Is logged in: ${_authService.isLoggedIn}');
      
      // Fetch projects for the current user only (by email)
      final projects = await ProjectsService.getProjects(userEmail);
      
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
      
      print('📊 Loaded ${projects.length} projects for user $userEmail');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Failed to load projects: $e');
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Projects'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showNewProjectDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add New Project',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProjects,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _projects.isEmpty
                ? _buildEmptyState()
                : _buildProjectsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 50),
            
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E3A8A),
                    const Color(0xFF1E3A8A).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.construction,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Construction Projects',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Track your building projects and estimates',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            
            Text(
              'No Projects Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              'Start your first construction project\nto track progress and manage costs',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Show login hint if not logged in
            if (!_authService.isLoggedIn) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Sign in to sync your projects across devices',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Create Project Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showNewProjectDialog,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create Your First Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            _buildFeaturesPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsList() {
    return Column(
      children: [
        // Summary header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1E3A8A),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_projects.length} Active Projects',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Budget: ${_getTotalBudget()}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadProjects,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh Projects',
              ),
            ],
          ),
        ),
        
        // Projects list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _projects.length,
            itemBuilder: (context, index) {
              return ProjectCard(
                project: _projects[index],
                onProjectUpdated: _loadProjects,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showComingSoonDialog(title),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Features',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 16),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildFeatureCard(
              icon: Icons.calculate,
              title: 'Cost Estimation',
              description: 'Calculate project costs and material requirements',
              color: Colors.blue,
            ),
            _buildFeatureCard(
              icon: Icons.schedule,
              title: 'Timeline Tracking',
              description: 'Monitor project progress and deadlines',
              color: Colors.purple,
            ),
            _buildFeatureCard(
              icon: Icons.inventory,
              title: 'Material Lists',
              description: 'Manage materials and supplier information',
              color: Colors.teal,
            ),
            _buildFeatureCard(
              icon: Icons.people,
              title: 'Team Management',
              description: 'Coordinate with contractors and workers',
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  String _getTotalBudget() {
    double total = _projects.fold(0, (sum, project) => sum + project.budget);
    return ProjectsService.formatCurrency(total);
  }

  void _showNewProjectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DefaultTabController(
        length: 2,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_home_work,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Create Project'),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                labelColor: const Color(0xFF1E3A8A),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF1E3A8A),
                tabs: const [
                  Tab(text: 'New Project'),
                  Tab(text: 'From Scan'),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: TabBarView(
              children: [
                _buildNewProjectForm(),
                _buildFromScanForm(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewProjectForm() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final budgetController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'Residential';
    bool isCreating = false;

    return StatefulBuilder(
      builder: (context, setState) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                hintText: 'e.g., Family Home Construction',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Downtown District',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Project Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: ['Residential', 'Commercial', 'Industrial', 'Infrastructure']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: budgetController,
              decoration: const InputDecoration(
                labelText: 'Budget',
                hintText: 'e.g., 50000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief project description...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCreating ? null : () async {
                  if (nameController.text.trim().isEmpty) {
                    _showErrorMessage('Please enter a project name');
                    return;
                  }
                  if (locationController.text.trim().isEmpty) {
                    _showErrorMessage('Please enter a location');
                    return;
                  }
                  
                  double? budget;
                  if (budgetController.text.trim().isNotEmpty) {
                    budget = double.tryParse(budgetController.text.trim());
                    if (budget == null || budget <= 0) {
                      _showErrorMessage('Please enter a valid budget amount');
                      return;
                    }
                  } else {
                    budget = 0.0;
                  }

                  setState(() => isCreating = true);

                  try {
                    final userEmail = _authService.userIdentifier;
                    
                    await ProjectsService.createProject(
                      name: nameController.text.trim(),
                      location: locationController.text.trim(),
                      projectType: selectedType,
                      budget: budget,
                      description: descriptionController.text.trim(),
                      userId: userEmail,
                    );

                    Navigator.of(context).pop();
                    _showSuccessMessage('Project created successfully!');
                    _loadProjects();
                  } catch (e) {
                    setState(() => isCreating = false);
                    _showErrorMessage('Failed to create project: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create Project'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFromScanForm() {
    return FutureBuilder<List<ScanResult>>(
      future: ScanStorage.loadScans(_authService.userIdentifier),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading scans: ${snapshot.error}'),
          );
        }

        final scans = snapshot.data ?? [];

        if (scans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.scanner, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No saved scans yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete a questionnaire to see your scans here!',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: scans.length,
          itemBuilder: (context, index) {
            final scan = scans[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scan.category == 'residential'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    scan.category == 'residential'
                        ? Icons.home
                        : Icons.business,
                    color: scan.category == 'residential'
                        ? Colors.green
                        : Colors.blue,
                  ),
                ),
                title: Text(
                  scan.projectName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Grade: ${scan.concreteGrade}'),
                    Text('Area: ${scan.builtUpArea} sq.ft'),
                    Text('Cost: ${scan.estimatedCost}'),
                  ],
                ),
                trailing: ElevatedButton.icon(
                  onPressed: () => _createProjectFromScan(scan),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createProjectFromScan(ScanResult scan) async {
    try {
      final userEmail = _authService.userIdentifier;
      
      // Extract budget from estimated cost
      double budget = 0.0;
      try {
        final costStr = scan.estimatedCost.replaceAll(RegExp(r'[^\d.]'), '');
        budget = double.tryParse(costStr) ?? 0.0;
      } catch (e) {
        print('Could not parse budget from cost: $e');
      }

      await ProjectsService.createProject(
        name: scan.projectName,
        location: 'Location from ${scan.category} scan',
        projectType: scan.category == 'residential' ? 'Residential' : 'Commercial',
        budget: budget,
        description: 'Created from scan - ${scan.buildingType}, ${scan.floors} floors, ${scan.builtUpArea} sq.ft, ${scan.concreteGrade}',
        userId: userEmail,
      );

      Navigator.of(context).pop();
      _showSuccessMessage('Project created from scan successfully!');
      _loadProjects();
    } catch (e) {
      _showErrorMessage('Failed to create project from scan: $e');
    }
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text(
          '$feature functionality is coming soon!\n\nThis feature will allow you to manage your construction projects, track progress, and organize all project-related information in one place.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}