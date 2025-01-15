import 'package:flutter/material.dart';
import 'profile_screen.dart'; // Importeer het profielscherm
import 'sudoku_list_screen.dart'; // Importeer het sudoku lijst scherm
import 'wordsearch_list_screen.dart'; // Importeer het woordzoeker lijst scherm
import 'binair_list_screen.dart'; // Importeer het binaire lijst scherm

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SudokuListScreen()),
                );
              },
              child: const Text('Speel Sudoku'),
            ),
            const SizedBox(height: 20), // Voeg ruimte toe tussen de knoppen
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WordsearchListScreen()),
                );
              },
              child: const Text('Speel Woordzoeker'),
            ),
            const SizedBox(height: 20), // Voeg ruimte toe tussen de knoppen
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BinairListScreen()),
                );
              },
              child: const Text('Speel Binair'),
            ),
          ],
        ),
      ),
    );
  }
}
