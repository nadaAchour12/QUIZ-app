import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_history.dart';

class HistoryService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveQuiz(QuizHistory history) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('history')
        .add(history.toMap());
  }



}
