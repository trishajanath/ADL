// lib/auth_service.dart
import 'package:flutter/foundation.dart';
import './data/models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _baseUrl = 'http://127.0.0.1:8000';

  UserModel? _user;
  UserModel? get user => _user;

  bool get isLoggedIn => _user != null;
  
  // Get the user's email as the unique identifier
  String get userIdentifier => _user?.email ?? 'anonymous';

  // Mock sign-in for email/password
  void mockSignIn(String name, String email, {String? profilePicture}) {
    _user = UserModel(
      uid: email, // Use email as UID for consistency
      name: name,
      email: email,
      phone: '9876543210',
      photoUrl: profilePicture ?? 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
    );
    notifyListeners();
  }
  
  // Sign-in with Google
  void signInWithGoogle(UserModel user) {
      // Ensure UID is set to email for consistency
      _user = UserModel(
        uid: user.email,
        name: user.name,
        email: user.email,
        phone: user.phone,
        photoUrl: user.photoUrl,
      );
      notifyListeners();
  }

  // Sign out
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    _user = null;
    notifyListeners();
  }

  // Update user details
  void updateUser(String newName, String newPhone) {
    if (_user != null) {
      _user!.name = newName;
      _user!.phone = newPhone;
      notifyListeners();
    }
  }

  // Update profile picture
  Future<bool> updateProfilePicture(String photoUrl) async {
    if (_user != null) {
      try {
        print('📸 Updating profile picture for ${_user!.email}');
        
        final response = await http.put(
          Uri.parse('$_baseUrl/api/v1/users/profile-picture'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': _user!.email,
            'profile_picture': photoUrl,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            _user!.photoUrl = photoUrl;
            notifyListeners();
            print('✅ Profile picture updated successfully');
            return true;
          }
        }
        
        print('❌ Failed to update profile picture: ${response.statusCode}');
        return false;
      } catch (e) {
        print('❌ Error updating profile picture: $e');
        return false;
      }
    }
    return false;
  }
}