// lib/screens/multiplayer_quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/multiplayer_service.dart';
import '../widget/boosters_bar.dart';
import 'multiplayer_result_screen.dart';

class MultiplayerQuizScreen extends StatefulWidget {
  final String roomCode;

  const MultiplayerQuizScreen({super.key, required this.roomCode});

  @override
  State<MultiplayerQuizScreen> createState() => _MultiplayerQuizScreenState();
}

class _MultiplayerQuizScreenState extends State<MultiplayerQuizScreen> {
  final MultiplayerService _service = MultiplayerService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String? selectedAnswerText;

  // Boosters
  int doublePointsRemaining = 0;
  bool localRevealActive = false; // ← Révélation locale, sans toucher à showAnswers

  Future<void> _submitAnswer(String answerText) async {
    if (currentUser == null || !canAnswer) return;

    final bool isCorrect = answerText == correctAnswerText;
    int scoreEarned = isCorrect ? (timeLeft * 100 + 100) : 0;

    if (doublePointsRemaining > 0 && isCorrect) {
      scoreEarned *= 2;
      doublePointsRemaining--;
    }

    await _service.submitAnswer(widget.roomCode, scoreEarned);

    setState(() {
      selectedAnswerText = answerText;
    });
  }

  // Variables synchronisées
  int timeLeft = 15;
  String correctAnswerText = '';
  bool showAnswers = false;
  bool canAnswer = true;
  List<String> answeredThisQuestion = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2F),
        elevation: 0,
        title: const Text("Quiz Multijoueur", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(
                "$timeLeft s",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: timeLeft <= 3 ? Colors.red : Colors.blueAccent),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('multiplayer_rooms').doc(widget.roomCode).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyan));
          }

          final data = snapshot.data!.data()!;
          final bool isFinished = data['isFinished'] ?? false;
          final int currentIndex = data['currentQuestionIndex'] ?? 0;
          final List<dynamic> questions = data['questions'] ?? [];

          // Fin de partie
          if (isFinished) {
            final playerScores = Map<String, int>.from(data['scores'] ?? {});
            final playerNames = Map<String, String>.from(data['playerNames'] ?? {});

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultiplayerResultScreen(
                      roomCode: widget.roomCode,
                      playerScores: playerScores,
                      playerNames: playerNames,
                      currentUserUid: currentUser?.uid ?? '',
                    ),
                  ),
                );
              }
            });
            return const Center(child: Text("Partie terminée !", style: TextStyle(color: Colors.cyan, fontSize: 24)));
          }

          if (questions.isEmpty || currentIndex >= questions.length) {
            return const Center(child: Text("En attente de la question...", style: TextStyle(color: Colors.white70, fontSize: 18)));
          }

          final q = questions[currentIndex];
          final String questionText = q['question'] ?? '';
          final String imagePath = q['image'] ?? '';
          final List<String> answers = List<String>.from(q['answers'] ?? []);
          final int? correctIndexRaw = q['correctAnswer'] as int?;
          final int correctIndex = (correctIndexRaw != null && correctIndexRaw >= 0 && correctIndexRaw < answers.length)
              ? correctIndexRaw
              : 0;

          correctAnswerText = answers.isNotEmpty ? answers[correctIndex] : '';

          // Timer synchronisé
          final Timestamp? startTime = data['questionStartTime'];
          if (startTime != null) {
            final elapsed = DateTime.now().difference(startTime.toDate()).inSeconds;
            timeLeft = (15 - elapsed).clamp(0, 15);
          } else {
            timeLeft = 15;
          }

          // État synchronisé depuis Firestore (NE PAS MODIFIER LOCALEMENT)
          showAnswers = (data['allAnswered'] ?? false) || timeLeft <= 0;
          answeredThisQuestion = List<String>.from(data['answeredThisQuestion'] ?? []);

          canAnswer = currentUser != null &&
              !answeredThisQuestion.contains(currentUser!.uid) &&
              timeLeft > 0 &&
              !showAnswers;

          // Timeout auto
          if (timeLeft <= 0 && canAnswer) {
            _submitAnswer('');
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _questionImage(imagePath),
                const SizedBox(height: 24),
                Text(questionText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 32),

                // RÉPONSES + BOOSTERS EN BAS
                Expanded(
                  child: ListView.builder(
                    itemCount: answers.length + 1,
                    itemBuilder: (context, i) {
                      if (i < answers.length) {
                        final answer = answers[i];
                        final bool isCorrect = answers.isNotEmpty && i == correctIndex;
                        final bool isSelected = selectedAnswerText == answer;

                        Color? cardColor = const Color(0xFF2A2A3B);
                        // Révélation locale OU révélation globale
                        if (showAnswers || localRevealActive) {
                          if (isCorrect) cardColor = Colors.green.withOpacity(0.7);
                          if (isSelected && !isCorrect) cardColor = Colors.red.withOpacity(0.7);
                        }

                        return Card(
                          color: cardColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            title: Text(answer, style: const TextStyle(color: Colors.white, fontSize: 17), textAlign: TextAlign.center),
                            trailing: doublePointsRemaining > 0 ? const Icon(Icons.star, color: Colors.purple, size: 20) : null,
                            onTap: canAnswer ? () => _submitAnswer(answer) : null,
                          ),
                        );
                      }

                      // Barre de boosters
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: BoostersBar(
                          onExtraTime: () {
                            setState(() {
                              timeLeft += 5;
                            });
                          },
                          onRevealAnswer: () async {
                            if (localRevealActive || !canAnswer) return;

                            setState(() {
                              localRevealActive = true;
                            });

                            await Future.delayed(const Duration(seconds: 3));

                            if (mounted) {
                              setState(() {
                                localRevealActive = false;
                              });
                            }
                          },
                          onDoublePoints: () {
                            setState(() {
                              doublePointsRemaining = 3;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Double points activé sur les 3 prochaines questions ! ⭐"),
                                backgroundColor: Colors.purple,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                if (showAnswers)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text("Passage à la suivante...", style: TextStyle(color: Colors.cyan, fontSize: 16)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _questionImage(String imagePath) {
    if (imagePath.isEmpty) return const SizedBox(height: 220);

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF2A2A3B), borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, color: Colors.grey, size: 60),
                SizedBox(height: 8),
                Text("Image manquante", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: frame == null ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent)) : child,
            );
          },
        ),
      ),
    );
  }
}