import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inloggen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'E-mailadres'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Voer een e-mailadres in';
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
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    try {
                      // Firebase: Inloggen met e-mailadres en wachtwoord
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      // Navigeren naar HomeScreen bij succesvol inloggen
                      Navigator.pushReplacementNamed(context, '/home');
                    } on FirebaseAuthException catch (e) {
                      String errorMessage;

                      // Specifieke foutcodes afhandelen
                      switch (e.code) {
                        case 'user-not-found':
                          errorMessage = 'Er bestaat geen account met dit e-mailadres.';
                          break;
                        case 'wrong-password':
                          errorMessage = 'Het wachtwoord is onjuist. Probeer het opnieuw.';
                          break;
                        case 'invalid-email':
                          errorMessage = 'Het ingevoerde e-mailadres is ongeldig.';
                          break;
                        case 'user-disabled':
                          errorMessage = 'Dit account is uitgeschakeld. Neem contact op met ondersteuning.';
                          break;
                        default:
                          errorMessage = 'Er is een onverwachte fout opgetreden. Probeer het opnieuw.';
                      }

                      // Toon een dialoogvenster met de foutmelding
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Inloggen mislukt'),
                          content: Text(errorMessage),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      // Voor andere, niet-specifieke fouten
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Fout'),
                          content: const Text(
                            'Er is een probleem opgetreden. Controleer je verbinding en probeer het opnieuw.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                child: const Text('Inloggen'),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register'); // Navigeren naar RegisterScreen
                },
                child: Text('Nog geen account? Registreer hier'),
              ),
              TextButton(
                onPressed: () {
                  _resetPasswordDialog(context); // Open reset password dialoog
                },
                child: Text('Wachtwoord vergeten?'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetPasswordDialog(BuildContext context) {
    String resetEmail = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reset wachtwoord'),
          content: TextFormField(
            decoration: InputDecoration(labelText: 'E-mailadres'),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              resetEmail = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: resetEmail);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('E-mail voor wachtwoord reset verzonden naar $resetEmail')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Fout'),
                      content: Text('Kan e-mail niet verzenden: ${e.toString()}'),
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
              },
              child: Text('Verzenden'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Annuleren'),
            ),
          ],
        );
      },
    );
  }
}
