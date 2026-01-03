// lib/services/json_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question_model.dart';

/// Charge toutes les questions d'une catégorie depuis JSON
Future<List<Question>> loadQuestionsFromJson({required String category}) async {
  try {
    // 1️⃣ Charger le fichier JSON depuis assets
    final String jsonString =
    await rootBundle.loadString('assets/data/$category/questions.json');

    // 2️⃣ Décoder le JSON
    final List<dynamic> jsonData = json.decode(jsonString);

    // 3️⃣ Convertir en liste de Question
    final questions = jsonData.map<Question>((q) {
      return Question.fromJson(q);
    }).toList();

    return questions;
  } catch (e) {
    print("Erreur lors du chargement du JSON pour $category : $e");
    return [];
  }
}
