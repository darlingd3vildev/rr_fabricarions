import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/screens/onboarding/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Make sure to set up your firebase_options.dart from FlutterFire CLI
  await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
      );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RR Fabrications',
      theme: ThemeData(
        // Use fromSeed to generate a cohesive color scheme from a single color.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          // Optional: Define a light blue background for a softer look.
          background: Colors.blue[50],
        ),
        useMaterial3: true, // Recommended for modern Flutter apps.
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}