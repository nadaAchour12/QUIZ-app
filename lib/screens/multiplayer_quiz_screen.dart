// lib/screens/multiplayer_quiz_screen.dart
import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/multiplayer_service.dart';
import '../services/json_loader.dart';
import '../widget/boosters_bar.dart';
import 'multiplayer_result_screen.dart';
import '../models/question_model.dart';

class MultiplayerQuizScreen extends StatefulWidget {
  final String roomCode;

  const MultiplayerQuizScreen({super.key, required this.roomCode});

  @override
  State<MultiplayerQuizScreen> createState() => _MultiplayerQuizScreenState();
}

class _MultiplayerQuizScreenState extends State<MultiplayerQuizScreen> {
  final MultiplayerService _service = MultiplayerService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  List<Question> questions = [];
  int currentIndex = 0;
  String? selectedAnswerText;

  // Boosters
  int doublePointsRemaining = 0;
  bool localRevealActive = false;

  // Sync
  int timeLeft = 15;
  String correctAnswerText = '';
  bool showAnswers = false;
  bool canAnswer = true;
  List<String> answeredThisQuestion = [];
  bool isStarted = false;
  bool isFinished = false;
  int totalQuestions = 10;

  bool _isNavigating = false;
  Timer? _nextQuestionTimer;
  bool _hasScheduledNextQuestion = false;

  @override
  void initState() {
    super.initState();
    _listenToRoom();
  }

  @override
  void dispose() {
    _nextQuestionTimer?.cancel();
    super.dispose();
  }

  void _listenToRoom() {
    FirebaseFirestore.instance
        .collection('multiplayer_rooms')
        .doc(widget.roomCode)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists || !mounted || _isNavigating) return;

      final data = snapshot.data()!;
      final wasStarted = isStarted;
      final oldQuestionIndex = currentIndex;
      final wasShowingAnswers = showAnswers;

      setState(() {
        isStarted = data['isStarted'] ?? false;
        isFinished = data['isFinished'] ?? false;
        currentIndex = data['currentQuestionIndex'] ?? 0;
        answeredThisQuestion = List<String>.from(data['answeredThisQuestion'] ?? []);
        totalQuestions = data['questionCount'] as int? ?? 10;

        timeLeft = (data['questionStartTime'] as Timestamp?)?.toDate() != null
            ? (15 - DateTime.now().difference((data['questionStartTime'] as Timestamp).toDate()).inSeconds).clamp(0, 15)
            : 15;

        showAnswers = (data['allAnswered'] ?? false) || timeLeft <= 0;
        canAnswer = currentUser != null &&
            !answeredThisQuestion.contains(currentUser!.uid) &&
            timeLeft > 0 &&
            !showAnswers &&
            isStarted &&
            !isFinished;
      });

      // Réinitialiser la sélection lors du changement de question
      if (currentIndex != oldQuestionIndex) {
        setState(() {
          selectedAnswerText = null;
          localRevealActive = false;
          _hasScheduledNextQuestion = false;
        });
        _nextQuestionTimer?.cancel();
      }

      // Chargement des questions si le quiz vient de commencer
      if (isStarted && !wasStarted && questions.isEmpty) {
        final int? seed = data['questionSeed'] as int?;
        await _loadQuestionsFromJson(seed: seed);
      }

      // Soumet la réponse vide si le temps est écoulé
      if (timeLeft <= 0 && canAnswer) {
        _submitAnswer('');
      }

      // Programmer le passage à la question suivante (uniquement par l'hôte)
      if (showAnswers && !wasShowingAnswers && !isFinished && !_hasScheduledNextQuestion) {
        _hasScheduledNextQuestion = true;
        final isHost = data['hostUid'] == currentUser?.uid;

        if (isHost) {
          _nextQuestionTimer?.cancel();
          _nextQuestionTimer = Timer(const Duration(seconds: 3), () {
            if (mounted && !isFinished) {
              _service.nextQuestion(widget.roomCode);
            }
          });
        }
      }

