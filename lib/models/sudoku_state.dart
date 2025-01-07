// lib/models/sudoku_state.dart

class SudokuState {
  /// 9x9 Sudoku-bord:
  /// - `null` => leeg vakje
  /// - `int` (1..9) => ingevuld vakje
  final List<List<int?>> board;

  /// Of de Sudoku is voltooid
  final bool isCompleted;

  /// Moeilijkheidsgraad (optioneel, pas aan naar wens)
  final String difficulty;

  /// Datum/tijd wanneer deze state voor het laatst is geüpdatet.
  final DateTime updatedAt;

  SudokuState({
    required this.board,
    required this.isCompleted,
    required this.difficulty,
    required this.updatedAt,
  });

  /// Converteer deze state naar een JSON-achtig Map,
  /// zodat we dit eenvoudig in Firestore kunnen opslaan.
  Map<String, dynamic> toJson() {
    return {
      'board': board
      // null => 0, omdat Firestore arrays geen null op die manier hanteren
          .map((row) => row.map((cell) => cell ?? 0).toList())
          .toList(),
      'isCompleted': isCompleted,
      'difficulty': difficulty,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Lees vanuit een Firestore Map terug naar onze Dart-structuur.
  factory SudokuState.fromJson(Map<String, dynamic> json) {
    // Bord parsen uit de Map
    final boardJson = json['board'] as List<dynamic>?;
    final board = boardJson != null
        ? boardJson.map((row) {
      return (row as List<dynamic>)
          .map((cell) => cell == 0 ? null : cell as int)
          .toList();
    }).toList()
        : <List<int?>>[];

    // updatedAt kan als string (of Timestamp) binnenkomen, we proberen hem te parsen
    DateTime parsedDateTime = DateTime.now();
    if (json['updatedAt'] is String) {
      parsedDateTime = DateTime.tryParse(json['updatedAt']) ?? DateTime.now();
    }

    return SudokuState(
      board: board,
      isCompleted: json['isCompleted'] ?? false,
      difficulty: json['difficulty'] ?? 'unknown',
      updatedAt: parsedDateTime,
    );
  }

  @override
  String toString() {
    return 'SudokuState(isCompleted: $isCompleted, difficulty: $difficulty, updatedAt: $updatedAt)';
  }
}
