import 'package:shared_preferences/shared_preferences.dart';

class PuzzleProgressManager {
  // Sla een individuele cel op
  static Future<void> saveCell(String puzzleId, int row, int col, int? value) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'puzzle_$puzzleId';
    List<String>? savedPuzzle = prefs.getStringList(key);

    if (savedPuzzle == null) {
      // Als er nog geen opgeslagen puzzel is, maak een nieuwe lege puzzel
      savedPuzzle = List.generate(9, (_) => List.generate(9, (_) => 'null').join(','));
    }

    // Zet de waarde voor de specifieke cel
    List<List<String>> puzzle = savedPuzzle.map((row) => row.split(',')).toList();
    puzzle[row][col] = value?.toString() ?? 'null';

    // Sla de puzzel op
    prefs.setStringList(key, puzzle.map((row) => row.join(',')).toList());
  }

  // Sla de volledige puzzelstatus op
  static Future<void> savePuzzle(String puzzleId, List<List<int?>> puzzle) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'puzzle_$puzzleId';

    // Converteer de puzzel naar een lijst van strings
    final rows = puzzle.map((row) {
      return row.map((cell) => cell?.toString() ?? 'null').join(',');
    }).toList();

    // Sla de volledige puzzel op
    await prefs.setStringList(key, rows);
    print('Puzzel opgeslagen: $rows');
  }

  // Laad de volledige puzzelstatus
  static Future<List<List<int?>>?> loadPuzzle(String puzzleId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'puzzle_$puzzleId';
    List<String>? savedPuzzle = prefs.getStringList(key);

    if (savedPuzzle == null) return null;

    return savedPuzzle.map((row) {
      return row.split(',').map((cell) => cell == 'null' ? null : int.parse(cell)).toList();
    }).toList();
  }
}
