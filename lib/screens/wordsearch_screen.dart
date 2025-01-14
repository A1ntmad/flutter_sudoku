import 'package:flutter/material.dart';
import '../managers/wordsearch_manager.dart';

class WordsearchScreen extends StatefulWidget {
  final String puzzleId;

  const WordsearchScreen({Key? key, required this.puzzleId}) : super(key: key);

  @override
  State<WordsearchScreen> createState() => _WordsearchScreenState();
}

class _WordsearchScreenState extends State<WordsearchScreen> {
  final WordSearchManager _manager = WordSearchManager(); // Initialiseer WordsearchManager
  bool _screenLoading = true; // Laadstatus van het scherm
  late List<List<String>> grid; // Woordzoeker-grid
  late List<Map<String, dynamic>> words; // Lijst van woorden
  Set<Map<String, int>> selectedCells = {};
  Map<String, int>? startCell;
  Map<String, int>? endCell;

  @override
  void initState() {
    super.initState();
    _initializeManager(); // Manager initialiseren bij schermopbouw
  }

  /// Initialiseer de WordsearchManager met de puzzleId
  Future<void> _initializeManager() async {
    try {
      print('DEBUG: Initialisatie van WordsearchManager gestart.');
      await _manager.init(DateTime.now(), widget.puzzleId); // Gebruik widget.puzzleId
      setState(() {
        grid = _manager.grid; // Woordzoeker-grid ophalen
        words = _manager.words; // Woorden ophalen
        _screenLoading = false; // Laadstatus bijwerken
      });
      print('DEBUG: WordsearchManager succesvol geïnitialiseerd.');
    } catch (e) {
      print('ERROR: Fout bij initialiseren van manager: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fout bij laden van puzzel.')),
      );
      Navigator.pop(context);
    }
  }

  /// Opslaan en terugnavigeren
  void _saveAndExit() async {
    final success = await _manager.saveProgress(widget.puzzleId);
    if (success) {
      Navigator.pop(context, true); // Geeft aan dat er een wijziging is opgeslagen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opslaan mislukt.')),
      );
    }
  }

  void _checkWord() async {
    List<String> selectedPattern = selectedCells
        .map((cell) => "${cell['row']}-${cell['col']}")
        .toList();

    bool isValidWord = await _manager.validateWord(selectedPattern);
    if (isValidWord) {
      setState(() {
        final foundWord = _manager.foundWords.last;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gevonden: $foundWord')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geen match gevonden.')),
      );
    }

    setState(() {
      if (!_manager.isCompleted()) {
        selectedCells.clear();
        startCell = null;
        endCell = null;
      }
    });
  }



  Future<void> _useHint() async {
    if (!_manager.canUseHint()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geen hints meer beschikbaar!')),
      );
      return;
    }

    final hint = await _manager.generateHint();
    if (hint != null) {
      setState(() {
        selectedCells.add({'row': hint['row'], 'col': hint['col']});
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            'Hint gebruikt! Nieuwe score: ${_manager.currentScore}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geen hints meer beschikbaar!')),
      );
    }
  }

  void _onCheckPressed() async {
    if (_manager.isCompleted()) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Gefeliciteerd!'),
          content: const Text(
              'Je hebt alle woorden gevonden. Wil je de puzzel inleveren?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Nee'),
            ),
            TextButton(
              onPressed: () async {
                // Sla de puzzel op met status 'completed'
                await _manager.saveProgress(widget.puzzleId, status: 'completed');
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
        print("DEBUG: Puzzel voltooid en status bijgewerkt naar 'completed'.");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nog niet alle woorden gevonden!')),
      );
    }
  }


  void _onGridItemTapped(int row, int col) {
    setState(() {
      if (startCell == null) {
        startCell = {'row': row, 'col': col};
        selectedCells.clear();
        selectedCells.add({'row': row, 'col': col});
      } else {
        endCell = {'row': row, 'col': col};

        final cellsBetween = _getCellsBetween(startCell!, endCell!);
        selectedCells.clear();
        selectedCells.addAll(
          cellsBetween.map((cell) {
            final parts = cell.split('-');
            return {'row': int.parse(parts[0]), 'col': int.parse(parts[1])};
          }),
        );

        _checkWord();
      }
    });
  }

  List<String> _getCellsBetween(Map<String, int> start, Map<String, int> end) {
    List<String> cells = [];

    int rowStep = (end['row']! - start['row']!).sign;
    int colStep = (end['col']! - start['col']!).sign;

    if (rowStep == 0 && colStep == 0) {
      print('ERROR: Start- en eindcel zijn hetzelfde.');
      return cells;
    }

    int currentRow = start['row']!;
    int currentCol = start['col']!;

    while (currentRow != end['row']! + rowStep ||
        currentCol != end['col']! + colStep) {
      if (currentRow >= 0 && currentRow < grid.length && currentCol >= 0 &&
          currentCol < grid[currentRow].length) {
        cells.add('$currentRow-$currentCol');
      } else {
        print('ERROR: Cel buiten grid: row=$currentRow, col=$currentCol');
        break;
      }

      currentRow += rowStep;
      currentCol += colStep;
    }

    return cells;
  }

  @override
  Widget build(BuildContext context) {
    if (_screenLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Woordzoeker')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    final availableHeight = screenHeight - appBarHeight - 150;

    final gridSize = screenWidth < availableHeight
        ? screenWidth
        : availableHeight;
    final cellSize = gridSize / grid.length;

    return WillPopScope(
      onWillPop: () async {
        if (_manager.hasChanges) {
          final shouldSave = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Wijzigingen opslaan?'),
              content: const Text('Je hebt wijzigingen gemaakt. Wil je deze opslaan?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false), // Nee
                  child: const Text('Nee'),
                ),
                TextButton(
                  onPressed: () async {
                    await _manager.saveProgress(widget.puzzleId);
                    Navigator.pop(ctx, true); // Ja, opslaan
                    Navigator.pop(context, true); // Stuur `true` terug
                  },
                  child: const Text('Ja, opslaan'),
                ),
              ],
            ),
          );
          return shouldSave ?? false;
        }
        return true;
      },

      child: Scaffold(
        appBar: AppBar(
          title: const Text('Woordzoeker'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  'Score: ${_manager.currentScore}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Hint gebruiken',
              onPressed: _useHint,
            ),
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Controleer puzzel',
              onPressed: _onCheckPressed,
            )
          ],
        ),
        body: Column(
          children: [
            Center(
              child: SizedBox(
                width: gridSize,
                height: gridSize,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: grid.length,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: grid.length * grid[0].length,
                  itemBuilder: (context, index) {
                    final row = index ~/ grid.length;
                    final col = index % grid.length;
                    return _buildGridItem(row, col, cellSize);
                  },
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: _buildWordList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(int row, int col, double cellSize) {
    final letter = grid[row][col];
    final isSelected = selectedCells.any((cell) =>
    cell['row'] == row && cell['col'] == col);

    Color? cellColor;
    for (final word in _manager.foundWords) {
      final wordData = _manager.words.firstWhere((w) => w['word'] == word);
      if (wordData['coordinates'].contains('$row-$col')) {
        cellColor = _manager.wordColors[word];
        break;
      }
    }

    return GestureDetector(
      onTap: () => _onGridItemTapped(row, col),
      child: Container(
        width: cellSize,
        height: cellSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          color: isSelected
              ? Colors.blue.withOpacity(0.6)
              : (cellColor?.withOpacity(0.4) ?? Colors.white),
        ),
        child: Text(
          letter,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildWordList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: words.map((wordData) {
        final word = wordData['word'];
        final isFound = _manager.foundWords.contains(word);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isFound
                ? _manager.wordColors[word]?.withOpacity(0.2)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFound
                  ? _manager.wordColors[word] ?? Colors.green
                  : Colors.grey,
              width: 1,
            ),
          ),
          child: Text(
            word,
            style: TextStyle(
              decoration: isFound ? TextDecoration.lineThrough : TextDecoration.none,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isFound
                  ? _manager.wordColors[word] ?? Colors.green
                  : Colors.black,
            ),
          ),
        );
      }).toList(),
    );
  }
}
