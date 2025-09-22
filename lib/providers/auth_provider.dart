import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  UserProfile? _userProfile;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    FirebaseService.authStateChanges.listen((user) async {
      _currentUser = user;
      if (user != null) {
        _userProfile = await UserService.getCurrentUser();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password, String displayName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await FirebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userProfile = User(
        id: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        photoUrl: '',
        createdAt: DateTime.now(),
        dailySearchCount: 0,
        isProUser: false,
      );

      await UserService.createUserProfile(userProfile);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await FirebaseService.auth.signOut();
  }

  Future<void> incrementSearchCount() async {
    if (_userProfile != null) {
      await UserService.incrementSearchCount(_userProfile!.id);
    }
  }

  bool canPerformSearch() {
    // Free users: 5 searches per day
    // Pro users: unlimited
    if (_userProfile?.isProUser == true) return true;
    return (_userProfile?.dailySearchCount ?? 0) < 5;
  }
}