import 'package:flutter/material.dart';
import 'profile_screen.dart'; // Importeer het profielscherm
import 'sudoku_list_screen.dart'; // Importeer het sudoku lijst scherm

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzel App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle), // Profielicoon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SudokuListScreen()),
            );
          },
          child: const Text('Speel Sudoku'),
        ),
      ),
    );
  }
}
