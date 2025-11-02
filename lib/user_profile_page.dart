// lib/user_profile_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
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
      // Get current user email as identifier
      final userEmail = AuthService().userIdentifier;
      final scans = await ScanStorage.loadScans(userEmail);
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

  ImageProvider _getProfileImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return NetworkImage('https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80');
    }
    
    // Check if it's a base64 encoded image
    if (photoUrl.startsWith('data:image')) {
      // Extract base64 data and decode
      final base64Data = photoUrl.split(',')[1];
      final bytes = base64Decode(base64Data);
      return MemoryImage(bytes);
    }
    
    // Check if it's a network URL
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return NetworkImage(photoUrl);
    }
    
    // Fallback to file path (shouldn't happen with new system)
    return FileImage(File(photoUrl));
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
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _getProfileImage(user.photoUrl),
                      backgroundColor: Colors.white,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showProfilePictureOptions,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Color(0xFF1E3A8A), width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                    ),
                  ],
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
      // Get current user email as identifier
      final userEmail = AuthService().userIdentifier;
      await ScanStorage.deleteScan(scan.id, userEmail);
      _loadPreviousScans(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan deleted successfully')),
      );
    }
  }

  void _showProfilePictureOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.photo_camera, color: Color(0xFF1E3A8A)),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF1E3A8A)),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (AuthService().user?.photoUrl != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfilePicture();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        // Convert image to base64 for storage
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        
        // Update the profile picture in the auth service (saves to backend)
        bool success = await AuthService().updateProfilePicture(base64Image);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Profile picture updated successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          setState(() {}); // Refresh UI
        } else {
          throw Exception('Failed to save profile picture');
        }
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to update profile picture'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removeProfilePicture() async {
    bool success = await AuthService().updateProfilePicture('https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80');
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Profile picture removed'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      setState(() {}); // Refresh UI
    }
  }
}