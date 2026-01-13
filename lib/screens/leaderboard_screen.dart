// lib/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/avatar_constants.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  String _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return "🥇";
      case 2:
        return "🥈";
      case 3:
        return "🥉";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('dailyScore', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyan),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.leaderboard,
                      size: 80,
                      color: Colors.white30,
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Aucun joueur classé",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Joue des quizzes pour apparaître ici",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final int myRank = myUid != null
              ? docs.indexWhere((doc) => doc.id == myUid) + 1
              : 0;

          return Column(
            children: [
              // Titre de la page
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1F3A),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TOP JOUEURS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              "Les meilleurs scores",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Ta position avec avatar
              if (myRank > 0)
                Builder(
                  builder: (context) {
                    final myData = docs[myRank - 1].data();
                    final int myAvatarIndex = myData['avatarIndex'] ?? 0;
                    final String? myAvatarUrl = myData['avatarUrl'];
                    final int myScore = (myData['dailyScore'] as num?)?.toInt() ?? 0;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F3A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.cyan.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyan,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: myAvatarUrl != null
                                  ? Image.network(
                                myAvatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  AvatarConstants.getAvatarAsset(myAvatarIndex),
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : Image.asset(
                                AvatarConstants.getAvatarAsset(myAvatarIndex),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Ta position",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "#$myRank",
                                  style: const TextStyle(
                                    color: Colors.cyan,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "$myScore pts",
                            style: const TextStyle(
                              color: Colors.cyan,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 16),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.people, color: Colors.white60, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Tous les joueurs",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Liste avec avatars
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
                    final int rank = index + 1;
                    final int avatarIndex = data['avatarIndex'] ?? 0;
                    final String? avatarUrl = data['avatarUrl'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.cyan.withOpacity(0.1)
                            : const Color(0xFF1A1F3A),
                        borderRadius: BorderRadius.circular(16),
                        border: isMe
                            ? Border.all(
                          color: Colors.cyan.withOpacity(0.5),
                          width: 1.5,
                        )
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: rank <= 3
                                    ? Colors.amber
                                    : Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: avatarUrl != null
                                  ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  AvatarConstants.getAvatarAsset(avatarIndex),
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : Image.asset(
                                AvatarConstants.getAvatarAsset(avatarIndex),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Rang et emoji
                          SizedBox(
                            width: 50,
                            child: Row(
                              children: [
                                Text(
                                  "#$rank",
                                  style: TextStyle(
                                    color: rank <= 3 ? Colors.amber : Colors.white60,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (rank <= 3)
                                  Text(
                                    _getRankIcon(rank),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Username
                          Expanded(
                            child: Text(
                              username,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Score
                          Text(
                            "$score",
                            style: TextStyle(
                              color: rank <= 3 ? Colors.amber : Colors.white70,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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