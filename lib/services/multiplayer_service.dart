// lib/services/multiplayer_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../models/question_model.dart';
import '../models/room_model.dart';
import 'firestore_service.dart';

class MultiplayerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final FirestoreService _questionService = FirestoreService();

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<MultiplayerRoom> createRoom({
    required String category,
    required String difficulty,
    required int numberOfQuestions,
  }) async {
    final code = _generateRoomCode();

    final userDoc = await _db.collection('users').doc(uid).get();
    final String hostName = userDoc.data()?['username'] ?? 'Joueur';

    final room = MultiplayerRoom(
      id: code,
      code: code,
      hostUid: uid,
      hostName: hostName,
      category: category,
      difficulty: difficulty,
      numberOfQuestions: numberOfQuestions,
      playerUids: [uid],
      playerNames: {uid: hostName},
      scores: {uid: 0},
      currentQuestionIndex: 0,
      isStarted: false,
      isFinished: false,
      createdAt: DateTime.now(),
    );

    await _db.collection('multiplayer_rooms').doc(code).set(room.toFirestore());

    return room;
  }

  Future<MultiplayerRoom?> joinRoom(String code) async {
    code = code.trim().toUpperCase();
    final ref = _db.collection('multiplayer_rooms').doc(code);
    final snap = await ref.get();

    if (!snap.exists) return null;

    final data = snap.data()!;
    final List<dynamic> players = data['playerUids'] ?? [];
    final bool isStarted = data['isStarted'] ?? false;

    if (isStarted || players.length >= 4) return null;

    final userDoc = await _db.collection('users').doc(uid).get();
    final String username = userDoc.data()?['username'] ?? 'Joueur';

    if (!players.contains(uid)) {
      await ref.update({
        'playerUids': FieldValue.arrayUnion([uid]),
        'scores.$uid': 0,
        'playerNames.$uid': username,
      });
    }

    return MultiplayerRoom.fromFirestore(snap);
  }

  Stream<MultiplayerRoom?> roomStream(String code) {
    return _db
        .collection('multiplayer_rooms')
        .doc(code)
        .snapshots()
        .map((snap) => snap.exists ? MultiplayerRoom.fromFirestore(snap) : null);
  }

  // === DÉMARRER LE QUIZ ===
  // === DÉMARRER LE QUIZ (version corrigée et 100% fiable) ===
  Future<void> startQuiz(String roomCode) async {
    final ref = _db.collection('multiplayer_rooms').doc(roomCode);

    try {
      final snap = await ref.get();
      if (!snap.exists) {
        debugPrint("Salle introuvable");
        return;
      }

      final data = snap.data()!;
      final String category = data['category'] as String;
      final String difficulty = data['difficulty'] as String;
      final int numberOfQuestions = data['numberOfQuestions'] as int;

      // Chargement des questions
      final List<Question> allQuestions = await _questionService.getQuestions(
        category: category,
        difficulty: difficulty,
      );

      if (allQuestions.isEmpty) {
        debugPrint("Aucune question trouvée pour $category - $difficulty");
        return;
      }

      allQuestions.shuffle();
      final selectedQuestions = allQuestions.take(numberOfQuestions).toList();

      final formattedQuestions = selectedQuestions.map((q) {
        final answersText = q.answers.map((a) => a.text).toList();
        int correctIndex = q.answers.indexWhere((a) => a.isCorrect);

        // Sécurité : si pas de bonne réponse trouvée, on prend la première
        if (correctIndex == -1) correctIndex = 0;

        return {
          'question': q.text,
          'image': q.image ?? '',
          'answers': answersText,
          'correctAnswer': correctIndex,
        };
      }).toList();
      // Mise à jour atomique
      await ref.update({
        'questions': formattedQuestions,
        'currentQuestionIndex': 0,
        'isStarted': true,
        'isFinished': false,
        'questionStartTime': FieldValue.serverTimestamp(),
        'allAnswered': false,
        'answeredThisQuestion': <String>[],
      });

      debugPrint("Partie démarrée avec succès ! ${formattedQuestions.length} questions chargées.");
    } catch (e) {
      debugPrint("Erreur lors du démarrage de la partie : $e");
    }
  }
  // === SOUMETTRE RÉPONSE ===
  Future<void> submitAnswer(String roomCode, int scoreEarned) async {
    final ref = _db.collection('multiplayer_rooms').doc(roomCode);

    await ref.update({
      'scores.$uid': FieldValue.increment(scoreEarned),
      'answeredThisQuestion': FieldValue.arrayUnion([uid]),
    });

    // Vérifier si tout le monde a répondu
    final snap = await ref.get();
    final data = snap.data()!;
    final List<dynamic> playerUids = data['playerUids'] ?? [];
    final List<dynamic> answered = data['answeredThisQuestion'] ?? [];

    if (answered.length == playerUids.length) {
      await ref.update({'allAnswered': true});

      // Passage automatique après 2 secondes
      Future.delayed(const Duration(seconds: 2), () {
        nextQuestion(roomCode);
      });
    }
  }

  // === QUESTION SUIVANTE ===
  Future<void> nextQuestion(String roomCode) async {
    final ref = _db.collection('multiplayer_rooms').doc(roomCode);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final int current = data['currentQuestionIndex'] ?? 0;
    final List<dynamic> questions = data['questions'] ?? [];
    final int total = questions.length;

    final bool isLast = current + 1 >= total;

    await ref.update({
      'currentQuestionIndex': current + 1,
      'isFinished': isLast,
      'questionStartTime': isLast ? null : FieldValue.serverTimestamp(),
      'allAnswered': false,
      'answeredThisQuestion': <String>[],
    });
  }

  Future<void> leaveRoom(String roomCode) async {
    final ref = _db.collection('multiplayer_rooms').doc(roomCode);

    await ref.update({
      'playerUids': FieldValue.arrayRemove([uid]),
      'scores.$uid': FieldValue.delete(),
      'playerNames.$uid': FieldValue.delete(),
      'answeredThisQuestion': FieldValue.arrayRemove([uid]),
    });

    final snap = await ref.get();
    final players = snap.data()?['playerUids'] ?? [];
    if (players.isEmpty) {
      await ref.delete();
    }
  }
}