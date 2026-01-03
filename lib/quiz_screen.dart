// lib/screens/quiz_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quizmaster/home/result_screen.dart';
import 'package:quizmaster/services/history_service.dart';
import 'package:quizmaster/widget/boosters_bar.dart';
//'package:quizmaster/widgets/boosters_bar.dart';
import '../models/question_model.dart';
import '../models/quiz_history.dart';

class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  final int numberOfQuestions;
  final String category;
  final String difficulty;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.numberOfQuestions,
    required this.category,
    required this.difficulty,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final HistoryService historyService = HistoryService();

  late List<Question> selectedQuestions;
  int currentIndex = 0;
  int score = 0;
  int remainingTime = 15;
  Timer? timer;
  Answer? selectedAnswer;

  // Boosters
  int doublePointsRemaining = 0;
  bool isRevealing = false;

  @override
  void initState() {
    super.initState();

    final shuffled = List<Question>.from(widget.questions)..shuffle();
    selectedQuestions = shuffled.take(widget.numberOfQuestions).toList();

    for (var q in selectedQuestions) {
      q.answers.shuffle();
    }

    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    remainingTime = 15;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          t.cancel();
          nextQuestion();
        }
      });
    });
  }

  void selectAnswer(Answer answer) {
    if (selectedAnswer != null || !mounted) return;

    setState(() {
      selectedAnswer = answer;

      if (answer.isCorrect) {
        int points = 1;
        if (doublePointsRemaining > 0) {
          points = 2;
          doublePointsRemaining--;
        }
        score += points;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) nextQuestion();
    });
  }

  Future<void> nextQuestion() async {
    timer?.cancel();

    if (!mounted) return;

    if (currentIndex + 1 < selectedQuestions.length) {
      setState(() {
        currentIndex++;
        selectedAnswer = null;
        isRevealing = false;
      });
      startTimer();
    } else {
      await _endQuiz();
    }
  }

  Future<void> _endQuiz() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'dailyScore': FieldValue.increment(score),
          'totalScore': FieldValue.increment(score),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Erreur sauvegarde score : $e");
      }
    }

    try {
      await historyService.saveQuiz(
        QuizHistory(
          category: widget.category,
          difficulty: widget.difficulty,
          score: score,
          total: selectedQuestions.length,
          date: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint("Erreur historique : $e");
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(score: score, total: selectedQuestions.length),
        ),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedQuestions.isEmpty) {
      return _errorScreen("Aucune question disponible pour cette catégorie.");
    }

    final question = selectedQuestions[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2F),
        elevation: 0,
        title: Text(
          "Question ${currentIndex + 1}/${selectedQuestions.length}",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$remainingTime s",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: remainingTime <= 5 ? Colors.red : Colors.blueAccent,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _questionImage(question.image),

            const SizedBox(height: 24),

            Text(
              question.text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 32),

            // === LISTE DES RÉPONSES + BOOSTERS À LA FIN ===
            Expanded(
              child: ListView.builder(
                itemCount: question.answers.length + 1, // +1 pour la barre de boosters
                itemBuilder: (context, i) {
                  // Les réponses normales
                  if (i < question.answers.length) {
                    final answer = question.answers[i];
                    Color? cardColor = const Color(0xFF2A2A3B);

                    if (selectedAnswer != null || isRevealing) {
                      if (answer.isCorrect) {
                        cardColor = Colors.green.withOpacity(0.7);
                      } else if (answer == selectedAnswer && !answer.isCorrect) {
                        cardColor = Colors.red.withOpacity(0.7);
                      }
                    }

                    return Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        title: Text(
                          answer.text,
                          style: const TextStyle(color: Colors.white, fontSize: 17),
                          textAlign: TextAlign.center,
                        ),
                        trailing: doublePointsRemaining > 0
                            ? const Icon(Icons.star, color: Colors.purple, size: 20)
                            : null,
                        onTap: selectedAnswer == null ? () => selectAnswer(answer) : null,
                      ),
                    );
                  }

                  // La barre de boosters : dernier élément
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: BoostersBar(
                      onExtraTime: () {
                        setState(() {
                          remainingTime += 5;
                        });
                      },
                      onRevealAnswer: () async {
                        if (isRevealing) return;
                        setState(() {
                          isRevealing = true;
                          selectedAnswer = question.answers.firstWhere((a) => a.isCorrect);
                        });
                        await Future.delayed(const Duration(seconds: 3));
                        if (mounted) {
                          setState(() {
                            selectedAnswer = null;
                            isRevealing = false;
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
          ],
        ),
      ),
    );
  }


  Widget _questionImage(String imagePath) {
    if (imagePath.isEmpty) {
      return const SizedBox(height: 220);
    }

    return Container(
      height: 220,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _imageError(imagePath),
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: frame == null
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : child,
            );
          },
        ),
      ),
    );
  }

  Widget _imageError(String path) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported, color: Colors.grey, size: 60),
          const SizedBox(height: 12),
          const Text("Image non trouvée", style: TextStyle(color: Colors.white70, fontSize: 16)),
          Text(path.split('/').last, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _errorScreen(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 20), textAlign: TextAlign.center),
        ),
      ),
    );
  }
}