import 'package:flutter/material.dart';

class QuizSettingsDialog extends StatefulWidget {
  final void Function(String difficulty, int count) onStart;

  const QuizSettingsDialog({
    super.key,
    required this.onStart,
  });

  @override
  State<QuizSettingsDialog> createState() => _QuizSettingsDialogState();
}

class _QuizSettingsDialogState extends State<QuizSettingsDialog> {
  String selectedDifficulty = "facile";
  int selectedCount = 10;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A3B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Paramètres du quiz",
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Difficulté", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),

          _difficultyChoice("facile", Colors.green),
          _difficultyChoice("moyenne", Colors.orange),
          _difficultyChoice("difficile", Colors.red),

          const SizedBox(height: 20),
          const Text("Nombre de questions", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),

          DropdownButton<int>(
            value: selectedCount,
            dropdownColor: const Color(0xFF2A2A3B),
            items: [5, 10, 15, 20]
                .map(
                  (n) => DropdownMenuItem(
                value: n,
                child: Text(
                  "$n questions",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedCount = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler", style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onStart(selectedDifficulty, selectedCount);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
          child: const Text("Commencer"),
        ),
      ],
    );
  }

  Widget _difficultyChoice(String value, Color color) {
    return RadioListTile<String>(
      value: value,
      groupValue: selectedDifficulty,
      activeColor: color,
      title: Text(
        value.toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
      onChanged: (v) => setState(() => selectedDifficulty = v!),
    );
  }
}
