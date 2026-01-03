// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widget/coin_reward_dialog.dart';


class ResultScreen extends StatefulWidget {  // ← Change en StatefulWidget
  final int score;
  final int total;

  const ResultScreen({super.key, required this.score, required this.total});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _hasAwarded = false; // Pour éviter double appel

  @override
  void initState() {
    super.initState();
    _awardCoins();
  }

  Future<void> _awardCoins() async {
    if (_hasAwarded || !mounted) return;
    _hasAwarded = true;
    final int earnedCoins = widget.score ~/ 5;
    if (earnedCoins > 0) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'coins': FieldValue.increment(earnedCoins),
        });
      }
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CoinRewardDialog(coins: earnedCoins),
      );
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.of(context).pop(); // Ferme le dialog
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Quiz terminé !",
                style: TextStyle(color: Colors.cyan, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Text(
                "${widget.score} / ${widget.total}",
                style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                widget.score == widget.total
                    ? "Parfait ! 🎉"
                    : widget.score >= widget.total * 0.8
                    ? "Excellent ! 🔥"
                    : widget.score >= widget.total * 0.6
                    ? "Bien joué ! 👍"
                    : "Continue à t'entraîner ! 💪",
                style: const TextStyle(color: Colors.white70, fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  icon: const Icon(Icons.home, size: 28),
                  label: const Text("Retour à l'accueil", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}