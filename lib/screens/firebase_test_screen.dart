import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseTestScreen extends StatelessWidget {
  const FirebaseTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              // Probeer een testgebruiker aan te maken
              UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: "testuser@example.com",
                password: "testpassword123",
              );

              // Toon succesmelding
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Succes"),
                  content: Text("Gebruiker aangemaakt: ${userCredential.user?.email}"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            } catch (e) {
              // Toon foutmelding
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Error"),
                  content: Text(e.toString()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            }
          },
          child: const Text("Test Firebase Verbinding"),
        ),
      ),
    );
  }
}
