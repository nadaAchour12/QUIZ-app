import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../widget/history_chart.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // 🔐 User not logged in
    if (uid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E2F),
        body: Center(
          child: Text(
            "Veuillez vous connecter pour voir l'historique",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Historique",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('history')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Aucun quiz joué pour le moment",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final recentDocs = docs.take(10).toList();

          // ===================== CALCULS =====================
          double averageScore = 0;
          double averageIq = 0;
          final List<double> scoreValues = [];

          for (final doc in recentDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final int score = (data['score'] ?? 0).toInt();
            final int total = (data['total'] ?? 1).toInt();

            final double percentage = (score / total) * 100;
            final double iq = 80 + percentage;

            averageScore += percentage;
            averageIq += iq;
            scoreValues.add(percentage);
          }

          averageScore /= recentDocs.length;
          averageIq /= recentDocs.length;

          // ===================== UI =====================
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===================== STATS =====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCard(
                      value: "${averageScore.round()}%",
                      label: "Avg Score",
                      color: Colors.blueAccent,
                    ),
                    _statCard(
                      value: averageIq.round().toString(),
                      label: "Avg IQ",
                      color: Colors.cyanAccent,
                    ),
                    _statCard(
                      value: recentDocs.length.toString(),
                      label: "Quizzes",
                      color: Colors.purpleAccent,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ===================== GRAPH =====================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Performance Trend",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: HistoryChart(
                          values: scoreValues.reversed.toList(),
                          title: "Score Evolution",
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ===================== RECENT ATTEMPTS =====================
                const Text(
                  "Recent Attempts",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Column(
                  children: recentDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final String category = data['category'] ?? 'Inconnu';
                    final int score = (data['score'] ?? 0).toInt();
                    final int total = (data['total'] ?? 1).toInt();
                    final double percentage = (score / total) * 100;

                    DateTime date;
                    final rawDate = data['date'];
                    if (rawDate is Timestamp) {
                      date = rawDate.toDate();
                    } else if (rawDate is String) {
                      date = DateTime.tryParse(rawDate) ?? DateTime.now();
                    } else {
                      date = DateTime.now();
                    }

                    return _recentAttemptCard(
                      category: category,
                      percentage: percentage,
                      date: date,
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===================== WIDGETS =====================
  Widget _statCard({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _recentAttemptCard({
    required String category,
    required double percentage,
    required DateTime date,
  }) {
    final formattedDate = DateFormat('dd MMM • HH:mm').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.quiz, color: Colors.blueAccent, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${percentage.round()}%",
            style: TextStyle(
              color: _getPercentageColor(percentage),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.greenAccent;
    if (percentage >= 60) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
