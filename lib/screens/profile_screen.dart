import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers voor de tekstvelden
  TextEditingController nameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  bool isEditing = false; // Houdt bij of de gebruiker in bewerkingsmodus is

  @override
  void initState() {
    super.initState();
    _loadProfile(); // Laad de profielgegevens bij het openen van het scherm
  }

  // Laad profielgegevens uit Firestore
  Future<void> _loadProfile() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Haal de gebruikersgegevens op uit Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            nameController.text = userDoc['name'] ?? '';
            lastNameController.text = userDoc['lastName'] ?? '';
            emailController.text = userDoc['email'] ?? '';
            phoneController.text = userDoc['phoneNumber'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Fout bij ophalen van profielgegevens: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout bij het laden van profielgegevens.')),
      );
    }
  }

  // Profielgegevens bijwerken in Firestore
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
            'name': nameController.text,
            'lastName': lastNameController.text,
            'email': emailController.text,
            'phoneNumber': phoneController.text,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profiel succesvol bijgewerkt!')),
          );

          setState(() {
            isEditing = false; // Zet de bewerkingsmodus uit
          });
        }
      } catch (e) {
        print('Fout bij het bijwerken van profielgegevens: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij het bijwerken van profielgegevens.')),
        );
      }
    }
  }

  // Toggle edit mode (om gegevens in te voeren)
  void _toggleEdit() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void _showChangePasswordDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String newPassword = '';
    String confirmPassword = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Wijzig Wachtwoord'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nieuw wachtwoord
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nieuw Wachtwoord'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Voer een nieuw wachtwoord in';
                    } else if (value.length < 6) {
                      return 'Wachtwoord moet minstens 6 tekens lang zijn';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    newPassword = value;
                  },
                ),
                const SizedBox(height: 16),
                // Bevestig wachtwoord
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Bevestig Wachtwoord'),
                  obscureText: true,
                  validator: (value) {
                    if (value != newPassword) {
                      return 'Wachtwoorden komen niet overeen';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    confirmPassword = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleren'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    // Wachtwoord wijzigen via Firebase
                    await FirebaseAuth.instance.currentUser!
                        .updatePassword(newPassword);

                    // Toon succesmelding
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wachtwoord succesvol gewijzigd!'),
                      ),
                    );

                    Navigator.pop(context); // Sluit de dialoog
                  } catch (e) {
                    // Toon foutmelding
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fout bij wijzigen wachtwoord: $e'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Opslaan'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn Profiel'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Voornaam
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Voornaam'),
              enabled: isEditing,
              validator: (value) =>
              value!.isEmpty ? 'Voer je voornaam in' : null,
            ),
            // Achternaam
            TextFormField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Achternaam'),
              enabled: isEditing,
              validator: (value) =>
              value!.isEmpty ? 'Voer je achternaam in' : null,
            ),
            // E-mail
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              enabled: isEditing,
              validator: (value) => value!.isEmpty ||
                  !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)
                  ? 'Voer een geldig e-mailadres in'
                  : null,
            ),
            // Telefoonnummer
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Telefoonnummer'),
              enabled: isEditing,
              validator: (value) => value!.isEmpty
                  ? 'Voer je telefoonnummer in'
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isEditing)
                    ElevatedButton(
                      onPressed: _toggleEdit,
                      child: const Text('Bewerken'),
                    ),
                  if (isEditing)
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text('Profiel bijwerken'),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      _showChangePasswordDialog(context);
                    },
                    child: const Text('Wijzig Wachtwoord'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut(); // Uitloggen
                Navigator.pushReplacementNamed(context, '/login'); // Terug naar LoginScreen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Maak de knop rood
              ),
              child: const Text('Uitloggen'),
            ),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    // Controllers opruimen
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}