// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../constants/avatar_constants.dart';
import 'boutique_screen.dart';
import 'edit_profile_screen.dart';
import 'history_screen.dart';
import 'leaderboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  int getLevel(int xp) => (xp ~/ 200) + 1;

  String getBadge(int level) {
    if (level >= 10) return "🏆 Maître";
    if (level >= 5) return "🔥 Expert";
    if (level >= 3) return "⭐ Avancé";
    return "🎯 Débutant";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1626),
        body: Center(
          child: Text(
            "Utilisateur non connecté",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Mon Profil",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyan),
            );
          }

          if (!userSnapshot.hasData || userSnapshot.data!.data() == null) {
            return const Center(
              child: Text(
                "Profil introuvable",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;

          final String name = userData['name'] ?? 'Utilisateur';
          final String username = userData['username'] ?? '';
          final String? avatarUrl = userData['avatarUrl'];
          final int avatarIndex = userData['avatarIndex'] ?? 0;
          final int coins = userData['coins'] ?? 0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('history')
                .snapshots(),
            builder: (context, historySnapshot) {
              if (historySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.cyan),
                );
              }

              final historyDocs = historySnapshot.data?.docs ?? [];

              int totalQuizzes = historyDocs.length;
              int totalScore = 0;
              int wins = 0;

              for (final doc in historyDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final int score = (data['score'] ?? 0).toInt();
                final int total = (data['total'] ?? 1).toInt();
                totalScore += score;
                if (total > 0 && (score / total) >= 0.5) wins++;
              }

              final double winRate =
              totalQuizzes == 0 ? 0 : (wins / totalQuizzes) * 100;
              final int xp = totalScore * 10;
              final int level = getLevel(xp);
              final String badge = getBadge(level);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar et infos
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.cyan.withOpacity(0.3),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.black87,
                        child: ClipOval(
                          child: avatarUrl != null
                              ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            width: 112,
                            height: 112,
                            placeholder: (context, url) =>
                            const CircularProgressIndicator(
                              color: Colors.cyan,
                            ),
                            errorWidget: (context, url, error) =>
                                Image.asset(
                                  AvatarConstants.getAvatarAsset(avatarIndex),
                                  fit: BoxFit.cover,
                                ),
                          )
                              : Image.asset(
                            AvatarConstants.getAvatarAsset(avatarIndex),
                            fit: BoxFit.cover,
                            width: 112,
                            height: 112,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "@$username",
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Niveau et coins
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.cyan.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.cyan, width: 1.5),
                          ),
                          child: Text(
                            "Niveau $level • $badge",
                            style: const TextStyle(
                              color: Colors.cyan,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "$coins",
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            label: "XP",
                            value: xp.toString(),
                            icon: Icons.insights,
                            color: Colors.cyan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            label: "Quiz",
                            value: totalQuizzes.toString(),
                            icon: Icons.quiz,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            label: "Victoires",
                            value: "${winRate.round()}%",
                            icon: Icons.emoji_events,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Actions
                    _menuButton(
                      context: context,
                      icon: Icons.bar_chart,
                      label: "Statistiques",
                      color: Colors.cyan,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _menuButton(
                      context: context,
                      icon: Icons.leaderboard,
                      label: "Classement",
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LeaderboardScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _menuButton(
                      context: context,
                      icon: Icons.shopping_bag,
                      label: "Boutique",
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BoutiqueScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _menuButton(
                      context: context,
                      icon: Icons.edit,
                      label: "Modifier profil",
                      color: Colors.blueAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _menuButton(
                      context: context,
                      icon: Icons.logout,
                      label: "Déconnexion",
                      color: Colors.red,
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                                (_) => false,
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white30,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}