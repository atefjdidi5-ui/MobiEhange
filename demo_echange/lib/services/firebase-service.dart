import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseService {
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // WEB CONFIGURATION - You MUST get these from Firebase Console
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyA...YOUR_API_KEY_HERE", // ← REPLACE THIS
            appId: "1:1234567890:web:abcdef...", // ← REPLACE THIS
            messagingSenderId: "1234567890", // ← REPLACE THIS
            projectId: "your-project-id", // ← REPLACE THIS
            authDomain: "your-project-id.firebaseapp.com", // ← REPLACE THIS
            storageBucket: "your-project-id.appspot.com", // ← REPLACE THIS
          ),
        );
      } else {
        // Mobile/Desktop - uses default configuration
        await Firebase.initializeApp();
      }
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
}