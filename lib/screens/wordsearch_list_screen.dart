import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Voor JSON-serialisatie
import 'wordsearch_screen.dart';

class WordsearchListScreen extends StatefulWidget {
  const WordsearchListScreen({Key? key}) : super(key: key);

  @override
  _WordsearchListScreenState createState() => _WordsearchListScreenState();
}

class _WordsearchListScreenState extends State<WordsearchListScreen> {
  late Map<String, String> _statusMap;
  bool _isLoading = true;
  final List<bool> _expandedPanels = [false, false, false];
  late List<DateTime> _completedDates;
  late List<DateTime> _inProgressDates;
  late List<DateTime> _notStartedDates;

  @override
  void initState() {
    super.initState();
    _statusMap = {};
    _expandedPanels.fillRange(0, _expandedPanels.length, false);
    _loadStatuses();
  }

  /// Normalizeer een datum naar middernacht (00:00:00)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _loadStatuses() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Stap 1: Haal de cache op
      final cachedStatuses = prefs.getString('statusMap_$userId');
      if (cachedStatuses != null) {
        _statusMap = Map<String, String>.from(jsonDecode(cachedStatuses));
        print('DEBUG: Cached statusMap geladen: $_statusMap');
      } else {
        _statusMap = {};
      }

      // Toon direct de gecachte data (indien aanwezig)
      final allDates = _generatePuzzleDates();
      _categorizeDates(allDates);
      setState(() {});

      // Stap 2: Query Firestore voor nieuwe data
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wordsearches')
          .where('puzzleDate', isLessThanOrEqualTo: DateTime.now().toIso8601String())
          .get();

      for (var doc in snapshot.docs) {
        final date = doc.id.split('_')[1]; // Extract datum
        final status = doc.data()['status'] ?? 'new'; // Extract status
        _statusMap[date] = status;
      }

      // Stap 3: Sla nieuwe data op in cache
      await prefs.setString('statusMap_$userId', jsonEncode(_statusMap));

      // Werk categorisering bij
      _categorizeDates(allDates);

      setState(() {
        _isLoading = false; // Laadstatus klaar
      });

      print('DEBUG: StatusMap bijgewerkt en opgeslagen in cache: $_statusMap');
    } catch (e) {
      print('ERROR: Fout bij het laden van statussen: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Genereer puzzeldatums vanaf 2025-01-01 tot vandaag
  List<DateTime> _generatePuzzleDates() {
    final today = _normalizeDate(DateTime.now());
    final startDate = DateTime(2025, 1, 1);

    return List.generate(
      today.difference(startDate).inDays + 1,
          (index) => _normalizeDate(today.subtract(Duration(days: index))),
    );
  }

  /// Categoriseer puzzeldatums
  void _categorizeDates(List<DateTime> allDates) {
    _completedDates = allDates
        .where((date) => _statusMap[date.toIso8601String().split('T')[0]] == 'completed')
        .toList();

    _inProgressDates = allDates
        .where((date) => _statusMap[date.toIso8601String().split('T')[0]] == 'inProgress')
        .toList();

    _notStartedDates = allDates
        .where((date) => !_statusMap.containsKey(date.toIso8601String().split('T')[0]) ||
        _statusMap[date.toIso8601String().split('T')[0]] == 'new')
        .toList();

    print('DEBUG: Categorized dates - Completed: $_completedDates');
    print('DEBUG: Categorized dates - In Progress: $_inProgressDates');
    print('DEBUG: Categorized dates - Not Started: $_notStartedDates');
  }


  /// Bouw een enkele categorie
  ExpansionPanel _buildCategory(
      String title,
      List<DateTime> dates,
      bool isExpanded,
      int panelIndex,
      ) {
    return ExpansionPanel(
      headerBuilder: (_, __) => ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: dates.isEmpty
          ? const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Geen woordzoekers beschikbaar'),
      )
          : Column(
        children: dates.map((date) {
          final dateKey = date.toIso8601String().split('T')[0];
          final status = _statusMap[dateKey] ?? 'new';

          return ListTile(
            title: Text(
              "Puzzel voor ${date.toLocal().toString().split(' ')[0]}",
              style: TextStyle(
                color: status == 'completed' ? Colors.grey : Colors.black,
                decoration: status == 'completed'
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: status == 'completed'
                ? const Text(
              'Afgerond',
              style: TextStyle(color: Colors.grey),
            )
                : null,
            onTap: status == 'completed'
                ? null
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WordsearchScreen(
                    puzzleId: 'wordsearch_$dateKey',
                  ),
                ),
              ).then((shouldReload) {
                print('DEBUG: Teruggekomen van WordsearchScreen met shouldReload = $shouldReload');
                if (shouldReload == true) {
                  print('DEBUG: _loadStatuses() wordt aangeroepen');
                  _loadStatuses(); // Lijst opnieuw laden
                }
              });
            },
          );
        }).toList(),
      ),
      isExpanded: isExpanded,
      canTapOnHeader: true,
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Woordzoekers'),
      ),
      body: SingleChildScrollView(
        child: ExpansionPanelList(
          expansionCallback: (index, isExpanded) {
            setState(() {
              _expandedPanels[index] = !_expandedPanels[index];
            });
          },
          children: [
            _buildCategory('Mee bezig', _inProgressDates, _expandedPanels[0], 0),
            _buildCategory('Nog te doen', _notStartedDates, _expandedPanels[1], 1),
            _buildCategory('Afgerond', _completedDates, _expandedPanels[2], 2),
          ],
        ),
      ),
    );
  }
}
