import 'package:firebase_auth/firebase_auth.dart';

import 'auth_fixed.dart';

class NewAuthService {
  // Inscription - Ignore complètement l'erreur
  Future<User?> signUp(String email, String password, String name) async {
    print('🔄 Nouvelle méthode signUp appelée');

    final result = await AuthFixed.createUser(
      email: email,
      password: password,
      name: name,
    );

    if (result['success'] == true) {
      print('🎉 SUCCÈS: Utilisateur créé avec la nouvelle méthode');
      return result['user'] as User;
    } else {
      print('❌ Échec avec la nouvelle méthode: ${result['error']}');
      return null;
    }
  }

  // Connexion
  Future<User?> signIn(String email, String password) async {
    final result = await AuthFixed.signIn(
      email: email,
      password: password,
    );

    if (result['success'] == true) {
      return result['user'] as User?;
    }
    return null;
  }

  // Déconnexion
  Future<void> signOut() async {
    await AuthFixed.signOut();
  }

  // Stream simplifié
  Stream<User?> get userStream => FirebaseAuth.instance.authStateChanges();
}