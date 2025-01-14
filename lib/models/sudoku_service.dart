import 'package:cloud_firestore/cloud_firestore.dart';

class SudokuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ophalen van Sudoku-data uit Firestore
  /// Retourneert een Map<String, dynamic> of null (als de doc niet bestaat).
  Future<Map<String, dynamic>?> getSudoku(String userId, String puzzleId) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sudokus')
          .doc(puzzleId)
          .get();

      if (docSnapshot.exists) {
        print('DEBUG: Sudoku data gevonden voor $puzzleId: ${docSnapshot.data()}');
        // Firestore .data() is Map<String, dynamic>? in Dart
        return docSnapshot.data() as Map<String, dynamic>?;
      } else {
        print('DEBUG: Geen Sudoku data gevonden voor $puzzleId');
        return null;
      }
    } catch (e) {
      print('ERROR: Fout bij ophalen van Sudoku data: $e');
      return null;
    }
  }

  /// Opslaan van de gehele Sudoku (grid + solution + progress + hintsUsed).
  Future<void> saveSudoku({
    required String userId,
    required String puzzleId,
    required Map<String, int?> grid,
    required Map<String, int?> solution,
    required Map<String, int?> progress,
    required int hintsUsed,
    String status = "inProgress", // Voeg een standaardstatus toe
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
        'status': status, // Status wordt opgeslagen
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('DEBUG: Sudoku succesvol opgeslagen voor $puzzleId');
    } catch (e) {
      print('ERROR: Fout bij opslaan van Sudoku: $e');
    }
  }


  /// Alleén de voortgang (progress en hintsUsed) updaten in een al bestaand doc.
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

  /// Hulpfunctie: 2D-array -> Map
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

  /// Hulpfunctie: Map -> 2D-array
  List<List<int?>> convertMapTo2DArray(Map<String, int?> map, int rows, int cols) {
    final List<List<int?>> array = List.generate(
      rows,
          (_) => List.filled(cols, null),
    );
    map.forEach((key, value) {
      final row = int.parse(key[0]); // Bijv. "05" -> row=0
      final col = int.parse(key[1]); // Bijv. "05" -> col=5
      array[row][col] = value;
    });
    print('DEBUG: Map geconverteerd naar 2D-array: $array');
    return array;
  }
}
