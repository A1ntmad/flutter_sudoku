import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sudoku_service.dart';
import 'sudoku_screen.dart';

class SudokuListScreen extends StatefulWidget {
  const SudokuListScreen({Key? key}) : super(key: key);

  @override
  _SudokuListScreenState createState() => _SudokuListScreenState();
}

class _SudokuListScreenState extends State<SudokuListScreen> {
  final SudokuService _sudokuService = SudokuService(); // SudokuService instantiëren
  Map<DateTime, double> _progressMap = {}; // Voortgang per Sudoku

  // Update voortgang van een specifieke Sudoku
  void updateProgress(DateTime date, double progress) {
    setState(() {
      _progressMap[date] = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kies een Sudoku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save), // Save-icoon
            onPressed: () async {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geen gebruiker ingelogd!')),
                );
                return;
              }

              // Dummy sudoku voortgang opslaan als test
              final dummyPuzzle = List.generate(9, (_) => List.generate(9, (_) => null));
              final progressMap = _convert2DArrayToMap(dummyPuzzle);

              try {
                await _sudokuService.saveSudokuProgress(
                  userId: currentUser.uid, // Correct genest argument
                  puzzleId: 'test_puzzle', // Correct genest argument
                  progress: _convert2DArrayToMap(dummyPuzzle), // Voortgang in Map-vorm
                  hintsUsed: 0, // Geen hints gebruikt
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test opslaan uitgevoerd!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opslaan mislukt: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 30, // Voorbeeld: 30 dagen Sudoku
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().subtract(Duration(days: index));
          double progress = _progressMap[date] ?? 0.0;

          return ListTile(
            title: Text('Sudoku van ${date.toLocal().toString().split(' ')[0]}'),
            subtitle: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SudokuScreen(
                    date: date,
                    onProgressUpdate: (progress) => updateProgress(date, progress),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Hulpfunctie: 2D-array naar Map converteren
  Map<String, int?> _convert2DArrayToMap(List<List<int?>> array) {
    final Map<String, int?> map = {};
    for (int row = 0; row < array.length; row++) {
      for (int col = 0; col < array[row].length; col++) {
        map['$row$col'] = array[row][col];
      }
    }
    return map;
  }
}

