import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/User.dart';
import '../services/auth-service.dart';
import '../services/firebase-service.dart';

class AuthProvider with ChangeNotifier {
  final NewAuthService _authService = NewAuthService();
  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _registrationInProgress = false;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    print('🔧 Initialisation du listener auth...');

    _authService.userStream.listen((user) {
      print('📡 État auth changé: ${user?.uid ?? "null"}');
      _firebaseUser = user;

      if (user != null) {
        print('👤 Utilisateur connecté, chargement des données...');
        _loadUserData(user.uid);
      } else {
        _appUser = null;
        _errorMessage = null;
        notifyListeners();
      }
    }, onError: (error) {
      print('❌ Erreur dans le stream: $error');
      // IGNORER l'erreur du stream - c'est le bug qu'on contourne
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      print('📥 Chargement des données pour: $userId');

      final doc = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        print('✅ Données utilisateur trouvées');
        _appUser = AppUser.fromMap(doc.data()!);
        _errorMessage = null;
        _registrationInProgress = false;
      } else {
        print('⚠️ Document non trouvé, création...');
        await _createUserDocument(userId);
      }

      notifyListeners();
    } catch (e) {
      print('❌ Erreur chargement données: $e');
      _errorMessage = 'Erreur de chargement';
      notifyListeners();
    }
  }

  Future<void> _createUserDocument(String userId) async {
    try {
      final user = _firebaseUser;
      if (user != null) {
        final userData = {
          'id': userId,
          'email': user.email ?? 'email@inconnu.com',
          'name': user.displayName ?? 'Utilisateur',
          'phone': '',
          'address': '',
          'rating': 0.0,
          'totalReviews': 0,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        };

        await FirebaseService.firestore
            .collection('users')
            .doc(userId)
            .set(userData);

        _appUser = AppUser.fromMap(userData);
        print('✅ Document utilisateur créé');
      }
    } catch (e) {
      print('❌ Erreur création document: $e');
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    _registrationInProgress = true;
    notifyListeners();

    print('🚀 DÉBUT INSCRIPTION: $email');

    try {
      final user = await _authService.signUp(email, password, name);
      _isLoading = false;

      if (user != null) {
        print('🎉 INSCRIPTION RÉUSSIE dans le provider');
        // Attendre que les données se chargent
        await Future.delayed(Duration(seconds: 3));
        return true;
      } else {
        print('❌ INSCRIPTION ÉCHOUÉE dans le provider');
        _errorMessage = 'Échec de la création du compte';
        _registrationInProgress = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _registrationInProgress = false;
      print('💥 ERREUR CRITIQUE dans signUp: $e');
      _errorMessage = 'Erreur technique';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signIn(email, password);
      _isLoading = false;

      return user != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur de connexion';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur déconnexion';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}