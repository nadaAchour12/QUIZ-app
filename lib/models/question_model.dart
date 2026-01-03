// lib/models/question_model.dart
class Question {
  final String text;
  final String image;
  final List<Answer> answers;
  final String category;
  final String difficulty;

  Question({
    required this.text,
    required this.image,
    required this.answers,
    required this.category,
    required this.difficulty,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      text: json['text'] ?? 'Question',
      image: json['image'] ?? 'assets/default.png',
      answers: (json['answers'] as List<dynamic>?)
          ?.map((a) => Answer.fromMap(a as Map<String, dynamic>))
          .toList() ??
          [],
      category: json['category'] ?? 'unknown',
      difficulty: json['difficulty'] ?? 'facile',
    );
  }
}

class Answer {
  final String text;
  final bool isCorrect;

  Answer({required this.text, required this.isCorrect});

  factory Answer.fromMap(Map<String, dynamic> map) {
    return Answer(
      text: map['text'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
    );
  }
}
