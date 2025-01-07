import 'dart:math';

class SudokuGenerator {
  static Map<String, List<List<int?>>> generatePuzzleAndSolution(DateTime date) {
    // Gebruik de datum als seed voor de random generator
    int seed = date.year * 10000 + date.month * 100 + date.day;
    Random random = Random(seed);

    // Volledig ingevulde sudoku (voorbeeld)
    List<List<int>> completePuzzle = [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ];

    // Maak een kopie van de oplossing
    List<List<int?>> puzzle = completePuzzle.map((row) => row.map((e) => e as int?).toList()).toList();

    // Maak de puzzel gedeeltelijk leeg
    _removeCells(puzzle, 40, random); // Verwijder 40 cellen om een puzzel te maken

    // Retourneer zowel de puzzel als de oplossing
    return {
      'puzzle': puzzle,
      'solution': completePuzzle,
    };
  }

  static void _removeCells(List<List<int?>> puzzle, int cellsToRemove, Random random) {
    for (int i = 0; i < cellsToRemove; i++) {
      int row = random.nextInt(9);
      int col = random.nextInt(9);

      // Zorg dat een cel niet meerdere keren wordt verwijderd
      while (puzzle[row][col] == null) {
        row = random.nextInt(9);
        col = random.nextInt(9);
      }
      puzzle[row][col] = null; // Leeg maken
    }
  }

  /// Haal de originele puzzelstructuur op, zonder wijzigingen.
  static Future<List<List<int?>>> getOriginalPuzzle(DateTime date) async {
    // Genereer de puzzel opnieuw op basis van de datum
    final generatedData = generatePuzzleAndSolution(date);

    // Retourneer de originele puzzelstructuur
    return generatedData['puzzle']!;
  }
}
