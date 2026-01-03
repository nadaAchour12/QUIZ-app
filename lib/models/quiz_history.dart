import 'package:cloud_firestore/cloud_firestore.dart';

class QuizHistory {
  final String category;
  final String difficulty;
  final int score;
  final int total;
  final DateTime date;

  QuizHistory({
    required this.category,
    required this.difficulty,
    required this.score,
    required this.total,
    required this.date,
  });

  // 🎯 Pourcentage sécurisé
  double get percentage =>
      total == 0 ? 0.0 : (score / total) * 100;

  // 🧠 IQ estimé
  int get iq => (80 + percentage).round();

  // 🔄 Object → Firestore
  Map<String, dynamic> toMap() {
    return {
      "category": category,
      "difficulty": difficulty,
      "score": score,
      "total": total,
      "date": Timestamp.fromDate(date), // ✅ IMPORTANT
    };
  }

  // 🔄 Firestore → Object
  factory QuizHistory.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'];

    DateTime parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    return QuizHistory(
      category: map['category'] ?? '',
      difficulty: map['difficulty'] ?? '',
      score: (map['score'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 1,
      date: parsedDate,
    );
  }
}
