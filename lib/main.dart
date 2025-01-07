import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart'; // Login-scherm importeren
import 'screens/home_screen.dart'; // Home-scherm importeren
import 'screens/register_screen.dart'; // Register-scherm importeren
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const PuzzelApp());
  } catch (e) {
    // Log of behandel de fout bij het initialiseren van Firebase
    debugPrint('Fout bij Firebase-initialisatie: $e');
  }
}

class PuzzelApp extends StatelessWidget {
  const PuzzelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Puzzel App',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Primaire kleur
        scaffoldBackgroundColor: Colors.grey[100], // Achtergrondkleur
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900], // Voor grote kopteksten
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.grey[800], // Voor standaard tekst
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.grey[700], // Voor subtekst
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Knopkleur
            foregroundColor: Colors.white, // Tekstkleur
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Ronde hoeken
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white, // Achtergrondkleur van invoervelden
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Ronde hoeken
            borderSide: BorderSide(color: Colors.blue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          labelStyle: TextStyle(
            color: Colors.grey[800], // Labelkleur
            fontSize: 14,
          ),
        ),
      ),
      home: LoginScreen(), // Login-scherm is de startpagina
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
      },
    );
  }
}
