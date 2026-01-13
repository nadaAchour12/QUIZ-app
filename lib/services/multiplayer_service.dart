import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/room_model.dart';
import '../services/json_loader.dart';

class MultiplayerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  // 🔹 Créer une salle
  Future<MultiplayerRoom> createRoom({
    required String category,
    required String difficulty,
    required int numberOfQuestions,
  }) async {
    final code = _generateRoomCode();
    final userDoc = await _db.collection('users').doc(uid).get();
    final hostName = userDoc.data()?['username'] ?? 'Joueur';

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

  // 🔹 Rejoindre une salle
  Future<MultiplayerRoom?> joinRoom(String code) async {
    code = code.trim().toUpperCase();
    final ref = _db.collection('multiplayer_rooms').doc(code);
    final snap = await ref.get();
    if (!snap.exists) return null;

    final data = snap.data()!;
    final players = data['playerUids'] as List<dynamic>? ?? [];
    if (data['isStarted'] == true || players.length >= 4) return null;

    final userDoc = await _db.collection('users').doc(uid).get();
    final username = userDoc.data()?['username'] ?? 'Joueur';

    if (!players.contains(uid)) {
      await ref.update({
        'playerUids': FieldValue.arrayUnion([uid]),
        'scores.$uid': 0,
        'playerNames.$uid': username,
      });
    }

    return MultiplayerRoom.fromFirestore(snap);
  }

  // 🔹 Stream des changements de la salle
  Stream<MultiplayerRoom?> roomStream(String code) {
    return _db.collection('multiplayer_rooms').doc(code).snapshots().map(
          (snap) => snap.exists ? MultiplayerRoom.fromFirestore(snap) : null,
    );
  }

  // 🔹 Démarrer le quiz
  Future<void> startQuiz(String roomCode) async {
    final ref = _db.collection('multiplayer_rooms').doc(roomCode);
    final snap = await ref.get();

    if (!snap.exists) return;

    final data = snap.data()!;
    final category = data['category'] as String? ?? 'general';
    final difficulty = data['difficulty'] as String? ?? 'mixte';
    final numberOfQuestions = data['numberOfQuestions'] as int? ?? 10;

    final allQuestions = await loadQuestionsFromJson(category: category);
    final filtered = allQuestions.where((q) => q.difficulty.toLowerCase() == difficulty.toLowerCase()).toList();

    if (filtered.isEmpty) return;

    final seed = Random().nextInt(999999);
    final random = Random(seed);
    filtered.shuffle(random);

    final selected = filtered.take(numberOfQuestions).toList();

    await ref.update({
      'currentQuestionIndex': 0,
      'isStarted': true,
      'isFinished': false,
      'questionStartTime': FieldValue.serverTimestamp(),
      'allAnswered': false,
      'answeredThisQuestion': <String>[],
      'questionCount': numberOfQuestions,
      'questionSeed': seed,
    });
  }

  // 🔹 Soumettre une réponse
  Future<void> submitAnswer(String roomCode, int scoreEarned) async {
    final ref = _db.collection('multiplayer_rooms').doc(roomCode);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final players = data['playerUids'] as List<dynamic>? ?? [];
      final answered = List<String>.from(data['answeredThisQuestion'] ?? []);
      final scores = Map<String, dynamic>.from(data['scores'] ?? {});

      // Ajouter le joueur à la liste des répondants s'il n'y est pas déjà
      if (!answered.contains(uid)) {
        answered.add(uid);
      }

      // Mettre à jour le score
      scores[uid] = (scores[uid] ?? 0) + scoreEarned;

      // Vérifier si tous les joueurs ont répondu
      final allAnswered = answered.length >= players.length;

      transaction.update(ref, {
        'scores': scores,
        'answeredThisQuestion': answered,
        'allAnswered': allAnswered,
      });
    });
  }

  // 🔹 Passer à la question suivante
  Future<void> nextQuestion(String roomCode) async {
    final ref = _db.collection('multiplayer_rooms').doc(roomCode);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final current = data['currentQuestionIndex'] as int? ?? 0;
      final total = data['questionCount'] as int? ?? 10;

      final nextIndex = current + 1;
      final isLast = nextIndex >= total;

      if (isLast) {
        // Fin du quiz
        transaction.update(ref, {
          'isFinished': true,
          'currentQuestionIndex': nextIndex,
        });
      } else {
        // Passer à la question suivante
        transaction.update(ref, {
          'currentQuestionIndex': nextIndex,
          'questionStartTime': FieldValue.serverTimestamp(),
          'allAnswered': false,
          'answeredThisQuestion': <String>[],
        });
      }
    });
  }

  // 🔹 Quitter la salle
  Future<void> leaveRoom(String roomCode) async {
    final ref = _db.collection('multiplayer_rooms').doc(roomCode);

    await ref.update({
      'playerUids': FieldValue.arrayRemove([uid]),
      'scores.$uid': FieldValue.delete(),
      'playerNames.$uid': FieldValue.delete(),
      'answeredThisQuestion': FieldValue.arrayRemove([uid]),
    });

    final snap = await ref.get();
    if ((snap.data()?['playerUids'] as List<dynamic>?)?.isEmpty ?? true) {
      await ref.delete();
    }
  }
}