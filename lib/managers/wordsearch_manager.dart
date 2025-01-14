import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../managers/score_manager.dart';

class WordSearchManager {
  late String userId;
  bool hasChanges = false; // Bijhouden of de puzzel is aangepast

  // Properties voor de woordzoeker
  late List<List<String>> grid; // Het woordzoekergrid
  late List<Map<String, dynamic>> words; // Lijst met woorden en hun coördinaten
  Set<String> foundWords = {}; // Bijhouden van gevonden woorden
  Map<String, Color> wordColors = {}; // Kleuren van gevonden woorden
  bool isLoading = true;

  DateTime? currentDate;

  // Scorebeheer
  int _currentScore = 100; // Standaard startscore
  int get currentScore => _currentScore;

  // Hint-beheer
  int hintsUsed = 0; // Aantal gebruikte hints
  final int maxHints = 3; // Maximaal aantal hints toegestaan

  final List<Color> _highlightColors = [
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.amber,
    Colors.pink,
    Colors.lime,
  ];

  /// Controleer of een hint beschikbaar is
  bool canUseHint() {
    return hintsUsed < maxHints;
  }

  /// Verhoog het aantal gebruikte hints en trek punten af
  Future<void> incrementHintsUsed() async {
    if (canUseHint()) {
      hintsUsed++;
      await deductPoints(10); // Trek exact 10 punten af
      hasChanges = true; // Markeer dat er een wijziging is
    }
  }


  /// Genereer een hint door een willekeurige letter van een nog niet gevonden woord te markeren
  Future<Map<String, dynamic>?> generateHint() async {
    if (!canUseHint()) return null; // Controleer of hints beschikbaar zijn

    // Kies een woord dat nog niet gevonden is
    final remainingWords = words.where((word) => !foundWords.contains(word['word'])).toList();
    if (remainingWords.isEmpty) return null; // Geen hints meer beschikbaar

    // Selecteer een willekeurig woord en een willekeurige letter binnen dat woord
    final randomWord = remainingWords[Random().nextInt(remainingWords.length)];
    final randomCoordinate = randomWord['coordinates'][Random().nextInt(randomWord['coordinates'].length)];

    // Splits de coördinaat in rij en kolom
    final rowCol = randomCoordinate.split('-');
    final row = int.parse(rowCol[0]);
    final col = int.parse(rowCol[1]);

    await incrementHintsUsed();

    return {'row': row, 'col': col, 'letter': grid[row][col]};
  }


  /// Voeg punten toe aan de score
  Future<void> addPoints(int points) async {
    _currentScore += points; // Update lokale score
    await ScoreManager.setPuzzleScore(currentDate.toString(), _currentScore);
    print("DEBUG: $points punten toegevoegd. Nieuwe score: $_currentScore");
  }

  /// Trek punten af van de score
  Future<void> deductPoints(int points) async {
    _currentScore = (_currentScore - points).clamp(0, double.infinity).toInt();
    await ScoreManager.setPuzzleScore(currentDate.toString(), _currentScore);
    print("DEBUG: $points punten afgetrokken. Nieuwe score: $_currentScore");
  }

  /// Initialisatie van de manager
  Future<void> init(DateTime date, String puzzleId) async {
    currentDate = date;

    // Ophalen van de huidige gebruiker
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Geen gebruiker ingelogd');
    }
    userId = currentUser.uid;

    // Controleer of de puzzel al bij de gebruiker staat
    final userPuzzleDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wordsearches')
        .doc(puzzleId)
        .get();

    if (!userPuzzleDoc.exists) {
      await copyPuzzleToUser(puzzleId);
    }

    final userPuzzleData = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wordsearches')
        .doc(puzzleId)
        .get();

    if (!userPuzzleData.exists) {
      throw Exception('Fout bij laden van puzzeldata.');
    }

    await _initializePuzzle(userPuzzleData.data()!);

