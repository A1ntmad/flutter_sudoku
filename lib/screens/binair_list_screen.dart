import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'binair_screen.dart';

class BinairListScreen extends StatefulWidget {
  const BinairListScreen({Key? key}) : super(key: key);

  @override
  _BinairListScreenState createState() => _BinairListScreenState();
}

class _BinairListScreenState extends State<BinairListScreen> {
  Map<DateTime, String> _statusMap = {};
  bool _isLoading = true;
  final List<bool> _expandedPanels = [true, true, true];

  @override
  void initState() {
    super.initState();
    _expandedPanels.fillRange(0, _expandedPanels.length, false);
    _loadStatuses();
  }

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
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('binair')
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  ExpansionPanel _buildCategory(String title, List<DateTime> dates,
      bool isExpanded, int panelIndex) {
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
        child: Text('Geen Binaire Puzzels beschikbaar'),
      )
          : Column(
        children: dates.map((date) {
          final isCompleted = _statusMap[date] == 'completed';
          return Container(
            child: ListTile(
              title: Text(
                'Binaire puzzel van ${date.toLocal().toString().split(' ')[0]}',
                style: TextStyle(
                  color: isCompleted ? Colors.grey : Colors.black,
                  decoration: isCompleted
                      ? TextDecoration.lineThrough
                      : null,
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BinairScreen(
                      userId: FirebaseAuth.instance.currentUser!.uid,
                      date: date.toString(),
                      grid: [], // Haal het grid op in BinairScreen
                    ),
                  ),
                ).then((shouldReload) {
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
        30,
            (index) =>
            _normalizeDate(DateTime.now().subtract(Duration(days: index))))
        .where((date) => !_statusMap.containsKey(date))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kies een Binaire Puzzel'),
      ),
      body: SingleChildScrollView(
        child: ExpansionPanelList(
          expansionCallback: (panelIndex, isExpanded) {
            setState(() {
              _expandedPanels[panelIndex] = !_expandedPanels[panelIndex];
            });
          },
          children: [
            _buildCategory('Mee bezig', inProgressDates, _expandedPanels[0], 0),
            _buildCategory('Nog te doen', notStartedDates, _expandedPanels[1], 1),
            _buildCategory('Afgerond', completedDates, _expandedPanels[2], 2),
          ],
        ),
      ),
    );
  }
}
