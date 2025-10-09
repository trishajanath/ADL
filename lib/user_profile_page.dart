// lib/user_profile_page.dart
import 'package:flutter/material.dart';
import './auth_service.dart';
import './edit_profile_page.dart';
import './change_password_page.dart';
import 'scan_storage.dart';
import 'prediction_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  List<ScanResult> _previousScans = [];
  bool _isLoadingScans = true;

  @override
  void initState() {
    super.initState();
    _loadPreviousScans();
  }

  Future<void> _loadPreviousScans() async {
    try {
      final scans = await ScanStorage.loadScans();
      setState(() {
        _previousScans = scans;
        _isLoadingScans = false;
      });
    } catch (e) {
      print('❌ Error loading scans: $e');
      setState(() {
        _isLoadingScans = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.user;

    if (user == null) {
      // This should not happen if the logic is correct, but as a fallback:
      return const Center(child: Text('User not logged in.'));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(user.photoUrl ?? 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80'),
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Previous Scans Section
          _buildPreviousScansSection(),
          
          const SizedBox(height: 20),
          _buildProfileOption(
            context,
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const EditProfilePage(),
              ));
            },
          ),
          _buildProfileOption(
            context,
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
               Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ChangePasswordPage(),
              ));
            },
          ),
          _buildProfileOption(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {},
          ),
          _buildProfileOption(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {},
          ),
          const Divider(indent: 16, endIndent: 16),
           _buildProfileOption(
            context,
            icon: Icons.logout,
            title: 'Sign Out',
            color: Colors.red,
            onTap: () {
              authService.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF1E3A8A)),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildPreviousScansSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.history, color: Color(0xFF1E3A8A), size: 24),
                SizedBox(width: 12),
                Text(
                  'My Previous Scans',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isLoadingScans)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_previousScans.isEmpty)
            _buildEmptyScansWidget()
          else
            _buildScansList(),
        ],
      ),
    );
  }

  Widget _buildEmptyScansWidget() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.scanner,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No scans yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
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

  Widget _buildScansList() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        children: _previousScans.take(5).map((scan) => _buildScanCard(scan)).toList()
          ..add(_buildViewAllButton()),
      ),
    );
  }

  Widget _buildViewAllButton() {
    if (_previousScans.length <= 5) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextButton(
        onPressed: () => _showAllScans(),
        child: Text(
          'View All ${_previousScans.length} Scans',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildScanCard(ScanResult scan) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: scan.category == 'residential' 
              ? Colors.green.withOpacity(0.1) 
              : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            scan.category.toUpperCase().substring(0, 3),
            style: TextStyle(
              color: scan.category == 'residential' ? Colors.green : Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          scan.projectName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              '${scan.concreteGrade} • ${scan.estimatedCost}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              _formatDate(scan.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              _viewScanDetails(scan);
            } else if (value == 'edit') {
              _editScan(scan);
            } else if (value == 'delete') {
              _deleteScan(scan);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'view', child: Text('View Details')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          child: Icon(Icons.more_vert, color: Colors.grey[400]),
        ),
        onTap: () => _viewScanDetails(scan),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAllScans() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'All My Scans (${_previousScans.length})',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _previousScans.length,
                itemBuilder: (context, index) => _buildScanCard(_previousScans[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewScanDetails(ScanResult scan) {
    showDialog(
      context: context,
      builder: (context) => _buildScanDetailsDialog(scan),
    );
  }

  Widget _buildScanDetailsDialog(ScanResult scan) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.analytics, color: Color(0xFF1E3A8A)),
          SizedBox(width: 8),
          Expanded(child: Text(scan.projectName)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultItem('Concrete Grade', scan.concreteGrade, Icons.foundation),
            _buildResultItem('Confidence', scan.confidence, Icons.verified),
            _buildResultItem('Estimated Cost', scan.estimatedCost, Icons.attach_money),
            _buildResultItem('Area', '${scan.builtUpArea} sq.ft', Icons.square_foot),
            _buildResultItem('Building Type', scan.buildingType, Icons.business),
            _buildResultItem('Floors', scan.floors, Icons.layers),
            
            SizedBox(height: 16),
            Text('Materials Required:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Divider(),
            if (scan.predictionResult['materials'] != null) ...[
              _buildMaterialItem('Cement', '${scan.predictionResult['materials']['Cement_kg']} kg'),
              _buildMaterialItem('Water', '${scan.predictionResult['materials']['Water_kg']} kg'),
              _buildMaterialItem('Sand', '${scan.predictionResult['materials']['Sand_kg']} kg'),
              _buildMaterialItem('Coarse Aggregate', '${scan.predictionResult['materials']['CA20_kg']} kg'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _editScan(scan);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1E3A8A)),
          child: Text('Edit', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Color(0xFF1E3A8A)),
          SizedBox(width: 8),
          Expanded(
            child: Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialItem(String material, String quantity) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(material),
          Text(quantity, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _editScan(ScanResult scan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PredictionPage(
          category: scan.category,
          existingScan: scan,
        ),
      ),
    ).then((_) => _loadPreviousScans()); // Refresh scans when returning
  }

  Future<void> _deleteScan(ScanResult scan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Scan'),
        content: Text('Are you sure you want to delete "${scan.projectName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ScanStorage.deleteScan(scan.id);
      _loadPreviousScans(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan deleted successfully')),
      );
    }
  }
}