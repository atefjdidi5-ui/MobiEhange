import 'package:demo_echange/providers/auth-provider.dart';
import 'package:demo_echange/services/firebase-service.dart';
import 'package:demo_echange/views/login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // AJOUTEZ CET IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // DOIT ÊTRE AVANT Firebase
  await FirebaseService.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'DEVMOB Echange',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.isLoading) {
              return Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return LoginPage(); // Nous allons créer cet écran
          },
        ),
      ),
    );
  }
}