    // Stel score specifiek in voor deze puzzel
    _currentScore = await ScoreManager.getPuzzleScore(puzzleId);
    if (_currentScore == 0) {
      _currentScore = 100;
      await ScoreManager.setPuzzleScore(puzzleId, _currentScore);
    }
  }

  /// Kopieer puzzeldata naar `users/{userId}/wordsearches/{puzzleId}`
  Future<void> copyPuzzleToUser(String puzzleId) async {
    try {
      final puzzleDoc = await FirebaseFirestore.instance
          .collection('puzzles')
          .doc(puzzleId)
          .get();

      if (!puzzleDoc.exists) {
        throw Exception('Puzzel bestaat niet in de puzzles-collectie.');
      }

      final puzzleData = puzzleDoc.data();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wordsearches')
          .doc(puzzleId)
          .set({
        ...puzzleData!,
        'foundWords': [],
        'wordColors': {},
        'status': 'new',
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("ERROR: Fout bij het kopiëren van puzzeldata: $e");
    }
  }

  /// Laden van het grid, de woordenlijst en de opgeslagen voortgang
  Future<void> _initializePuzzle(Map<String, dynamic> puzzleData) async {
    print('DEBUG: Start initialisatie van puzzel.');
    grid = (puzzleData['puzzle'] as List<dynamic>)
        .map((row) => row.toString().split(''))
        .toList();

    words = (puzzleData['solution'] as List<dynamic>)
        .map((wordData) {
      final coordinates = (wordData['coordinates'] as List<dynamic>)
          .map((coord) => '${coord['row']}-${coord['col']}')
          .toList();
      return {
        'word': wordData['word'],
        'coordinates': coordinates,
        'reversed': wordData['reversed'] ?? false,
      };
    }).toList();

    foundWords = (puzzleData['foundWords'] as List<dynamic>).cast<String>().toSet();

    final savedColors = (puzzleData['wordColors'] as Map<String, dynamic>?) ?? {};
    wordColors = savedColors.map((word, color) =>
        MapEntry(word, Color(int.parse(color, radix: 16))));

    foundWords.forEach((word) {
      if (!wordColors.containsKey(word)) {
        assignColorToWord(word);
      }
    });
  }

  /// Opslaan van voortgang in Firestore
  Future<bool> saveProgress(String puzzleId, {String status = 'inProgress'}) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wordsearches')
          .doc(puzzleId)
          .set({
        'foundWords': foundWords.toList(),
        'wordColors': wordColors.map((word, color) =>
            MapEntry(word, color.value.toRadixString(16))),
        'status': status, // Gebruik de statusparameter
        'lastUpdated': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // Sla de specifieke score op
      await ScoreManager.setPuzzleScore(puzzleId, _currentScore);

      hasChanges = false;
      print("DEBUG: Status bijgewerkt naar '$status' en opgeslagen in Firestore.");
      return true; // Geef aan dat opslaan succesvol was
    } catch (e) {
      print("ERROR: Fout bij opslaan van voortgang: $e");
      return false; // Geef aan dat opslaan is mislukt
    }
  }

  /// Wijs een kleur toe aan een woord
  void assignColorToWord(String word) {
    if (!wordColors.containsKey(word)) {
      wordColors[word] =
      _highlightColors[wordColors.length % _highlightColors.length];
    }
  }

  /// Valideer of een geselecteerd woord correct is
  Future<bool> validateWord(List<String> selectedPattern) async {
    for (var word in words) {
      List<String> coordinates = List<String>.from(word['coordinates']);

      if (word['reversed'] ?? false) {
        coordinates = coordinates.reversed.toList();
      }

      if (listEquals(selectedPattern, coordinates)) {
        foundWords.add(word['word']);
        assignColorToWord(word['word']);
        hasChanges = true; // Markeer dat er een wijziging is
        return true;
      }
    }
    return false;
  }

  /// Controleren of de puzzel is voltooid
  bool isCompleted() {
    return foundWords.length == words.length;
  }

  /// Reset de voortgang van de puzzel
  Future<void> resetProgress(String puzzleId) async {
    foundWords.clear();
    wordColors.clear();
    await saveProgress(puzzleId);
  }
}
