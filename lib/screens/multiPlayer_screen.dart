import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/avatar_constants.dart';
import 'waiting_room_screen.dart';
import 'choose_difficulty_screen.dart';
import '../services/multiplayer_service.dart';

class MultiplayerScreen extends StatefulWidget {
  const MultiplayerScreen({super.key});

  @override
  State<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> {
  final MultiplayerService _multiplayerService = MultiplayerService();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Map<String, String> categoryImages = const {
    'histoire': 'assets/screen/history.png',
    'géographie': 'assets/screen/geography.png',
    'geography': 'assets/screen/geography.png',
    'science': 'assets/screen/science.png',
    'cinéma': 'assets/screen/cinema.png',
    'cinema': 'assets/screen/cinema.png',
    'sport': 'assets/screen/sports_basketball.png',
    'drapeaux': 'assets/screen/flags.png',
    'informatique': 'assets/screen/informatique.png',
    'islam': 'assets/screen/islam.png',
    'اعرف المسلسل': 'assets/screen/series_tunisienne.png',
    'كمل المثل': 'assets/screen/kammel_mathal.png',
    'stades': 'assets/screen/stades.png',
    'languages': 'assets/screen/language.png',
    'logs': 'assets/screen/logs.png',
  };

  final List<Map<String, String>> categories = const [
    {'name': 'Histoire', 'image': 'assets/screen/history.png'},
    {'name': 'Géographie', 'image': 'assets/screen/geography.png'},
    {'name': 'Science', 'image': 'assets/screen/science.png'},
    {'name': 'Cinéma', 'image': 'assets/screen/cinema.png'},
    {'name': 'Sport', 'image': 'assets/screen/sports_basketball.png'},
    {'name': 'Drapeaux', 'image': 'assets/screen/flags.png'},
    {'name': 'Informatique', 'image': 'assets/screen/informatique.png'},
    {"name": "Islam", "image": "assets/screen/islam.png"},
    {"name": "اعرف المسلسل", "image": "assets/screen/series_tunisienne.png"},
    {"name": "كمل المثل", "image": "assets/screen/kammel_mathal.png"},
    {"name": "Stades", "image": "assets/screen/stades.png"},
    {"name": "Languages", "image": "assets/screen/language.png"},
    {"name": "Logs", "image": "assets/screen/logs.png"},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getCategoryImage(String category) {
    final key = category.toLowerCase();
    return categoryImages[key] ?? 'assets/screen/history.png';
  }

  Future<void> _joinRoom(String roomCode) async {
    try {
      final room = await _multiplayerService.joinRoom(roomCode);

      if (room == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Salle introuvable, pleine ou déjà commencée"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tu as rejoint la salle ${room.code} !"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WaitingRoomScreen(roomCode: room.code),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Salle créée ! Code : ${room.code}"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WaitingRoomScreen(roomCode: room.code),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return "À l'instant";
    if (difference.inMinutes < 60) return "${difference.inMinutes} min";
    if (difference.inHours < 24) return "${difference.inHours}h";
    return "${difference.inDays}j";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Titre de la page
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.cyan,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MULTIJOUEUR",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      "Défie tes amis en ligne",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Champ de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: "Code de salle ou recherche...",
                hintStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF1A1F3A),
                prefixIcon: const Icon(Icons.search, color: Colors.cyan),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
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
          ),

          const SizedBox(height: 20),

          // Titre section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.public, color: Colors.white60, size: 20),
                SizedBox(width: 8),
                Text(
                  "Salles publiques",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Liste des salles avec avatars
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('multiplayer_rooms')
                  .where('isStarted', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_off,
                          size: 60,
                          color: Colors.white30,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Aucune salle disponible",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final rooms = snapshot.data!.docs;
                final searchText = _searchController.text.toLowerCase();

                final filteredRooms = rooms.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final code = doc.id.toLowerCase();
                  final hostName =
                  (data['hostName'] ?? '').toString().toLowerCase();
                  final category =
                  (data['category'] ?? '').toString().toLowerCase();
                  return code.contains(searchText) ||
                      hostName.contains(searchText) ||
                      category.contains(searchText);
                }).toList();

                if (filteredRooms.isEmpty) {
                  return const Center(
                    child: Text(
                      "Aucune salle correspondante",
                      style: TextStyle(color: Colors.white60),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('users').snapshots(),
                  builder: (context, usersSnapshot) {
                    final Map<String, Map<String, dynamic>> usersData = {};

                    if (usersSnapshot.hasData) {
                      for (final doc in usersSnapshot.data!.docs) {
                        usersData[doc.id] =
                        doc.data() as Map<String, dynamic>;
                      }
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredRooms.length,
                      itemBuilder: (context, index) {
                        final doc = filteredRooms[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final code = doc.id;
                        final hostUid = data['hostUid'];
                        final hostName = data['hostName'] ?? 'Joueur';
                        final category = data['category'] ?? 'Thème';
                        final playersCount =
                            (data['playerUids'] as List?)?.length ?? 1;
                        final createdAt = (data['createdAt'] as Timestamp?) ??
                            Timestamp.now();
                        final timeAgo = _timeAgo(createdAt.toDate());
                        final categoryImage = _getCategoryImage(category);

                        // Récupération de l'avatar de l'hôte
                        final hostData = usersData[hostUid];
                        final int hostAvatarIndex =
                            hostData?['avatarIndex'] ?? 0;
                        final String? hostAvatarUrl = hostData?['avatarUrl'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1F3A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.cyan.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            onTap: () => _joinRoom(code),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Avatar de l'hôte
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.cyan.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: hostAvatarUrl != null
                                        ? Image.network(
                                      hostAvatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Image.asset(
                                            AvatarConstants.getAvatarAsset(
                                                hostAvatarIndex),
                                            fit: BoxFit.cover,
                                          ),
                                    )
                                        : Image.asset(
                                      AvatarConstants.getAvatarAsset(
                                          hostAvatarIndex),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Image de catégorie
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.cyan.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      categoryImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.cyan.withOpacity(0.2),
                                        child: const Icon(
                                          Icons.quiz,
                                          color: Colors.cyan,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              hostName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  "Code: $code",
                                  style: const TextStyle(
                                    color: Colors.cyan,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      category,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Text(
                                      " • ",
                                      style: TextStyle(color: Colors.white30),
                                    ),
                                    Text(
                                      "$playersCount joueur${playersCount > 1 ? 's' : ''}",
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Text(
                                      " • ",
                                      style: TextStyle(color: Colors.white30),
                                    ),
                                    Text(
                                      timeAgo,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.cyan,
                              size: 18,
                            ),
                          ),
                        );
                      },
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
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Créer une partie",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCreateRoomBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F3A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Choisis un thème",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.cyan.withOpacity(0.3),
                            width: 2,
                          ),
                          image: DecorationImage(
                            image: AssetImage(cat['image']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['name']!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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