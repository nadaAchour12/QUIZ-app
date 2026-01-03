import '../models/quiz_history.dart';

class StatsHelper {
  static double avgScore(List<QuizHistory> list) {
    if (list.isEmpty) return 0;
    return list.map((e) => e.percentage).reduce((a, b) => a + b) / list.length;
  }

  static int iq(List<QuizHistory> list) {
    final avg = avgScore(list);
    return (80 + avg).round(); // simple & logique
  }
}
