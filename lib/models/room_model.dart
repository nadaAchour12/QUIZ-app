// lib/models/room_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MultiplayerRoom {
  final String id;
  final String code;
  final String hostUid;
  final String hostName;
  final String category;
  final String difficulty;
  final int numberOfQuestions;
  final List<String> playerUids;
  final Map<String, String> playerNames;
  final Map<String, int> scores;
  final int currentQuestionIndex;
  final bool isStarted;
  final bool isFinished;
  final DateTime createdAt;
  final List<dynamic>? questions;

  MultiplayerRoom({
    required this.id,
    required this.code,
    required this.hostUid,
    required this.hostName,
    required this.category,
    required this.difficulty,
    required this.numberOfQuestions,
    required this.playerUids,
    required this.playerNames,
    required this.scores,
    required this.currentQuestionIndex,
    required this.isStarted,
    required this.isFinished,
    required this.createdAt,
    this.questions,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'hostUid': hostUid,
      'hostName': hostName,
      'category': category,
      'difficulty': difficulty,
      'numberOfQuestions': numberOfQuestions,
      'playerUids': playerUids,
      'playerNames': playerNames,
      'scores': scores,
      'currentQuestionIndex': currentQuestionIndex,
      'isStarted': isStarted,
      'isFinished': isFinished,
      'createdAt': Timestamp.fromDate(createdAt),
      if (questions != null) 'questions': questions,
    };
  }

  factory MultiplayerRoom.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data()!;

    return MultiplayerRoom(
      id: snap.id,
      code: data['code'] ?? '',
      hostUid: data['hostUid'] ?? '',
      hostName: data['hostName'] ?? 'Joueur',
      category: data['category'] ?? '',
      difficulty: data['difficulty'] ?? '',
      numberOfQuestions: data['numberOfQuestions'] ?? 10,
      playerUids: List<String>.from(data['playerUids'] ?? []),
      playerNames: Map<String, String>.from(data['playerNames'] ?? {}),
      scores: Map<String, int>.from(data['scores'] ?? {}),
      currentQuestionIndex: data['currentQuestionIndex'] ?? 0,
      isStarted: data['isStarted'] ?? false,
      isFinished: data['isFinished'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      questions: data['questions'],
    );
  }
}