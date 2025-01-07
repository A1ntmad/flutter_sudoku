import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sudoku_service.dart';



class ScoreManager {
  static const String _totalScoreKey = 'total_score';

  // Haalt de totale score op uit SharedPreferences
  static Future<int> getTotalScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalScoreKey) ?? 0; // Standaard score is 0
  }

  // Voegt punten toe aan de totale score
  static Future<void> addPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    int currentScore = prefs.getInt(_totalScoreKey) ?? 0;
    prefs.setInt(_totalScoreKey, currentScore + points);
  }

  // Verwijdert punten van de totale score
  static Future<void> deductPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    int currentScore = prefs.getInt(_totalScoreKey) ?? 0;
    prefs.setInt(_totalScoreKey, (currentScore - points).clamp(0, double.infinity).toInt());
  }

  // Haalt de score op voor een specifieke Sudoku-puzzel
  static Future<int> getScore(String puzzleId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('score_$puzzleId') ?? 100; // Standaard score is 100
  }

  // Stelt de score in voor een specifieke Sudoku-puzzel
  static Future<void> saveScore(String puzzleId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('score_$puzzleId', score);
  }

  // Verwijdert een specifieke Sudoku-score
  static Future<void> clearScore(String puzzleId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('score_$puzzleId');
  }
}
