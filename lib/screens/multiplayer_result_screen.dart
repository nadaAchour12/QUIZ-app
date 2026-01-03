// lib/screens/multiplayer_result_screen.dart
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widget/coin_reward_dialog.dart';

class MultiplayerResultScreen extends StatefulWidget {
  final String roomCode;
  final Map<String, int> playerScores;
  final Map<String, String> playerNames;
  final String currentUserUid;

  const MultiplayerResultScreen({
    super.key,
    required this.roomCode,
    required this.playerScores,
    required this.playerNames,
    required this.currentUserUid,
  });

  @override
  State<MultiplayerResultScreen> createState() => _MultiplayerResultScreenState();
}

class _MultiplayerResultScreenState extends State<MultiplayerResultScreen> {
  late ConfettiController _confettiController;
  int _podiumStep = 0;
  bool _hasProcessed = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _podiumStep = 1);
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _podiumStep = 2);
    });
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() => _podiumStep = 3);
        _confettiController.play();
        _processEndOfGame(); // ← SEULE fonction appelée
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  List<MapEntry<String, int>> get sortedPlayers {
    return widget.playerScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  String getRankEmoji(int rank) {
    switch (rank) {
      case 0: return '🥇';
      case 1: return '🥈';
      case 2: return '🥉';
      default: return '🏅';
    }
  }

  String _getOrdinalSuffix(int number) => number == 1 ? "er" : "ème";

  /// Traitement unique de fin de partie : coins + totalScore
  Future<void> _processEndOfGame() async {
    if (_hasProcessed || !mounted) return;
    _hasProcessed = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final myScore = widget.playerScores[widget.currentUserUid] ?? 0;
    final players = sortedPlayers;
    final myRank = players.indexWhere((e) => e.key == widget.currentUserUid);

    // Coins selon classement
    int earnedCoins = 0;
    if (myRank == 0) earnedCoins = 5;
    else if (myRank == 1) earnedCoins = 3;
    else if (myRank >= 2) earnedCoins = 1;

    // Mise à jour Firestore en une seule transaction
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

        final updates = <String, dynamic>{
          'totalScore': FieldValue.increment(myScore),
        };

        if (earnedCoins > 0) {
          updates['coins'] = FieldValue.increment(earnedCoins);
        }

        transaction.update(userRef, updates);
      });
    } catch (e) {
      debugPrint("Erreur mise à jour Firestore : $e");
      // Ne bloque pas l'UI même en cas d'erreur réseau
    }

    // Animation coins (seulement si gagnés)
    if (earnedCoins > 0 && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CoinRewardDialog(coins: earnedCoins),
      );

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = sortedPlayers;
    final myRank = players.indexWhere((e) => e.key == widget.currentUserUid);
    final myScore = widget.playerScores[widget.currentUserUid] ?? 0;
    final myName = widget.playerNames[widget.currentUserUid] ?? 'Toi';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 50),
                const Text(
                  "RÉSULTATS FINAUX",
                  style: TextStyle(color: Colors.cyan, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (players.length > 1) _buildPodiumPlayer(players[1], 2, _podiumStep >= 2),
                      const SizedBox(width: 30),
                      if (players.isNotEmpty) _buildPodiumPlayer(players[0], 1, _podiumStep >= 3, isFirst: true),
                      const SizedBox(width: 30),
                      if (players.length > 2) _buildPodiumPlayer(players[2], 3, _podiumStep >= 1),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Card(
                  color: const Color(0xFF161B22),
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Text(getRankEmoji(myRank), style: const TextStyle(fontSize: 50)),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ta place : ${myRank + 1}${_getOrdinalSuffix(myRank + 1)}",
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text("$myName • $myScore points", style: const TextStyle(color: Colors.cyan, fontSize: 18)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    icon: const Icon(Icons.home, size: 28),
                    label: const Text("Retour à l'accueil", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 10,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.04,
              numberOfParticles: 80,
              gravity: 0.15,
              colors: const [Colors.cyan, Colors.yellow, Colors.pink, Colors.green, Colors.orange],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlayer(MapEntry<String, int> player, int position, bool visible, {bool isFirst = false}) {
    final name = widget.playerNames[player.key] ?? 'Joueur';
    final score = player.value;

    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 700),
      child: AnimatedScale(
        scale: visible ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 700),
        curve: Curves.elasticOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(getRankEmoji(position - 1), style: TextStyle(fontSize: isFirst ? 70 : 55)),
            const SizedBox(height: 12),
            CircleAvatar(
              radius: isFirst ? 45 : 35,
              backgroundColor: Colors.cyan,
              child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: TextStyle(fontSize: isFirst ? 36 : 28, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("$score pts", style: TextStyle(color: Colors.yellow[600], fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              height: isFirst ? 200 : (position == 2 ? 150 : 110),
              width: 110,
              decoration: BoxDecoration(
                color: position == 1 ? Colors.amber : (position == 2 ? Colors.grey[300] : Colors.brown[700]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 8))],
              ),
              child: Center(
                child: Text(position.toString(),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}