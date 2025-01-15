import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class BinairGenerator {
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

  // Genereer een geldig binair grid
  List<List<int>> generateValidGrid() {
    List<List<int>> grid = generateEmptyGrid();
    Random random = Random();

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        int value = random.nextBool() ? 0 : 1;
        grid[row][col] = value;
        if (!isRowValid(grid[row]) || !isColumnValid(grid, col)) {
          grid[row][col] = -1; // Ongeldige waarde herstellen
        }
      }
    }

    return grid;
  }

  // Sla een nieuw binair grid op in Firestore per gebruiker
  Future<void> saveGridToFirestore(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final today = DateTime.now().toIso8601String().split('T').first;

    // Referentie naar de gebruiker in Firestore
    final userRef = firestore.collection('users').doc(userId).collection('binair');

    // Controleer of er al een puzzel is voor vandaag
    final existingDoc = await userRef.doc(today).get();
    if (!existingDoc.exists) {
      // Genereer en sla een nieuwe puzzel op
      List<List<int>> newGrid = generateValidGrid();
      await userRef.doc(today).set({
        'grid': newGrid,
        'date': today,
      });
    }
  }

  // Haal een binair grid op voor een specifieke datum
  Future<List<List<int>>?> getGridForDate(String userId, String date) async {
    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(userId).collection('binair');

    final doc = await userRef.doc(date).get();
    if (doc.exists) {
      // Haal de data op als een List<dynamic>
      List<dynamic> gridJson = doc.data()?['grid'];

      // Converteer List<dynamic> naar List<List<int>>
      List<List<int>> grid = gridJson
          .map((row) => (row as List<dynamic>).map((cell) => cell as int).toList())
          .toList();

      return grid;
    }
    return null;
  }

  // Haal het grid van vandaag op (of genereer en sla op als het niet bestaat)
  Future<List<List<int>>> getTodayGrid(String userId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    await saveGridToFirestore(userId); // Zorg ervoor dat het grid van vandaag bestaat
    return (await getGridForDate(userId, today))!;
  }
}
