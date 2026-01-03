import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Question>> getQuestions({
    required String category,
    required String difficulty,
  }) async {
    List<Question> allQuestions = [];
    final quizzesSnap = await _db.collection('quizzes').get(); // Récupérer tous les quizzes
    for (final quizDoc in quizzesSnap.docs) {
      final quizData = quizDoc.data();
      if (quizData['category']?.toString().toLowerCase() == category.toLowerCase() &&
          quizData['difficulty']?.toString().toLowerCase() == difficulty.toLowerCase()) {
        final questionsSnap = await _db
            .collection('quizzes')
            .doc(quizDoc.id)
            .collection('questions')
            .get();

        for (final qDoc in questionsSnap.docs) {
          final qData = qDoc.data();

          // 🔥 Image sécurisée
          String image = 'assets/default.png';
          if (qData['image'] is String && qData['image'].toString().isNotEmpty) {
            image = qData['image'];
          }

          allQuestions.add(
            Question(
              text: qData['question'] ?? qData['text'] ?? 'Question',
              image: image,
              answers: _parseAnswers(qData['answers']),
              category: quizData['category'] ?? category,    // ajouté
              difficulty: quizData['difficulty'] ?? difficulty, // ajouté
            ),
          );
        }
      }
    }

    return allQuestions;
  }

  // 4️⃣ Parser les réponses
  List<Answer> _parseAnswers(dynamic data) {
    if (data is! List) {
      return [
        Answer(text: 'Vrai', isCorrect: true),
        Answer(text: 'Faux', isCorrect: false),
      ];
    }

    return data.map<Answer>((a) {
      return Answer(
        text: a['text'] ?? '',
        isCorrect: a['isCorrect'] ?? false,
      );
    }).toList();
  }
}
