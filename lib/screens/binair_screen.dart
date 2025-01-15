import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Voor Firestore
import '../managers/binair_manager.dart'; // Importeer BinairManager

class BinairScreen extends StatefulWidget {
  final String userId;
  final String date;
  final List<List<int>> grid;

  const BinairScreen({
    Key? key,
    required this.userId,
    required this.date,
    required this.grid,
  }) : super(key: key);

  @override
  _BinairScreenState createState() => _BinairScreenState();
}

class _BinairScreenState extends State<BinairScreen> {
  late List<List<int>> grid;
  final BinairManager manager = BinairManager();

  @override
  void initState() {
    super.initState();

    // Initialiseer grid
    grid = widget.grid.isEmpty ? manager.generateEmptyGrid() : widget.grid;
  }

  // Wijzig een cel in het grid
  void toggleCell(int row, int col) {
    setState(() {
      if (grid[row][col] == -1) {
        grid[row][col] = 0;
      } else if (grid[row][col] == 0) {
        grid[row][col] = 1;
      } else {
        grid[row][col] = -1;
      }

      // Controleer of het grid geldig blijft
      if (!manager.isGridValid(grid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ongeldige zet! Controleer het grid.')),
        );
      }
    });
  }

  // Opslaan van het grid
  Future<void> saveGrid() async {
    if (!manager.isGridValid(grid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kan niet opslaan. Grid is ongeldig.')),
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore
        .collection('users')
        .doc(widget.userId)
        .collection('binair')
        .doc(widget.date);

    await userRef.set({
      'grid': grid,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Puzzel opgeslagen!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Binaire Puzzel (${widget.date})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveGrid,
          ),
        ],
      ),
      body: Center(
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: grid.length,
            childAspectRatio: 1,
          ),
          itemCount: grid.length * grid.length,
          itemBuilder: (context, index) {
            final row = index ~/ grid.length;
            final col = index % grid.length;
            final value = grid[row][col];

            return GestureDetector(
              onTap: () => toggleCell(row, col),
              child: Container(
                margin: const EdgeInsets.all(2.0),
                color: Colors.blueGrey[100],
                child: Center(
                  child: Text(
                    value == -1 ? '' : value.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: value == -1
                          ? Colors.grey
                          : value == 0
                          ? Colors.blue
                          : Colors.red,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
