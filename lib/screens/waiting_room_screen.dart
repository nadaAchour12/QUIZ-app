// lib/screens/waiting_room_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Salle d'attente", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('multiplayer_rooms').doc(widget.roomCode).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyan));
          }

          if (!snapshot.hasData || !snapshot.data!.exists || snapshot.data!.data() == null) {
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
          final Map<String, dynamic> playerNamesDynamic = data['playerNames'] ?? {};
          final Map<String, String> playerNames = playerNamesDynamic.map((key, value) => MapEntry(key, value.toString()));
          final bool isStarted = data['isStarted'] as bool? ?? false;

          // Redirection automatique quand la partie démarre
          if (isStarted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultiplayerQuizScreen(roomCode: widget.roomCode),
                  ),
                );
              }
            });
            return const Center(child: CircularProgressIndicator(color: Colors.cyan));
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text("CODE DE LA SALLE", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 10),
                SelectableText(
                  widget.roomCode,
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                const Text("Joueurs dans la salle", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                Expanded(
                  child: ListView.builder(
                    itemCount: playerUids.length,
                    itemBuilder: (context, index) {
                      final uid = playerUids[index];
                      final name = playerNames[uid] ?? 'Joueur ${index + 1}';
                      final isMe = uid == currentUser?.uid;

                      return Card(
                        color: const Color(0xFF161B22),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.cyan,
                            child: Text(
                              name.isEmpty ? '?' : name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          trailing: isMe
                              ? const Chip(
                            label: Text("Toi", style: TextStyle(fontSize: 12)),
                            backgroundColor: Colors.cyan,
                            labelPadding: EdgeInsets.symmetric(horizontal: 8),
                          )
                              : null,
                        ),
                      );
                    },
                  ),
                ),

                if (isHost)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: playerUids.length < 2
                            ? null
                            : () async {
                          // Démarre la partie
                          await _service.startQuiz(widget.roomCode);

                          // Redirige IMMÉDIATEMENT l'hôte vers le quiz
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MultiplayerQuizScreen(roomCode: widget.roomCode),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.play_arrow, size: 28),
                        label: Text(
                          playerUids.length < 2
                              ? "En attente d'un adversaire... (${playerUids.length}/4 max)"
                              : "DÉMARRER LA PARTIE",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: playerUids.length < 2 ? Colors.grey[700] : Colors.green,
                          disabledBackgroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 8,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}