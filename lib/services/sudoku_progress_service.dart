// lib/services/sudoku_progress_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/sudoku_state.dart';

class SudokuProgressService {
  // Singleton-patroon (optioneel, zodat je één instance gebruikt in de app)
  static final SudokuProgressService _instance = SudokuProgressService._internal();
  factory SudokuProgressService() => _instance;
  SudokuProgressService._internal();

  // Firestore-instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sla de Sudoku-voortgang op in Firestore.
  /// We gebruiken hier een collectie 'sudoku_states' en een document
  /// met het user.uid als ID (dus per user maximaal één Sudoku).
  /// Als je meerdere puzzels per gebruiker wilt opslaan, kun je dit anders structureren.
  Future<void> saveSudokuProgress(SudokuState state) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in, cannot save progress.');
      return;
    }

    // Converteer de SudokuState naar een Map
    final data = state.toJson();

    // We willen graag de "updatedAt" zetten via de server om de actuele server-tijd te krijgen.
    // Dus we overschrijven de "updatedAt" uit toJson() met FieldValue.serverTimestamp()
    data['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await _firestore
          .collection('sudoku_states')
          .doc(user.uid) // doc ID = user.uid
          .set(data, SetOptions(merge: true));

      print('Sudoku progress saved to Firestore for user: ${user.uid}');
    } catch (e) {
      print('Error saving Sudoku progress: $e');
    }
  }

  /// Haal de Sudoku-voortgang op uit Firestore.
  /// Returned null als er geen doc is voor deze user, of als de user niet is ingelogd.
  Future<SudokuState?> loadSudokuProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in, cannot load progress.');
      return null;
    }

    try {
      final docSnapshot = await _firestore
          .collection('sudoku_states')
          .doc(user.uid)
          .get();

      if (!docSnapshot.exists) {
        // Document niet gevonden, dus geen opgeslagen voortgang
        print('No sudoku progress found for user: ${user.uid}');
        return null;
      }

      final data = docSnapshot.data();
      if (data == null) {
        return null;
      }

      // Als updatedAt door de server is gezet, staat er een Timestamp in Firestore,
      // dus converteren we die naar String om 'm door te geven aan fromJson.
      if (data['updatedAt'] is Timestamp) {
        final ts = data['updatedAt'] as Timestamp;
        data['updatedAt'] = ts.toDate().toIso8601String();
      }

      final state = SudokuState.fromJson(data);
      print('Sudoku progress loaded for user: ${user.uid} => $state');
      return state;
    } catch (e) {
      print('Error loading Sudoku progress: $e');
      return null;
    }
  }
}
