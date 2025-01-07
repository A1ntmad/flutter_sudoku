import 'package:cloud_firestore/cloud_firestore.dart';

class SudokuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ophalen van Sudoku-data uit Firestore
  Future<Map<String, dynamic>?> getSudoku(String userId, String puzzleId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sudokus')
          .doc(puzzleId)
          .get();

      if (doc.exists) {
        print('DEBUG: Sudoku data gevonden voor $puzzleId: ${doc.data()}');
        return doc.data();
      } else {
        print('DEBUG: Geen Sudoku data gevonden voor $puzzleId');
        return null;
      }
    } catch (e) {
      print('ERROR: Fout bij ophalen van Sudoku data: $e');
      return null;
    }
  }

  // Opslaan van volledige Sudoku-data in Firestore
  Future<void> saveSudoku({
    required String userId,
    required String puzzleId,
    required Map<String, int?> grid,
    required Map<String, int?> solution,
    required Map<String, int?> progress,
    required int hintsUsed,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sudokus')
          .doc(puzzleId)
          .set({
        'grid': grid,
        'solution': solution,
        'progress': progress,
        'hintsUsed': hintsUsed,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('DEBUG: Sudoku succesvol opgeslagen voor $puzzleId');
    } catch (e) {
      print('ERROR: Fout bij opslaan van Sudoku: $e');
    }
  }

  // Opslaan van voortgang in Firestore
  Future<void> saveSudokuProgress({
    required String userId,
    required String puzzleId,
    required Map<String, int?> progress,
    required int hintsUsed,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sudokus')
          .doc(puzzleId)
          .update({
        'progress': progress,
        'hintsUsed': hintsUsed,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('DEBUG: Sudoku voortgang succesvol opgeslagen voor $puzzleId');
    } catch (e) {
      print('ERROR: Fout bij opslaan van Sudoku voortgang: $e');
    }
  }

  // Hulpfunctie: 2D-array naar Map converteren
  Map<String, int?> convert2DArrayToMap(List<List<int?>> array) {
    final Map<String, int?> map = {};
    for (int row = 0; row < array.length; row++) {
      for (int col = 0; col < array[row].length; col++) {
        map['$row$col'] = array[row][col];
      }
    }
    print('DEBUG: 2D-array geconverteerd naar Map: $map');
    return map;
  }

  // Hulpfunctie: Map naar 2D-array converteren
  List<List<int?>> convertMapTo2DArray(Map<String, int?> map, int rows, int cols) {
    final List<List<int?>> array = List.generate(rows, (_) => List.filled(cols, null));
    map.forEach((key, value) {
      final row = int.parse(key[0]); // Eerste cijfer is de rij
      final col = int.parse(key[1]); // Tweede cijfer is de kolom
      array[row][col] = value;
    });
    print('DEBUG: Map geconverteerd naar 2D-array: $array');
    return array;
  }
}
