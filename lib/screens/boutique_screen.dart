import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BoutiqueScreen extends StatelessWidget {
  const BoutiqueScreen({super.key});

  // 🔥 LISTE DES AVATARS + PRIX
  static const List<Map<String, dynamic>> avatars = [
    {"index": 0, "asset": "assets/avatar/avatar11.png", "price": 0},
    {"index": 1, "asset": "assets/avatar/avatar12.png", "price": 5},
    {"index": 2, "asset": "assets/avatar/avatar13.png", "price": 10},
    {"index": 3, "asset": "assets/avatar/avatar14.png", "price": 15},
    {"index": 4, "asset": "assets/avatar/avatar15.png", "price": 20},
    {"index": 5, "asset": "assets/avatar/avatar16.png", "price": 25},
    {"index": 6, "asset": "assets/avatar/avatar17.png", "price": 30},
    {"index": 7, "asset": "assets/avatar/avatar18.png", "price": 35},
    {"index": 8, "asset": "assets/avatar/avatar19.png", "price": 40},
    {"index": 9, "asset": "assets/avatar/avatar20.png", "price": 50},
  ];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2F),
        title: const Text("🛍 Boutique", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyan));
          }

          final data = snapshot.data!.data()!;
          final int coins = data['coins'] ?? 0;
          final int currentAvatar = data['avatarIndex'] ?? 0;
          final List ownedAvatars = List.from(data['ownedAvatars'] ?? [0]);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "💰 Coins : $coins",
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: avatars.length,
                  itemBuilder: (context, index) {
                    final avatar = avatars[index];
                    final bool owned = ownedAvatars.contains(avatar["index"]);
                    final bool selected = currentAvatar == avatar["index"];

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? Colors.cyan : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(avatar["asset"], width: 80),
                          const SizedBox(height: 12),

                          if (owned)
                            ElevatedButton(
                              onPressed: selected
                                  ? null
                                  : () async {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .update({"avatarIndex": avatar["index"]});
                              },
                              child: Text(selected ? "Équipé" : "Équiper"),
                            )
                          else
                            ElevatedButton.icon(
                              icon: const Icon(Icons.lock),
                              label: Text("${avatar["price"]} coins"),
                              onPressed: coins >= avatar["price"]
                                  ? () async {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .update({
                                  "coins": FieldValue.increment(-avatar["price"]),
                                  "ownedAvatars": FieldValue.arrayUnion([avatar["index"]]),
                                });
                              }
                                  : null,
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
