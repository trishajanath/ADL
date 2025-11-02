// lib/auth_service.dart
import 'package:flutter/foundation.dart';
import './data/models.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _user;
  UserModel? get user => _user;

  bool get isLoggedIn => _user != null;
  
  // Get the user's email as the unique identifier
  String get userIdentifier => _user?.email ?? 'anonymous';

  // Mock sign-in for email/password
  void mockSignIn(String name, String email) {
    _user = UserModel(
      uid: email, // Use email as UID for consistency
      name: name,
      email: email,
      phone: '9876543210',
      photoUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
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
  void updateProfilePicture(String photoUrl) {
    if (_user != null) {
      _user!.photoUrl = photoUrl;
      notifyListeners();
    }
  }
}