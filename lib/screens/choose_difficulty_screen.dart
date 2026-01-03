import 'package:flutter/material.dart';
import '../services/multiplayer_service.dart';
import 'waiting_room_screen.dart';

class ChooseDifficultyScreen extends StatefulWidget {
  final String category;
  const ChooseDifficultyScreen({super.key, required this.category});

  @override
  State<ChooseDifficultyScreen> createState() =>
      _ChooseDifficultyScreenState();
}

class _ChooseDifficultyScreenState extends State<ChooseDifficultyScreen> {
  String difficulty = 'facile';
  int questions = 10;
  bool loading = false;

  final MultiplayerService _service = MultiplayerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Choisir la difficulté",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            DropdownButton<String>(
              value: difficulty,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'facile', child: Text('Facile')),
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'difficile', child: Text('Difficile')),
              ],
              onChanged: (value) {
                setState(() => difficulty = value!);
              },
            ),

            const SizedBox(height: 20),

            const Text("Nombre de questions"),
            Slider(
              min: 5,
              max: 20,
              divisions: 3,
              value: questions.toDouble(),
              label: questions.toString(),
              onChanged: (v) {
                setState(() => questions = v.toInt());
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                  setState(() => loading = true);

                  final room = await _service.createRoom(
                    category: widget.category,
                    difficulty: difficulty,
                    numberOfQuestions: questions,
                  );

                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WaitingRoomScreen(roomCode: room.code),
                      ),
                    );
                  }
                },
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Créer la salle"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
