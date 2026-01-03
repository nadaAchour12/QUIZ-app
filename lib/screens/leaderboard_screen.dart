// lib/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2F),
        elevation: 0,
        title: const Text(
          "🏆 Classement Général (All-Time)",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // On récupère tous les utilisateurs triés par totalScore (descendant)
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('dailyScore', descending: true)
            .limit(100) // Top 100 pour éviter de charger trop de données
            .snapshots(),
        builder: (context, snapshot) {
          // Chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyan));
          }

          // Aucun joueur ou aucun score
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, size: 80, color: Colors.amber),
                    SizedBox(height: 20),
                    Text(
                      "Aucun joueur dans le classement",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Joue des quizzes pour apparaître ici ! 🔥",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // Trouver le rang du joueur actuel
          final int myRank = myUid != null
              ? docs.indexWhere((doc) => doc.id == myUid) + 1
              : 0;

          return Column(
            children: [
              // En-tête avec ton rang
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "🏆 Meilleurs joueurs de tous les temps",
                      style: TextStyle(color: Colors.cyan, fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      myRank > 0
                          ? "Ton rang : #$myRank"
                          : "Tu n'es pas encore classé",
                      style: TextStyle(
                        color: myRank > 0 ? Colors.amber : Colors.white70,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des joueurs
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final String username = data['username'] ?? 'Joueur';
                    final int score = (data['dailyScore'] as num?)?.toInt() ?? 0;
                    final bool isMe = doc.id == myUid;
                    return Card(
                      color: isMe ? Colors.cyan.withOpacity(0.3) : const Color(0xFF2A2A3B),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: isMe ? 8 : 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: index < 3 ? Colors.amber : Colors.grey[600],
                          child: Text(
                            "#${index + 1}",
                            style: TextStyle(
                              color: index < 3 ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        title: Text(
                          username,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                            fontSize: 18,
                          ),
                        ),
                        trailing: Text(
                          "$score pts",
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}