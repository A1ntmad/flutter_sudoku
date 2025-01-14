import 'package:shared_preferences/shared_preferences.dart';

class ScoreManager {
  static const String _totalScoreKey = 'total_score'; // Key voor de totale score
  static const int _defaultStartScore = 100; // Standaard startscore

  /// Haalt de totale score op, met een standaardwaarde van 100 als deze niet is ingesteld.
  static Future<int> getTotalScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalScoreKey) ?? _defaultStartScore;
  }

  /// Stelt de totale score in op een specifieke waarde.
  static Future<void> setTotalScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalScoreKey, score);
  }

  /// Voegt punten toe aan de totale score.
  static Future<void> addPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    int currentScore = prefs.getInt(_totalScoreKey) ?? _defaultStartScore;
    final newScore = currentScore + points;
    await prefs.setInt(_totalScoreKey, newScore);
  }

  /// Trek punten af van de totale score, met een minimumwaarde van 0.
  static Future<void> deductPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    int currentScore = prefs.getInt(_totalScoreKey) ?? _defaultStartScore;
    final newScore = (currentScore - points).clamp(0, double.infinity).toInt();
    await prefs.setInt(_totalScoreKey, newScore);
  }

  /// Haalt de score op voor een specifieke puzzel. Standaard 100 als niet ingesteld.
  static Future<int> getPuzzleScore(String puzzleId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('score_$puzzleId') ?? _defaultStartScore;
  }

  /// Stelt de score in voor een specifieke puzzel.
  static Future<void> setPuzzleScore(String puzzleId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('score_$puzzleId', score);
  }

  /// Verwijdert een specifieke puzzelscore.
  static Future<void> clearPuzzleScore(String puzzleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('score_$puzzleId');
  }

  /// Reset alle opgeslagen scores.
  static Future<void> resetScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Controleert of de totale score is ingesteld.
  static Future<bool> hasTotalScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_totalScoreKey);
  }

  /// Debugfunctie: print alle opgeslagen scores.
  static Future<void> debugPrintAllScores() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.getKeys().forEach((key) {
      print('$key: ${prefs.get(key)}');
    });
  }
}
