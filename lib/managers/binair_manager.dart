import 'dart:math';

class BinairManager {
  static const int gridSize = 12;

  // Genereer een leeg grid
  List<List<int>> generateEmptyGrid() {
    return List.generate(gridSize, (_) => List.filled(gridSize, -1));
  }

  // Controleer of een rij geldig is
  bool isRowValid(List<int> row) {
    int count0 = row.where((cell) => cell == 0).length;
    int count1 = row.where((cell) => cell == 1).length;
    if (count0 > gridSize ~/ 2 || count1 > gridSize ~/ 2) return false;

    for (int i = 0; i < row.length - 2; i++) {
      if (row[i] == row[i + 1] && row[i] == row[i + 2]) return false;
    }
    return true;
  }

  // Controleer of een kolom geldig is
  bool isColumnValid(List<List<int>> grid, int colIndex) {
    int count0 = 0;
    int count1 = 0;

    for (int i = 0; i < grid.length; i++) {
      if (grid[i][colIndex] == 0) count0++;
      if (grid[i][colIndex] == 1) count1++;
      if (i > 1 &&
          grid[i][colIndex] == grid[i - 1][colIndex] &&
          grid[i][colIndex] == grid[i - 2][colIndex]) {
        return false;
      }
    }

    return count0 <= gridSize ~/ 2 && count1 <= gridSize ~/ 2;
  }

  // Controleer of het grid geldig is
  bool isGridValid(List<List<int>> grid) {
    for (int i = 0; i < gridSize; i++) {
      if (!isRowValid(grid[i]) || !isColumnValid(grid, i)) return false;
    }
    return true;
  }

  // Genereer een volledig geldig grid
  List<List<int>> generateValidGrid() {
    List<List<int>> grid = generateEmptyGrid();
    Random random = Random();

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        // Probeer waarden totdat de rij en kolom geldig blijven
        for (int attempt = 0; attempt < 2; attempt++) {
          int value = random.nextBool() ? 0 : 1;
          grid[row][col] = value;

          if (isRowValid(grid[row]) && isColumnValid(grid, col)) {
            break;
          }

          // Als geen waarde past, herstel naar leeg
          grid[row][col] = -1;
        }
      }
    }

    // Valideer of het volledige grid voldoet
    if (!isGridValid(grid)) {
      return generateValidGrid(); // Herstart als het grid ongeldig is
    }

    return grid;
  }
}
