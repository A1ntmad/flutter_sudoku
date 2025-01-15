import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../managers/sudoku_manager.dart';

class SudokuScreen extends StatefulWidget {
  final DateTime date; // De datum van deze sudoku
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
  int? _selectedNumber; // Het geselecteerde nummer voor invoer

  @override
  void initState() {
    super.initState();
    print("DEBUG: SudokuScreen geopend voor datum ${widget.date}");
    _initializeManager();
  }

  /// Manager initialiseren (laden puzzle, user checken, etc.)
  Future<void> _initializeManager() async {
    try {
      print("DEBUG: Initialisatie van SudokuManager gestart voor datum: ${widget.date}");
      await _manager.init(widget.date, widget.onProgressUpdate);
      print("DEBUG: SudokuManager succesvol geïnitialiseerd");
      setState(() {
        _screenLoading = false;
      });
    } catch (e) {
      print('ERROR: Fout bij _initializeManager: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout bij laden van de puzzel: $e')),
      );
      Navigator.pop(context);
    }
  }

  /// Voortgang opslaan
  Future<void> _saveProgress() async {
    try {
      await _manager.saveProgress();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voortgang opgeslagen!')),
      );
      print("DEBUG: Voortgang opgeslagen en status bijgewerkt naar 'inProgress'.");
    } catch (e) {
      print("ERROR: Fout bij opslaan van voortgang: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout bij opslaan van voortgang: $e')),
      );
    }
  }

  /// Hint-knop
  Future<void> _onHintPressed() async {
    try {
      await _manager.showHint();
      setState(() {}); // Scherm opnieuw tekenen
    } catch (e) {
      print("ERROR: Fout bij het tonen van een hint: $e");
    }
  }

  /// Oplossing-knop
  Future<void> _onSolutionPressed() async {
    try {
      await _manager.showSolution(); // Zorg dat deze methode in je SudokuManager bestaat
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oplossing getoond!')),
      );
      print("DEBUG: Oplossing getoond.");
    } catch (e) {
      print("ERROR: Fout bij tonen van oplossing: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout bij tonen van oplossing: $e')),
      );
    }
  }

  /// Controle-knop
  void _onCheckPressed() async {
    final correct = _manager.checkPuzzle();

    if (correct) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Gefeliciteerd!'),
          content: const Text(
              'De puzzel is correct opgelost. Wil je deze inleveren?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nee'),
            ),
            TextButton(
              onPressed: () async {
                await _manager.saveFullSudoku(status: "completed");
                Navigator.pop(ctx, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Puzzel is succesvol ingeleverd!')),
                );
                Navigator.pop(context, true);
              },
              child: const Text('Ja, inleveren'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        print("DEBUG: Sudoku voltooid en opgeslagen.");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fouten gevonden! Probeer opnieuw.')),
      );
    }
  }

  /// Selecteer een cel
  void _onCellTap(int row, int col) {
    setState(() {
      _manager.selectCell(row, col);
    });
  }

  /// Wis de inhoud van de geselecteerde cel
  void _onClearPressed() {
    if (_manager.selectedRow != null && _manager.selectedCol != null) {
      _manager.clearSelectedCell();
      setState(() {}); // Scherm opnieuw tekenen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecteer eerst een cel om te wissen.')),
      );
    }
  }

  /// Bouw de nummerkiezer inclusief de wis-knop
  Widget _buildNumberPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0), // Voeg ruimte onder de knoppen toe
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...List.generate(9, (index) {
              final number = index + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () {
                    if (_manager.selectedRow != null && _manager.selectedCol != null) {
                      setState(() {
                        _selectedNumber = number;
                        _manager.setNumber(
                          _manager.selectedRow!,
                          _manager.selectedCol!,
                          number,
                        );
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecteer eerst een cel.')),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: _selectedNumber == number ? Colors.blue : Colors.grey[300],
                    child: Text(
                      number.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        color: _selectedNumber == number ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GestureDetector(
                onTap: _onClearPressed,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.red[300],
                  child: const Icon(
                    Icons.clear,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_screenLoading || _manager.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Sudoku van ${widget.date.toLocal().toString().split(' ')[0]}'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final puzzle = _manager.puzzle;

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
                      await _saveProgress();
                      Navigator.pop(ctx, true); // Sluit dialoog met true
                      Navigator.pop(context, true); // Terug naar lijst met true
                    },
                    child: const Text('Ja, opslaan'),
                  ),
                ],
              );
            },
          );
          return shouldSave ?? false;
        }
        Navigator.pop(context, false); // Geen wijzigingen, ga terug met false
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Score: ${_manager.currentScore}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Alles wissen',
                  onPressed: () {
                    _manager.clearSudoku();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Alle cellen zijn gewist!')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'Hint gebruiken',
                  onPressed: _onHintPressed,
                ),
                IconButton(
                  icon: const Icon(Icons.visibility), // 'Oplossing' knop
                  tooltip: 'Oplossing tonen',
                  onPressed: _onSolutionPressed,
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Controleer puzzel',
                  onPressed: _onCheckPressed,
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
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
                    final cellValue = _manager.progress[cellKey] ?? puzzle[row][col];
                    final isEditable = puzzle[row][col] == null;

                    return GestureDetector(
                      onTap: () {
                        if (isEditable) {
                          setState(() {
                            _manager.selectCell(row, col);
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: _manager.selectedRow == row && _manager.selectedCol == col
                              ? Colors.yellow[200] // Highlight geselecteerde cel
                              : (isEditable ? Colors.lightBlue[100] : Colors.grey[200]),
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
            const SizedBox(height: 16),
            _buildNumberPicker(), // Nummerkiezer en wis-knop
          ],
        ),
      ),
    );
  }
}