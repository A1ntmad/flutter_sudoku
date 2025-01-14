import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sudoku_service.dart';
import 'dart:async';
import '../models/sudoku_generator.dart';
import 'dart:math';

class SudokuManager {
  final SudokuService _sudokuService = SudokuService();

  late String userId;

  bool isLoading = true;
  late List<List<int?>> puzzle; // 9x9 raster
  late Map<String, int?> solution; // oplossingen
  late Map<String, int?> progress; // user-invoer
  int currentScore = 100;
  bool hasChanges = false;

  DateTime? currentDate;
  Function(double)? onProgressUpdate;

  // Houd de geselecteerde cel bij
  int? selectedRow;
  int? selectedCol;

  Future<void> init(DateTime date, Function(double) onProgressUpdate) async {
    currentDate = date;
    this.onProgressUpdate = onProgressUpdate;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Geen gebruiker ingelogd');
    }
    userId = currentUser.uid;

    await _initializePuzzle();
    isLoading = false;
  }

  Future<void> _initializePuzzle() async {
    final puzzleId = _generatePuzzleId();
    final savedPuzzleData = await _sudokuService.getSudoku(userId, puzzleId);

    if (savedPuzzleData == null) {
      final generatedData = SudokuGenerator.generatePuzzleAndSolution(currentDate!);
      puzzle = generatedData['puzzle']!;
      final solution2D = generatedData['solution']!;
      solution = convert2DArrayToMap(solution2D);
      progress = {};
      currentScore = 100;

      await saveFullSudoku();
    } else {
      puzzle = _convertMapTo2DArray(
          Map<String, int?>.from(savedPuzzleData['grid']),
          9
      );
      solution = Map<String, int?>.from(savedPuzzleData['solution']);
      progress = Map<String, int?>.from(savedPuzzleData['progress']);
      currentScore = savedPuzzleData['hintsUsed'] ?? 100;
    }
  }

  Future<void> saveFullSudoku({String status = "inProgress"}) async {
    final gridMap = _sudokuService.convert2DArrayToMap(puzzle);

    await _sudokuService.saveSudoku(
      userId: userId,
      puzzleId: _generatePuzzleId(),
      grid: gridMap,
      solution: solution,
      progress: progress,
      hintsUsed: currentScore,
      status: status,
    );

    hasChanges = false;
  }


  Future<void> saveProgress() async {
    final puzzleId = _generatePuzzleId();

    try {
      await _sudokuService.saveSudokuProgress(
        userId: userId,
        puzzleId: puzzleId,
        progress: progress,
        hintsUsed: currentScore,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sudokus')
          .doc(puzzleId)
          .update({'status': 'inProgress'});

      hasChanges = false;
    } catch (e) {
    }
  }



  String _generatePuzzleId() {
    final dayStr = currentDate!.toIso8601String().split('T')[0];
    return 'sudoku_$dayStr';
  }

  Map<String, int?> convert2DArrayToMap(List<List<int?>> array) {
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

  void selectCell(int row, int col) {
    selectedRow = row;
    selectedCol = col;
    print('DEBUG: Geselecteerde cel is nu: Row $row, Col $col');
  }

  void clearSelectedCell() {
    if (selectedRow != null && selectedCol != null) {
      final cellKey = '$selectedRow$selectedCol';
      if (puzzle[selectedRow!][selectedCol!] == null) {
        progress[cellKey] = null;
        hasChanges = true;
        print('DEBUG: Cel gewist: $cellKey');
      } else {
        print('DEBUG: Niet-bewerkbare cel kan niet worden gewist.');
      }
    }
  }

  void clearCell(int row, int col) {
    final cellKey = '$row$col';
    if (puzzle[row][col] == null) {
      progress[cellKey] = null;
      hasChanges = true;
      print('DEBUG: Cel gewist: $cellKey');
    } else {
      print('DEBUG: Niet-bewerkbare cel kan niet worden gewist.');
    }
  }

  Future<void> showHint() async {
    List<Map<String, int>> blueCells = [];
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final cellKey = '$row$col';
        if (progress[cellKey] == null && puzzle[row][col] == null) {
          blueCells.add({'row': row, 'col': col});
        }
      }
    }

    if (blueCells.isEmpty) {
      print('DEBUG: Geen lege bewerkbare cellen meer beschikbaar voor hints');
      return;
    }

    final random = Random();
    final randomCell = blueCells[random.nextInt(blueCells.length)];
    final row = randomCell['row']!;
    final col = randomCell['col']!;
    final cellKey = '$row$col';

    final hintValue = solution[cellKey];

    if (hintValue != null) {
      setNumber(row, col, hintValue);
      currentScore = (currentScore - 10).clamp(0, 100);
      hasChanges = true;
      print('DEBUG: Hint toegevoegd aan blauwe cel $cellKey met waarde $hintValue');
    } else {
      print('DEBUG: Geen hint beschikbaar voor blauwe cel $cellKey');
    }
  }

  void clearSudoku() {
    progress.clear();

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final cellKey = '$row$col';
        if (puzzle[row][col] == null) {
          progress[cellKey] = null;
        }
      }
    }

    hasChanges = true;
  }

  Future<void> showSolution() async {
    progress = Map.from(solution);
    currentScore = 0;
    hasChanges = true;
    await saveProgress();
  }

  bool checkPuzzle() {
    for (final key in solution.keys) {
      if (progress[key] != solution[key]) {
        return false;
      }
    }
    return true;
  }

  void setNumber(int row, int col, int chosenNumber) {
    final cellKey = '$row$col';
    progress[cellKey] = chosenNumber;
    hasChanges = true;
    print('DEBUG: Progress bijgewerkt: $progress');
  }
}
