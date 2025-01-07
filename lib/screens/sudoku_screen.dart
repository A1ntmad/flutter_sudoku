import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../managers/sudoku_manager.dart';

class SudokuScreen extends StatefulWidget {
  final DateTime date;                // De datum van deze sudoku
  final Function(double) onProgressUpdate;

  const SudokuScreen({
    Key? key,
    required this.date,
    required this.onProgressUpdate,
  }) : super(key: key);

  @override
  _SudokuScreenState createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  final SudokuManager _manager = SudokuManager();
  bool _screenLoading = true; // Zolang dit true is, tonen we een laad-indicator

  @override
  void initState() {
    super.initState();
    _initializeManager();
  }

  /// Stap 1: Manager initialiseren (laden puzzle, user checken, etc.)
  Future<void> _initializeManager() async {
    try {
      // init(...) laadt of genereert de puzzle. Kan eventjes duren.
      await _manager.init(widget.date, widget.onProgressUpdate);
      setState(() {
        _screenLoading = false;
      });
    } catch (e) {
      // Als er iets misgaat (bv. geen user ingelogd), ga terug of toon fout
      print('Fout bij _initializeManager: $e');
      Navigator.pop(context);
    }
  }

  /// Hint-knop
  Future<void> _onHintPressed() async {
    await _manager.showHint();
    // manager verwerkt een hint (bvb. vul eerste lege cel in en verlaag score).
    setState(() {});
  }

  /// Oplossing-knop
  Future<void> _onSolutionPressed() async {
    await _manager.showSolution();
    // manager vult de hele puzzle in (score naar 0).
    setState(() {});
  }

  /// Controle-knop
  void _onCheckPressed() {
    final correct = _manager.checkPuzzle();
    // Toon melding via Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correct ? 'Correct opgelost!' : 'Fouten gevonden!'),
      ),
    );
  }

  /// Klik op een cel: dialoog om cijfer te kiezen
  void _onCellTap(int row, int col) async {
    // Check of deze cel bewerkbaar is (in manager: puzzle[row][col] == null)
    if (_manager.puzzle[row][col] != null) {
      // Niet bewerkbaar (was al ingevuld in puzzle)
      return;
    }

    // Dialoog om 1-9 te kiezen
    final chosenNum = await _showNumberPicker();
    if (chosenNum != null) {
      setState(() {
        _manager.setNumber(row, col, chosenNum);
      });
    }
  }

  /// Dialoog: kies cijfer 1..9
  Future<int?> _showNumberPicker() async {
    return showDialog<int>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Kies een nummer'),
          content: SizedBox(
            width: 200,
            height: 200,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 60,  // hoogte van elke knop
              ),
              itemBuilder: (context, index) {
                final number = index + 1; // 1..9
                return ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx, number);
                  },
                  child: Text(number.toString()),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Zolang manager of screenLoading = true is, tonen we laad-UI
    if (_screenLoading || _manager.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Sudoku van ${widget.date.toLocal().toString().split(' ')[0]}'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Haal de puzzle-lijst (9x9) op uit de manager
    final puzzle = _manager.puzzle;

    // WillPopScope: als we terugnavigeren, checken we of er wijzigingen zijn
    return WillPopScope(
      onWillPop: () async {
        if (_manager.hasChanges) {
          final shouldSave = await showDialog<bool>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Wijzigingen opslaan?'),
                content: const Text('Je hebt wijzigingen gemaakt. Wil je deze opslaan?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Nee'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _manager.saveProgress();
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('Ja, opslaan'),
                  ),
                ],
              );
            },
          );
          // Als user “Ja” klikt => manager.saveProgress() => Navigator.pop(..., true)
          return shouldSave ?? false;
          // Als null (dialoog weggeklikt) of false => blijf
        }
        // geen changes => direct weg
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sudoku van ${widget.date.toLocal().toString().split(' ')[0]}'),
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),
            // Toon de score in UI
            Text(
              'Sudoku Scoring: ${_manager.currentScore}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Ons 9x9-raster
            Expanded(
              child: AspectRatio(
                aspectRatio: 1, // Vierkant
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                  ),
                  itemCount: 81,
                  itemBuilder: (context, index) {
                    final row = index ~/ 9;
                    final col = index % 9;
                    final cellKey = '$row$col';

                    // Is de user something in progress of puzzle
                    final cellValue = _manager.progress[cellKey] ?? puzzle[row][col];
                    final isEditable = puzzle[row][col] == null;

                    return GestureDetector(
                      onTap: () => isEditable ? _onCellTap(row, col) : null,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: isEditable ? Colors.lightBlue[100] : Colors.grey[200],
                        ),
                        child: Center(
                          child: Text(
                            cellValue?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 18,
                              color: isEditable ? Colors.blue : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Drie knoppen: Hint, Oplossing, Controle
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _onHintPressed,
                  child: const Text('Hint'),
                ),
                ElevatedButton(
                  onPressed: _onSolutionPressed,
                  child: const Text('Oplossing'),
                ),
                ElevatedButton(
                  onPressed: _onCheckPressed,
                  child: const Text('Controle'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
