import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/AppUser.dart';
import '../services/auth-service.dart';
import '../services/firebase-service.dart';


class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = false;
  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // Écouter les changements d'authentification
    _authService.userStream.listen((user) {
      _firebaseUser = user;
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _appUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      var doc = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        _appUser = AppUser.fromMap(doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      print('Erreur chargement user data: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      User? user = await _authService.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      User? user = await _authService.signUp(email, password, name);
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}