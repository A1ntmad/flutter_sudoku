import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sudoku_screen.dart';

class SudokuListScreen extends StatefulWidget {
  const SudokuListScreen({Key? key}) : super(key: key);

  @override
  _SudokuListScreenState createState() => _SudokuListScreenState();
}

class _SudokuListScreenState extends State<SudokuListScreen> {
  Map<DateTime, double> _progressMap = {};

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
      ),
      body: ListView.builder(
        itemCount: 30,
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
                    onProgressUpdate: (newProgress) => updateProgress(date, newProgress),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
