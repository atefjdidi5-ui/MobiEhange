import 'package:firebase_auth/firebase_auth.dart';
import '../models/AppUser.dart';
import 'firebase-service.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Connexion
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Erreur connexion: $e');
      return null;
    }
  }

  // Inscription
  Future<User?> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Créer le document user dans Firestore
      if (result.user != null) {
        AppUser newUser = AppUser(
          id: result.user!.uid,
          email: email,
          name: name,
          createdAt: DateTime.now(),
        );

        await FirebaseService.firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(newUser.toMap());
      }

      return result.user;
    } catch (e) {
      print('Erreur inscription: $e');
      return null;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Écouter les changements d'authentification
  Stream<User?> get userStream => _auth.authStateChanges();
}