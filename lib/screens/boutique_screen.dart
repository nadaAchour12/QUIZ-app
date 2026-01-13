import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/avatar_constants.dart';

class BoutiqueScreen extends StatelessWidget {
  const BoutiqueScreen({super.key});

  // Avatars premium : indices 10-19 (avatar11.png à avatar20.png)
  static const List<Map<String, dynamic>> premiumAvatars = [
    {"index": 10, "price": 5},   // avatar11.png
    {"index": 11, "price": 10},  // avatar12.png
    {"index": 12, "price": 15},  // avatar13.png
    {"index": 13, "price": 20},  // avatar14.png
    {"index": 14, "price": 25},  // avatar15.png
    {"index": 15, "price": 30},  // avatar16.png
    {"index": 16, "price": 35},  // avatar17.png
    {"index": 17, "price": 40},  // avatar18.png
    {"index": 18, "price": 45},  // avatar19.png
    {"index": 19, "price": 50},  // avatar20.png
  ];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2F),
        title: const Text(
          "🛍 Boutique Premium",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyan),
            );
          }

          final data = snapshot.data!.data()!;
          final int coins = data['coins'] ?? 0;
          final int currentAvatar = data['avatarIndex'] ?? 0;
          final List ownedAvatars = List.from(data['ownedAvatars'] ?? [0]);

          return Column(
            children: [
              // Solde coins
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      "$coins Coins",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Info
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Débloque des avatars exclusifs avec tes coins !",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Grille avatars
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: premiumAvatars.length,
                  itemBuilder: (context, i) {
                    final avatar = premiumAvatars[i];
                    final int avatarIndex = avatar["index"];
                    final int price = avatar["price"];
                    final bool owned = ownedAvatars.contains(avatarIndex);
                    final bool selected = currentAvatar == avatarIndex;

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? Colors.amber
                              : (owned ? Colors.cyan : Colors.transparent),
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Badge Premium
                          if (!owned)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "PREMIUM",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Avatar image
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: AssetImage(
                                  AvatarConstants.avatarAssets[avatarIndex],
                                ),
                              ),
                              if (!owned)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.lock,
                                      color: Colors.white70,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              if (selected)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.black,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Bouton action
                          if (owned)
                            ElevatedButton(
                              onPressed: selected
                                  ? null
                                  : () async {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .update({"avatarIndex": avatarIndex});

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Avatar équipé ! ✨"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                selected ? Colors.grey : Colors.cyan,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                selected ? "Équipé" : "Équiper",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              icon: const Icon(Icons.shopping_cart, size: 18),
                              label: Text(
                                "$price coins",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: coins >= price
                                  ? () async {
                                final batch =
                                FirebaseFirestore.instance.batch();
                                final userRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid);

                                batch.update(userRef, {
                                  "coins": FieldValue.increment(-price),
                                  "ownedAvatars":
                                  FieldValue.arrayUnion([avatarIndex]),
                                  "avatarIndex": avatarIndex,
                                });

                                await batch.commit();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Avatar acheté et équipé ! 🎉"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: coins >= price
                                    ? Colors.amber
                                    : Colors.grey,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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