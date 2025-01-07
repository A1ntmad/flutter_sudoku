import 'package:flutter/material.dart';

class SudokuCell extends StatelessWidget {
  final int? value; // Huidige waarde van de cel (kan leeg zijn)
  final bool isEditable; // Controle of de cel bewerkbaar is
  final Function(int?) onChanged; // Callback wanneer de waarde verandert

  const SudokuCell({
    Key? key,
    required this.value,
    required this.isEditable,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1.0), // Ruimte tussen cellen
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.0), // Rand
        color: isEditable ? Colors.white : Colors.grey[300], // Grijze kleur voor niet-bewerkbare cellen
      ),
      child: isEditable
          ? TextField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1, // Maximaal 1 karakter
        style: const TextStyle(fontSize: 18),
        decoration: const InputDecoration(
          border: InputBorder.none, // Geen rand binnenin
          counterText: "", // Verberg het tellertje van maxLength
        ),
        onChanged: (text) {
          final input = int.tryParse(text);
          if (input != null && input >= 1 && input <= 9) {
            onChanged(input);
          } else {
            onChanged(null);
          }
        },
      )
          : Center(
        child: Text(
          value?.toString() ?? '',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
