// lib/screens/waiting_room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/avatar_constants.dart';
import '../services/multiplayer_service.dart';
import 'multiplayer_quiz_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String roomCode;

  const WaitingRoomScreen({super.key, required this.roomCode});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final MultiplayerService _service = MultiplayerService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: widget.roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Code copié dans le presse-papier !"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db
            .collection('multiplayer_rooms')
            .doc(widget.roomCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyan),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists ||
              snapshot.data!.data() == null) {
            return const Center(
              child: Text(
                "Salle introuvable ou supprimée",
                style: TextStyle(color: Colors.redAccent, fontSize: 18),
              ),
            );
          }

          final data = snapshot.data!.data()!;
          final String hostUid = data['hostUid'] as String? ?? '';
          final bool isHost = hostUid == currentUser?.uid;
          final List<dynamic> playerUidsDynamic = data['playerUids'] ?? [];
          final List<String> playerUids = playerUidsDynamic.cast<String>();
          final Map<String, dynamic> playerNamesDynamic =
              data['playerNames'] ?? {};
          final Map<String, String> playerNames = playerNamesDynamic
              .map((key, value) => MapEntry(key, value.toString()));
          final bool isStarted = data['isStarted'] as bool? ?? false;
          final String category = data['category'] ?? 'Quiz';

          // Redirection automatique quand la partie démarre
          if (isStarted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MultiplayerQuizScreen(roomCode: widget.roomCode),
                  ),
                );
              }
            });
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyan),
            );
          }

          return Column(
            children: [
              // Header avec titre
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
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
                            color: Colors.cyan.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.timer,
                            color: Colors.cyan,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "SALLE D'ATTENTE",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              category,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Code de la salle
                    GestureDetector(
                      onTap: _copyRoomCode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.cyan.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.roomCode,
                              style: const TextStyle(
                                color: Colors.cyan,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.copy,
                              color: Colors.cyan,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre section joueurs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.people,
                                color: Colors.white60,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Joueurs",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${playerUids.length}/4",
                              style: const TextStyle(
                                color: Colors.cyan,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Liste des joueurs
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _db.collection('users').snapshots(),
                          builder: (context, usersSnapshot) {
                            final Map<String, Map<String, dynamic>> usersData =
                            {};

                            if (usersSnapshot.hasData) {
                              for (final doc in usersSnapshot.data!.docs) {
                                usersData[doc.id] =
                                doc.data() as Map<String, dynamic>;
                              }
                            }

                            return ListView.builder(
                              itemCount: playerUids.length,
                              itemBuilder: (context, index) {
                                final uid = playerUids[index];
                                final name =
                                    playerNames[uid] ?? 'Joueur ${index + 1}';
                                final isMe = uid == currentUser?.uid;
                                final userData = usersData[uid];
                                final int avatarIndex =
                                    userData?['avatarIndex'] ?? 0;
                                final String? avatarUrl =
                                userData?['avatarUrl'];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Colors.cyan.withOpacity(0.15)
                                        : const Color(0xFF1A1F3A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: isMe
                                        ? Border.all(
                                      color: Colors.cyan.withOpacity(0.5),
                                      width: 2,
                                    )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 55,
                                        height: 55,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isMe
                                                ? Colors.cyan
                                                : Colors.white.withOpacity(0.2),
                                            width: 3,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: avatarUrl != null
                                              ? Image.network(
                                            avatarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) =>
                                                Image.asset(
                                                  AvatarConstants
                                                      .getAvatarAsset(
                                                      avatarIndex),
                                                  fit: BoxFit.cover,
                                                ),
                                          )
                                              : Image.asset(
                                            AvatarConstants
                                                .getAvatarAsset(
                                                avatarIndex),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 16),

                                      // Nom
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: isMe
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                fontSize: 17,
                                              ),
                                            ),
                                            if (uid == hostUid)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    top: 4),
                                                padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                  BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  "👑 Hôte",
                                                  style: TextStyle(
                                                    color: Colors.amber,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Badge "Toi"
                                      if (isMe)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.cyan,
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            "Toi",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bouton démarrer
              if (isHost)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: playerUids.length < 2
                          ? null
                          : () async {
                        await _service.startQuiz(widget.roomCode);
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MultiplayerQuizScreen(
                                  roomCode: widget.roomCode),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        playerUids.length < 2 ? Colors.grey : Colors.green,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        playerUids.length < 2
                            ? "En attente d'un adversaire..."
                            : "DÉMARRER LA PARTIE",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "En attente que l'hôte démarre la partie...",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}