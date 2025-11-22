import 'package:firebase_auth/firebase_auth.dart';

import 'firebase-service.dart';

class AuthFixed {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Méthode d'inscription qui contourne TOTALEMENT le bug
  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('🎯 Début de création utilisateur (méthode fixe)');

      // Étape 1: Créer l'utilisateur avec une approche différente
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Utilisateur Auth créé: ${userCredential.user?.uid}');

      if (userCredential.user != null) {
        // Étape 2: Ignorer complètement l'erreur et continuer
        // L'utilisateur EST créé malgré l'erreur
        final userId = userCredential.user!.uid;

        // Étape 3: Créer le document utilisateur
        final userData = {
          'id': userId,
          'email': email,
          'name': name,
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

        print('✅ Document Firestore créé avec succès');

        // Retourner le succès même si une erreur s'est produite
        return {
          'success': true,
          'user': userCredential.user,
          'userData': userData,
          'message': 'Compte créé avec succès'
        };
      }

      return {'success': false, 'error': 'User creation failed'};
    } catch (e) {
      print('⚠️ Erreur attrapée mais ignorée: $e');

      // VÉRIFIER si l'utilisateur a quand même été créé
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('🎉 L\'utilisateur a été créé malgré l\'erreur! UID: ${currentUser.uid}');

        // Créer le document utilisateur
        final userData = {
          'id': currentUser.uid,
          'email': email,
          'name': name,
          'phone': '',
          'address': '',
          'rating': 0.0,
          'totalReviews': 0,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        };

        await FirebaseService.firestore
            .collection('users')
            .doc(currentUser.uid)
            .set(userData);

        return {
          'success': true,
          'user': currentUser,
          'userData': userData,
          'message': 'Compte créé avec succès (malgré une erreur technique)'
        };
      }

      return {'success': false, 'error': 'Échec complet de la création'};
    }
  }

  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return {
        'success': true,
        'user': userCredential.user,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;
}