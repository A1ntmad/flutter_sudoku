import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sudoku_screen.dart';

class SudokuListScreen extends StatefulWidget {
  const SudokuListScreen({Key? key}) : super(key: key);

  @override
  _SudokuListScreenState createState() => _SudokuListScreenState();
}

class _SudokuListScreenState extends State<SudokuListScreen> {
  Map<DateTime, String> _statusMap = {};
  bool _isLoading = true; // Laadstatus
  final List<bool> _expandedPanels = [
    true,
    true,
    true
  ]; // Uitklapstatus per categorie

  @override
  @override
  void initState() {
    super.initState();

    // Zorg ervoor dat de _expandedPanels is geïnitialiseerd met de juiste standaardwaarden
    _expandedPanels.fillRange(0, _expandedPanels.length, false);
    print('DEBUG: Initialized _expandedPanels: $_expandedPanels');

    // Laad de statussen van Firestore
    _loadStatuses(); // Dit heb je al in je bestaande code
  }


  /// Normalizeer een datum naar middernacht (00:00:00)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Laad puzzelstatussen vanuit Firestore
  Future<void> _loadStatuses() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sudokus')
          .get();

      final Map<DateTime, String> statuses = {};
      for (var doc in snapshot.docs) {
        final date = _normalizeDate(
            DateTime.parse(doc.id.split('_')[1])); // Normalizeer datum
        final status = doc['status'] ?? 'inProgress';
        statuses[date] = status;
      }

      setState(() {
        _statusMap = statuses;
        _isLoading = false; // Laadstatus klaar
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Bouw een enkele categorie
  ExpansionPanel _buildCategory(String title, List<DateTime> dates,
      bool isExpanded, int panelIndex) {
    print('DEBUG: Building category $title with ${dates.length} items');
    return ExpansionPanel(
      headerBuilder: (context, isExpanded) {
        return ListTile(
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );
      },
      body: dates.isEmpty
          ? const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Geen Sudoku\'s beschikbaar'),
      )
          : Column(
        children: dates.map((date) {
          final isCompleted = _statusMap[date] == 'completed';
          return Container(
            child: ListTile(
              title: Text(
                'Sudoku van ${date.toLocal().toString().split(' ')[0]}',
                style: TextStyle(
                  color: isCompleted ? Colors.grey : Colors.black,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: isCompleted
                  ? const Text(
                'Afgerond',
                style: TextStyle(color: Colors.grey),
              )
                  : null,
              onTap: isCompleted
                  ? null
                  : () {
                print('DEBUG: ListTile tapped for date: $date');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SudokuScreen(
                          date: date,
                          onProgressUpdate: (newProgress) {
                            print('DEBUG: Progress updated to $newProgress');
                          },
                        ),
                  ),
                ).then((shouldReload) {
                  print('DEBUG: Returned from SudokuScreen with $shouldReload');
                  if (shouldReload == true) {
                    _loadStatuses();
                  }
                });
              },
            ),
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
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final completedDates = _statusMap.keys
        .where((date) => _statusMap[date] == 'completed')
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final inProgressDates = _statusMap.keys
        .where((date) => _statusMap[date] == 'inProgress')
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final notStartedDates = List.generate(
        30, (index) =>
        _normalizeDate(DateTime.now().subtract(Duration(days: index))))
        .where((date) => !_statusMap.containsKey(date))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kies een Sudoku'),
      ),
      body: SingleChildScrollView(
        child: ExpansionPanelList(
          expansionCallback: (panelIndex, isExpanded) {
            print(
                'DEBUG: Panel $panelIndex toggled. Current state: $isExpanded');
            setState(() {
              _expandedPanels[panelIndex] = !_expandedPanels[panelIndex];
              print('DEBUG: Updated _expandedPanels: $_expandedPanels');
            });
          },
          children: [
            // Nieuwe volgorde: Mee bezig, Nog te doen, Afgerond
            _buildCategory('Mee bezig', inProgressDates, _expandedPanels[0], 0),
            _buildCategory(
                'Nog te doen', notStartedDates, _expandedPanels[1], 1),
            _buildCategory('Afgerond', completedDates, _expandedPanels[2], 2),
          ],
        ),
      ),
    );
  }
}
