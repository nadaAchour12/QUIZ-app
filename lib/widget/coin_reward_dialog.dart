// lib/widgets/coin_reward_dialog.dart
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class CoinRewardDialog extends StatefulWidget {
  final int coins;

  const CoinRewardDialog({super.key, required this.coins});

  @override
  State<CoinRewardDialog> createState() => _CoinRewardDialogState();
}

class _CoinRewardDialogState extends State<CoinRewardDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AlertDialog(
          backgroundColor: const Color(0xFF1E1E2F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Félicitations !",
                style: TextStyle(color: Colors.cyan, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 50),
                  const SizedBox(width: 16),
                  Text(
                    "+${widget.coins} coins gagnés !",
                    style: const TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "Continue comme ça !",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.2,
            colors: const [Colors.amber, Colors.cyan, Colors.green, Colors.yellow],
          ),
        ),
      ],
    );
  }
}