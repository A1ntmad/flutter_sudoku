import 'package:flutter/material.dart';
import '../models/sudoku_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SudokuScreen extends StatefulWidget {
  final DateTime date;
  final Function(double) onProgressUpdate;

  const SudokuScreen({
    Key? key,
    required this.date,
    required this.onProgressUpdate,
  }) : super(key: key);

  @override
  _SudokuScreenState createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  late List<List<int?>> puzzle; // Sudoku raster
  late Map<String, int?> solution; // Oplossing van de puzzel
  late Map<String, int?> progress; // Voortgang van de puzzel
  int _currentScore = 100; // Startscore
  bool _hasChanges = false; // Detecteert wijzigingen
  bool _isLoading = true; // Laadindicator
  final SudokuService _sudokuService = SudokuService(); // Sudoku-service instantie
  late String userId; // ID van de huidige gebruiker

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("Geen gebruiker ingelogd");
      Navigator.pop(context);
      return;
    }
    userId = currentUser.uid;
    await _initializePuzzle();
  }

  Future<void> _initializePuzzle() async {
    final savedPuzzleData = await _sudokuService.getSudoku(userId, _generatePuzzleId());

    if (savedPuzzleData != null) {
      // Laad opgeslagen puzzeldata
      puzzle = _convertMapTo2DArray(Map<String, int?>.from(savedPuzzleData['grid']), 9);
      solution = Map<String, int?>.from(savedPuzzleData['solution']);
      progress = Map<String, int?>.from(savedPuzzleData['progress']);
      _currentScore = savedPuzzleData['hintsUsed'] ?? 100;
    } else {
      // Initialiseer nieuwe puzzel
      puzzle = List.generate(9, (_) => List.generate(9, (_) => null));
      solution = {}; // Voeg een oplossing toe als placeholder
      progress = {};
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProgress() async {
    await _sudokuService.saveSudokuProgress(
      userId: userId,
      puzzleId: _generatePuzzleId(),
      progress: progress,
      hintsUsed: _currentScore,
    );
  }

  String _generatePuzzleId() {
    return 'sudoku_${widget.date.toIso8601String()}';
  }

  Map<String, int?> _convert2DArrayToMap(List<List<int?>> array) {
    final Map<String, int?> map = {};
    for (int row = 0; row < array.length; row++) {
      for (int col = 0; col < array[row].length; col++) {
        map['$row$col'] = array[row][col];
      }
    }
    return map;
  }

  List<List<int?>> _convertMapTo2DArray(Map<String, int?> map, int gridSize) {
    final List<List<int?>> array = List.generate(
      gridSize,
          (_) => List.filled(gridSize, null),
    );
    map.forEach((key, value) {
      final row = int.parse(key[0]);
      final col = int.parse(key[1]);
      array[row][col] = value;
    });
    return array;
  }

  void _showHint() async {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final cellKey = '$row$col';
        if (progress[cellKey] == null) {
          setState(() {
            progress[cellKey] = solution[cellKey];
            _currentScore -= 10; // Verminder score met 10 voor een hint
            _hasChanges = true;
          });
          await _saveProgress();
          return;
        }
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geen hints meer beschikbaar!')),
    );
  }

  void _showSolution() async {
    setState(() {
      progress = Map.from(solution);
      _currentScore = 0; // Stel score in op nul
      _hasChanges = true;
    });
    await _saveProgress();
  }

  void _checkPuzzle() {
    bool isCorrect = true;
    for (final key in solution.keys) {
      if (progress[key] != solution[key]) {
        isCorrect = false;
        break;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? 'Correct opgelost!' : 'Fouten gevonden!'),
      ),
    );
  }

  Widget _buildSudokuCell(int row, int col) {
    final cellKey = '$row$col';
    final value = progress[cellKey] ?? puzzle[row][col];
    final editable = puzzle[row][col] == null;

    return GestureDetector(
      onTap: () {
        if (editable) {
          _showNumberPicker(row, col);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          color: editable ? Colors.lightBlue[100] : Colors.grey[200],
        ),
        child: Center(
          child: Text(
            value?.toString() ?? '',
            style: TextStyle(
              fontSize: 18,
              color: editable ? Colors.blue : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  void _showNumberPicker(int row, int col) async {
    final number = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kies een nummer'),
          content: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final num = index + 1;
              return ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, num); // Geef het gekozen nummer terug
                },
                child: Text(
                  num.toString(),
                  style: const TextStyle(fontSize: 18),
                ),
              );
            },
          ),
        );
      },
    );

    if (number != null) {
      setState(() {
        final cellKey = '$row$col';
        progress[cellKey] = number;
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Sudoku van ${widget.date.toLocal().toString().split(' ')[0]}'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final shouldSave = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Wijzigingen opslaan?'),
                content: const Text('Je hebt wijzigingen gemaakt. Wil je deze opslaan voordat je het scherm verlaat?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Verlaten zonder opslaan'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _saveProgress();
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Opslaan en verlaten'),
                  ),
                ],
              );
            },
          );
          return shouldSave ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sudoku van ${widget.date.toLocal().toString().split(' ')[0]}'),
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Sudoku Scoring: $_currentScore',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                  ),
                  itemCount: 81,
                  itemBuilder: (context, index) {
                    final row = index ~/ 9;
                    final col = index % 9;
                    return _buildSudokuCell(row, col);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _showHint, child: const Text('Hint')),
                ElevatedButton(onPressed: _showSolution, child: const Text('Oplossing')),
                ElevatedButton(onPressed: _checkPuzzle, child: const Text('Controle')),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
