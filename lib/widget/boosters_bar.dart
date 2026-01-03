// lib/widgets/boosters_bar.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BoostersBar extends StatelessWidget {
  final VoidCallback onExtraTime;
  final VoidCallback onRevealAnswer;
  final VoidCallback onDoublePoints;

  const BoostersBar({
    super.key,
    required this.onExtraTime,
    required this.onRevealAnswer,
    required this.onDoublePoints,
  });

  Future<bool> _spendCoins(int amount, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final currentCoins = (doc.data()?['coins'] as num?)?.toInt() ?? 0;

    if (currentCoins < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 10),
              Text("Pas assez de coins ! Il te manque ${amount - currentCoins} 💰"),
            ],
          ),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'coins': FieldValue.increment(-amount),
    });

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.cyan.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _boosterItem(
            context: context,
            icon: Icons.timer_outlined,
            glowColor: Colors.green,
            label: "+5s",
            cost: 5,
            onTap: () async {
              if (await _spendCoins(5, context)) {
                onExtraTime();
                _showActivation(context, "+5 secondes !", Colors.green);
              }
            },
          ),
          _boosterItem(
            context: context,
            icon: Icons.lightbulb_outline,
            glowColor: Colors.amber,
            label: "Révéler",
            cost: 15,
            onTap: () async {
              if (await _spendCoins(15, context)) {
                onRevealAnswer();
                _showActivation(context, "Réponse révélée !", Colors.amber);
              }
            },
          ),
          _boosterItem(
            context: context,
            icon: Icons.star_outline,
            glowColor: Colors.purple,
            label: "x2 pts",
            cost: 20,
            onTap: () async {
              if (await _spendCoins(20, context)) {
                onDoublePoints();
                _showActivation(context, "Double points x3 !", Colors.purple);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _boosterItem({
    required BuildContext context,
    required IconData icon,
    required Color glowColor,
    required String label,
    required int cost,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.3),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: glowColor, size: 36),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: glowColor, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  cost.toString(),
                  style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showActivation(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: color),
            const SizedBox(width: 12),
            Text(message, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}