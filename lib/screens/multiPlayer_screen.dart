import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizmaster/screens/waiting_room_screen.dart';
import 'choose_difficulty_screen.dart';
import '../services/multiplayer_service.dart';
import 'multiplayer_quiz_screen.dart';

class MultiplayerScreen extends StatefulWidget {
  const MultiplayerScreen({super.key});

  @override
  State<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> {
  final MultiplayerService _multiplayerService = MultiplayerService();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<Map<String, String>> categories = const [
    {'name': 'Histoire', 'image': 'assets/screen/history.png'},
    {'name': 'Géographie', 'image': 'assets/screen/geography.png'},
    {'name': 'Science', 'image': 'assets/screen/science.png'},
    {'name': 'Cinéma', 'image': 'assets/screen/cinema.png'},
    {'name': 'Sport', 'image': 'assets/screen/sports_basketball.png'},
    {'name': 'Drapeaux', 'image': 'assets/screen/flags.png'},
    {'name': 'Informatique', 'image': 'assets/screen/informatique.png'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Rejoindre une salle
  // Rejoindre une salle et naviguer vers le quiz multijoueur
  Future<void> _joinRoom(String roomCode) async {
    try {
      final room = await _multiplayerService.joinRoom(roomCode);

      if (room == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Salle introuvable, pleine ou déjà commencée"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tu as rejoint la salle ${room.code} !"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WaitingRoomScreen(roomCode: room.code),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
      );
    }
  }


  // Créer une nouvelle salle

  // Créer une salle → aller à la salle d’attente
  void _createRoom(String categoryName) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ChooseDifficultyScreen(category: categoryName),
      ),
    );

    if (result == null || !mounted) return;

    final String difficulty = result['difficulty'];
    final int numberOfQuestions = result['numberOfQuestions'];

    try {
      final room = await _multiplayerService.createRoom(
        category: categoryName.toLowerCase(),
        difficulty: difficulty,
        numberOfQuestions: numberOfQuestions,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Salle créée ! Code : ${room.code}"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WaitingRoomScreen(roomCode: room.code),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
      );
    }
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return "À l'instant";
    if (difference.inMinutes < 60) return "Il y a ${difference.inMinutes} min";
    if (difference.inHours < 24) return "Il y a ${difference.inHours} h";
    return "Il y a ${difference.inDays} j";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: const Text("Multijoueur", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.cyan.withOpacity(0.3),
              child: const Icon(Icons.group, color: Colors.cyan),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Rejoindre une partie",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Entre le code ou cherche une salle publique",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: "Code de salle ou recherche...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[850],
                    prefixIcon: const Icon(Icons.search, color: Colors.cyan),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.length == 6) {
                      _joinRoom(value.toUpperCase());
                    }
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),

          // Liste des salles publiques
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('multiplayer_rooms')
                  .where('isStarted', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.cyan));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Aucune salle publique disponible pour le moment",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final rooms = snapshot.data!.docs;
                final searchText = _searchController.text.toLowerCase();

                final filteredRooms = rooms.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final code = doc.id.toLowerCase();
                  final hostName = (data['hostName'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '').toString().toLowerCase();
                  return code.contains(searchText) ||
                      hostName.contains(searchText) ||
                      category.contains(searchText);
                }).toList();

                if (filteredRooms.isEmpty) {
                  return const Center(
                    child: Text("Aucune salle correspondante", style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredRooms.length,
                  itemBuilder: (context, index) {
                    final doc = filteredRooms[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final code = doc.id;
                    final hostUid = data['hostUid'];
                    final hostName = data['hostName'] ?? 'Joueur';
                    final category = data['category'] ?? 'Thème inconnu';
                    final playersCount = (data['playerUids'] as List?)?.length ?? 1;
                    final createdAt = (data['createdAt'] as Timestamp?) ?? Timestamp.now();
                    final timeAgo = _timeAgo(createdAt.toDate());
                    final bool isHost = hostUid == user?.uid;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.grey[850],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        onTap: () => _joinRoom(code),
                        leading: CircleAvatar(
                          backgroundColor: Colors.cyan,
                          child: Text(
                            hostName.isNotEmpty ? hostName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(hostName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Code: $code", style: const TextStyle(color: Colors.cyan)),
                            Text("$category • $playersCount joueur${playersCount > 1 ? 's' : ''}", style: const TextStyle(color: Colors.white70)),
                            Text(timeAgo, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                        trailing: isHost && playersCount >= 2
                            ? ElevatedButton(
                          onPressed: () async {
                            await _multiplayerService.startQuiz(code);
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MultiplayerQuizScreen(roomCode: code),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text("Démarrer", style: TextStyle(fontSize: 12)),
                        )
                            : const Icon(Icons.arrow_forward_ios, color: Colors.cyan, size: 18),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => _buildCreateRoomBottomSheet(),
          );
        },
        backgroundColor: Colors.cyan,
        icon: const Icon(Icons.add),
        label: const Text("Créer une partie", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCreateRoomBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1117),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "Choisis un thème",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _createRoom(cat['name']!);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.cyan.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.2),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: DecorationImage(
                            image: AssetImage(cat['image']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        cat['name']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}