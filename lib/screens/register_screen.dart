import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  // Variabelen voor het opslaan van gebruikersinvoer
  String name = '';
  String lastName = '';
  String email = '';
  String phoneNumber = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registreren'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Naam
                TextFormField(
                  decoration: InputDecoration(labelText: 'Naam'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Voer je naam in';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    name = value!;
                  },
                ),
                SizedBox(height: 16),

                // Achternaam
                TextFormField(
                  decoration: InputDecoration(labelText: 'Achternaam'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Voer je achternaam in';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    lastName = value!;
                  },
                ),
                SizedBox(height: 16),

                // E-mailadres
                TextFormField(
                  decoration: InputDecoration(labelText: 'E-mailadres'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Voer een geldig e-mailadres in';
                    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Voer een geldig e-mailadres in';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    email = value!;
                  },
                ),
                SizedBox(height: 16),

                // Telefoonnummer (optioneel)
                TextFormField(
                  decoration: InputDecoration(labelText: 'Telefoonnummer (optioneel)'),
                  keyboardType: TextInputType.phone,
                  onSaved: (value) {
                    phoneNumber = value!;
                  },
                ),
                SizedBox(height: 16),

                // Wachtwoord
                TextFormField(
                  decoration: InputDecoration(labelText: 'Wachtwoord'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Voer een wachtwoord in';
                    } else if (value.length < 6) {
                      return 'Wachtwoord moet minstens 6 tekens zijn';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    password = value!;
                  },
                ),
                SizedBox(height: 32),

                // Registreer-knop
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      try {
                        // Firebase-authenticatie: Gebruiker registreren
                        UserCredential userCredential =
                        await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );

                        // Firestore: Extra gegevens opslaan
                        await FirebaseFirestore.instance
                            .collection('users') // Collectienaam in Firestore
                            .doc(userCredential.user!.uid) // Document ID is de UID
                            .set({
                          'name': name,
                          'lastName': lastName,
                          'email': email,
                          'phoneNumber': phoneNumber,
                        });

                        // Navigeren naar het profielscherm of home
                        Navigator.pushReplacementNamed(context, '/home');
                      } catch (e) {
                        // Toon foutmelding bij registratieproblemen
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Registreren mislukt'),
                            content: Text(
                                'Er is een fout opgetreden: ${e.toString()}'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  child: Text('Registreren'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
