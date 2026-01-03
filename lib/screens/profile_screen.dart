import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Recommandé pour les photos uploadées

import 'boutique_screen.dart';
import 'edit_profile_screen.dart';
import 'history_screen.dart';
import 'leaderboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  // ✅ EXACTEMENT LA MÊME LISTE QUE DANS EditProfileScreen !!!
  final List<String> avatarAssets = [
    'assets/avatar/avatar1.png',
    'assets/avatar/avatar2.png',
    'assets/avatar/avatar3.png',
    'assets/avatar/avatar4.png',
    'assets/avatar/avatar5.png',
    'assets/avatar/avatar6.png',
    'assets/avatar/avatar7.png',
    'assets/avatar/avatar8.png',
    'assets/avatar/avatar9.png',
    'assets/avatar/avatar10.png',
  ];

  int getLevel(int xp) => (xp ~/ 200) + 1;

  String getBadge(int level) {
    if (level >= 10) return "🏆 Master";
    if (level >= 5) return "🔥 Expert";
    if (level >= 3) return "⭐ Avancé";
    return "🎯 Débutant";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E2F),
        body: Center(
          child: Text("Utilisateur non connecté",
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2F),
        elevation: 0,
        centerTitle: true,
        title: const Text("Profil",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyan));
          }

          if (!userSnapshot.hasData || userSnapshot.data!.data() == null) {
            return const Center(
              child: Text("Profil introuvable",
                  style: TextStyle(color: Colors.white)),
            );
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;

          final String name = userData['name'] ?? 'Utilisateur';
          final String username = userData['username'] ?? '';
          final String email = user.email ?? '';
          final String? avatarUrl = userData['avatarUrl']; // Photo uploadée
          final int avatarIndex = (userData['avatarIndex'] is int &&
              userData['avatarIndex'] < avatarAssets.length)
              ? userData['avatarIndex']
              : 0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('history')
                .snapshots(),
            builder: (context, historySnapshot) {
              if (historySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.cyan));
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

              final double winRate = totalQuizzes == 0 ? 0 : (wins / totalQuizzes) * 100;
              final int xp = totalScore * 10;
              final int level = getLevel(xp);
              final String badge = getBadge(level);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 👤 AVATAR : photo perso OU avatar prédéfini
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade800,
                      child: ClipOval(
                        child: avatarUrl != null
                            ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          placeholder: (context, url) => const CircularProgressIndicator(color: Colors.cyan),
                          errorWidget: (context, url, error) => Image.asset(
                            avatarAssets[avatarIndex],
                            fit: BoxFit.cover,
                          ),
                        )
                            : Image.asset(
                          avatarAssets[avatarIndex],
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("@$username",
                        style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(email,
                        style: const TextStyle(color: Colors.white38, fontSize: 13)),
                    const SizedBox(height: 20),
                    Text("Niveau $level • $badge",
                        style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statCard("XP", xp.toString()),
                        _statCard("Quiz", totalQuizzes.toString()),
                        _statCard("Victoires", "${winRate.round()}%"),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _actionButton(
                      icon: Icons.bar_chart,
                      label: "Voir mes statistiques",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _actionButton(
                      icon: Icons.bar_chart,
                      label: "Voir le classement mondial",
                      onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                     ),
                    ),

                    const SizedBox(height: 16),
                    _actionButton(
                      icon: Icons.event_busy_sharp,
                      label: "boutique",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BoutiqueScreen()),
                      ),
                    ),


                    const SizedBox(height: 16),
                    _actionButton(
                      icon: Icons.edit,
                      label: "Modifier le profil",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _actionButton(
                      icon: Icons.logout,
                      label: "Se déconnecter",
                      color: Colors.redAccent,
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.cyan,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.blueAccent,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}