      // Fin de partie : navigation unique et sécurisée
      if (isFinished && mounted && !_isNavigating) {
        _isNavigating = true;
        _nextQuestionTimer?.cancel();

        // Petit délai pour laisser voir la dernière réponse
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MultiplayerResultScreen(
                  roomCode: widget.roomCode,
                  playerScores: Map<String, int>.from(data['scores'] ?? {}),
                  playerNames: Map<String, String>.from(data['playerNames'] ?? {}),
                  currentUserUid: currentUser?.uid ?? '',
                ),
              ),
            );
          }
        });
      }
    });
  }

  Future<void> _loadQuestionsFromJson({int? seed}) async {
    final roomSnap = await FirebaseFirestore.instance
        .collection('multiplayer_rooms')
        .doc(widget.roomCode)
        .get();
    final category = roomSnap.data()?['category'] as String? ?? 'general';

    final allQuestions = await loadQuestionsFromJson(category: category);
    if (allQuestions.isEmpty) return;

    final random = seed != null ? Random(seed) : Random();
    allQuestions.shuffle(random);

    setState(() {
      questions = allQuestions.take(totalQuestions).toList();
    });
  }

  Future<void> _submitAnswer(String answerText) async {
    if (currentUser == null || !canAnswer) return;

    final question = questions[currentIndex];
    final isCorrect = question.answers.any((a) => a.text == answerText && a.isCorrect);
    int scoreEarned = isCorrect ? (timeLeft * 100 + 100) : 0;

    if (doublePointsRemaining > 0 && isCorrect) {
      scoreEarned *= 2;
      setState(() => doublePointsRemaining--);
    }

    await _service.submitAnswer(widget.roomCode, scoreEarned);

    setState(() {
      selectedAnswerText = answerText;
      canAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isStarted) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(
          child: Text(
            "En attente du démarrage...",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ),
      );
    }

    // Protection contre fin de partie ou questions vides
    if (currentIndex >= totalQuestions || questions.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyan),
        ),
      );
    }

    final question = questions[currentIndex];
    final answers = question.answers.map((a) => a.text).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: Text(
          "Question ${currentIndex + 1}/$totalQuestions",
          style: const TextStyle(color: Colors.white),
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
                "$timeLeft s",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: timeLeft <= 5 ? Colors.red : Colors.blueAccent,
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: answers.length + 1,
                itemBuilder: (context, i) {
                  if (i < answers.length) {
                    final answer = answers[i];
                    final isCorrect = question.answers[i].isCorrect;
                    final isSelected = selectedAnswerText == answer;

                    Color? cardColor = const Color(0xFF2A2A3B);
                    if (showAnswers || localRevealActive) {
                      cardColor = isCorrect
                          ? Colors.green.withOpacity(0.7)
                          : (isSelected ? Colors.red.withOpacity(0.7) : cardColor);
                    }

                    return Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        title: Text(
                          answer,
                          style: const TextStyle(color: Colors.white, fontSize: 17),
                          textAlign: TextAlign.center,
                        ),
                        trailing: doublePointsRemaining > 0
                            ? const Icon(Icons.star, color: Colors.purple, size: 20)
                            : null,
                        onTap: canAnswer ? () => _submitAnswer(answer) : null,
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: BoostersBar(
                      onExtraTime: () => setState(() => timeLeft += 5),
                      onRevealAnswer: () async {
                        if (localRevealActive || !canAnswer) return;
                        setState(() => localRevealActive = true);
                        await Future.delayed(const Duration(seconds: 3));
                        if (mounted) setState(() => localRevealActive = false);
                      },
                      onDoublePoints: () {
                        setState(() => doublePointsRemaining = 3);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Double points x3 activé ! ⭐"),
                            backgroundColor: Colors.purple,
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
                child: Text(
                  "Passage à la suivante...",
                  style: TextStyle(color: Colors.cyan, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _questionImage(String imagePath) {
    if (imagePath.isEmpty) return const SizedBox(height: 220);

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.image_not_supported, color: Colors.grey, size: 60),
          ),
        ),
      ),
    );
  }
}