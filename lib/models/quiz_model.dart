class Quiz {
  final String id;
  final String title;
  final String category;
  final String difficulty;

  Quiz({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
  });

  factory Quiz.fromFirestore(String id, Map<String, dynamic> data) {
    return Quiz(
      id: id,
      title: data['title'],
      category: data['category'],
      difficulty: data['difficulty'],
    );
  }
}
