import 'package:firebase_auth/firebase_auth.dart';
import '../models/sudoku_service.dart';
import 'dart:async';
import '../models/sudoku_generator.dart';

/// De manager-class die gebruikmaakt van SudokuService.
/// Hij houdt state vast (puzzle, solution, progress, currentScore)
/// en biedt methodes om te load/save/etc.
class SudokuManager {
  final SudokuService _sudokuService = SudokuService();

  late String userId;

  // Hier 'spiegelen' we jouw properties uit sudoku_screen:
  bool isLoading = true;
  late List<List<int?>> puzzle;      // 9x9 raster
  late Map<String, int?> solution;   // oplossingen
  late Map<String, int?> progress;   // user-invoer
  int currentScore = 100;
  bool hasChanges = false;

  DateTime? currentDate; // Om te weten welke puzzleId we bouwen
  Function(double)? onProgressUpdate; // Als je die callback wilt doorgeven

  /// Deze methode moet je aanroepen zodra je de manager instelt
  /// (bijv. in initState van sudoku_screen).
  Future<void> init(DateTime date, Function(double) onProgressUpdate) async {
    currentDate = date;
    this.onProgressUpdate = onProgressUpdate;

    // Ophalen van user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Geen gebruiker ingelogd');
    }
    userId = currentUser.uid;

    // Puzzle laden
    await _initializePuzzle();
    isLoading = false;
  }

  /// Ophalen van puzzle-data (zowel raster als progress) vanuit SudokuService
  Future<void> _initializePuzzle() async {
    final puzzleId = _generatePuzzleId();  // Bijvoorbeeld "sudoku_2025-01-08"
    final savedPuzzleData = await _sudokuService.getSudoku(userId, puzzleId);

    if (savedPuzzleData == null) {
      // GEEN data in Firestore => generate nieuwe puzzel
      final generatedData = SudokuGenerator.generatePuzzleAndSolution(currentDate!);

      puzzle = generatedData['puzzle']!;
      final solution2D = generatedData['solution']!;
      solution = convert2DArrayToMap(solution2D);
      progress = {};
      currentScore = 100;

      // Meteen het doc aanmaken in Firestore (zodat we later .update kunnen doen)
      await saveFullSudoku();

      // Nu bestaat 'sudoku_<datum>' in Firestore
    } else {
      // We HEBBEN al een doc => laad vanuit Firestore
      puzzle = _convertMapTo2DArray(
          Map<String, int?>.from(savedPuzzleData['grid']),
          9
      );
      solution = Map<String, int?>.from(savedPuzzleData['solution']);
      progress = Map<String, int?>.from(savedPuzzleData['progress']);
      currentScore = savedPuzzleData['hintsUsed'] ?? 100;
    }
  }

  Future<void> saveFullSudoku() async {
    // Converteer je 2D puzzle-lijst naar een Map
    final gridMap = _sudokuService.convert2DArrayToMap(puzzle);

    // Sla de volledige sudoku op (grid, solution, progress, hintsUsed) in Firestore
    await _sudokuService.saveSudoku(
      userId: userId,
      puzzleId: _generatePuzzleId(), // of gebruik puzzleId als je het al hebt
      grid: gridMap,
      solution: solution,
      progress: progress,
      hintsUsed: currentScore,
    );

    hasChanges = false;
  }

  /// Wegschrijven van voortgang
  Future<void> saveProgress() async {
    final puzzleId = _generatePuzzleId();
    await _sudokuService.saveSudokuProgress(
      userId: userId,
      puzzleId: puzzleId,
      progress: progress,
      hintsUsed: currentScore,
    );
    hasChanges = false;
  }

  String _generatePuzzleId() {
    // Haal alleen de "yyyy-mm-dd" uit de datum
    final dayStr = currentDate!.toIso8601String().split('T')[0];
    return 'sudoku_$dayStr'; // geen uren, minuten en seconden
  }

  /// Convert 2D-array -> map
  Map<String, int?> convert2DArrayToMap(List<List<int?>> array) {
    final Map<String, int?> map = {};
    for (int row = 0; row < array.length; row++) {
      for (int col = 0; col < array[row].length; col++) {
        map['$row$col'] = array[row][col];
      }
    }
    return map;
  }

  /// Convert map -> 2D-array
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

  /// Hint-actie
  /// Zoeken naar de eerste lege cel in progress en vul solution in.
  Future<void> showHint() async {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final cellKey = '$row$col';
        if (progress[cellKey] == null) {
          progress[cellKey] = solution[cellKey];
          currentScore -= 10;
          hasChanges = true;

          // 1) Log "hint" specifiek
          print('DEBUG: [Hint] vul cel $row,$col in, score=$currentScore');

          // 2) Nu gewoon opslaan
          await saveProgress();

          // 3) Klaar
          return;
        }
      }
    }
    // geen lege cel gevonden
  }


  /// Hele oplossing tonen
  Future<void> showSolution() async {
    progress = Map.from(solution);
    currentScore = 0;
    hasChanges = true;
    await saveProgress();
  }

  /// Controleren of progress == solution
  bool checkPuzzle() {
    for (final key in solution.keys) {
      if (progress[key] != solution[key]) {
        return false;
      }
    }
    return true;
  }

  /// Gebruiker kiest een getal
  void setNumber(int row, int col, int chosenNumber) {
    final cellKey = '$row$col';
    progress[cellKey] = chosenNumber;
    hasChanges = true;
  }
}
