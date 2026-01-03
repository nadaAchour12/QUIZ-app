// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/question_model.dart';
import '../quiz_screen.dart';
import '../screens/history_screen.dart';
import '../screens/multiPlayer_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/quiz_settings_dialog.dart';
import '../screens/user/login_screen.dart';
import '../services/json_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // ⚠️ Plus de const ici car les widgets ne sont pas tous const
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Initialisation des pages (non-const)
    _pages = [
      const QuizHomePage(),
      const MultiplayerScreen(),
      const HistoryScreen(),
       ProfileScreen(), // même si pas const, c'est OK ici
    ];

    // Redirection si non connecté
    final user = FirebaseAuth.instance.currentUser;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user == null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  void _onItemTapped(int index) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null && index != 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E2F),
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'MultiPlayer'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// ========================= QuizHomePage =========================
class QuizHomePage extends StatelessWidget {
  const QuizHomePage({super.key});

  // ✅ Ces listes sont vraiment constantes → on garde const
  static const List<Map<String, dynamic>> categories = [
    {
      "key": "sport",
      "name": "Sport",
      "color": Colors.blue,
      "icon": Icons.sports_basketball,
      "imageUrl": "assets/screen/sports_basketball.png"
    },
    {
      "key": "histoire",
      "name": "Histoire",
      "color": Colors.orange,
      "icon": Icons.account_balance,
      "imageUrl": "assets/screen/history.png"
    },
    {
      "key": "science",
      "name": "Science",
      "color": Colors.green,
      "icon": Icons.science,
      "imageUrl": "assets/screen/science.png"
    },
    {
      "key": "geography",
      "name": "Géographie",
      "color": Colors.teal,
      "icon": Icons.public,
      "imageUrl": "assets/screen/geography.png"
    },
    {
      "key": "cinema",
      "name": "Cinéma",
      "color": Colors.red,
      "icon": Icons.movie,
      "imageUrl": "assets/screen/cinema.png"
    },
    {
      "key": "drapeaux",
      "name": "Drapeaux",
      "color": Colors.purple,
      "icon": Icons.flag,
      "imageUrl": "assets/screen/flags.png"
    },
    {
      "key": "informatique",
      "name": "Informatique",
      "color": Colors.indigo,
      "icon": Icons.computer,
      "imageUrl": "assets/screen/informatique.png"
    },
    {
      "key": "islam",
      "name": "Islam",
      "color": Colors.white,
      "icon": Icons.mosque,
      "imageUrl": "assets/screen/islam.png"
    },
    {
      "key": "اعرف المسلسل",
      "name": "اعرف المسلسل",
      "color": Colors.orange,
      "icon": Icons.account_balance,
      "imageUrl": "assets/screen/series_tunisienne.png"
    },
    {
      "key": "كمل المثل",
      "name": "كمل المثل",
      "color": Colors.orange,
      "icon": Icons.account_balance,
      "imageUrl": "assets/screen/kammel_mathal.png"
    },
    {
      "key": "stades",
      "name": "Stades",
      "color": Colors.orange,
      "icon": Icons.account_balance,
      "imageUrl": "assets/screen/stades.png"
    },
    {
      "key": "languages",
      "name": "Languages",
      "color": Colors.orange,
      "icon": Icons.account_balance,
      "imageUrl": "assets/screen/language.png"
    },
    {
      "key": "logs",
      "name": "Logs",
      "color": Colors.orange,
      "icon": Icons.account_balance,
      "imageUrl": "assets/screen/logs.png"
    },

  ];

  static const List<String> avatarAssets = [
    'assets/avatar/avatar1.png',
    'assets/avatar/avatar2.png',
    'assets/avatar/avatar3.png',
    'assets/avatar/avatar4.png',
    'assets/avatar/avatar5.png',
    'assets/avatar/avatar6.png',
    'assets/avatar/avatar7.png',
    'assets/avatar/avatar8.png',
    'assets/avatar/avatar9.png',
    'assets/avatar/avatar10.png',
  ];

  // Calcul correct de la semaine ISO 8601
  String _getIsoWeekKey(DateTime date) {
    final thursday = date.add(Duration(days: 4 - (date.weekday % 7)));
    final yearThursday = DateTime(thursday.year, 1, 4);
    final firstThursday = yearThursday.add(Duration(days: 4 - (yearThursday.weekday % 7)));
    final weekNumber = ((thursday.difference(firstThursday).inDays / 7).floor() + 1);
    return "${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}";
  }

  int _calculateWeeklyIncrease(Map<String, dynamic>? weeklyScores) {
    if (weeklyScores == null || weeklyScores.isEmpty) return 0;

    final now = DateTime.now();
    final currentWeekKey = _getIsoWeekKey(now);
    final lastWeek = now.subtract(const Duration(days: 7));
    final lastWeekKey = _getIsoWeekKey(lastWeek);

    final int current = (weeklyScores[currentWeekKey] ?? 0) as int;
    final int previous = (weeklyScores[lastWeekKey] ?? 0) as int;

    return current - previous;
  }

  Future<void> _startDailyQuiz(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
    );

    try {
      List<Question> allQuestions = [];

      for (final cat in categories) {
        final questions = await loadQuestionsFromJson(category: cat["key"] as String);
        allQuestions.addAll(questions);
      }

      if (allQuestions.isEmpty) throw Exception("Aucune question chargée");

      allQuestions.shuffle();
      final dailyQuestions = allQuestions.take(10).toList();

      if (!context.mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            questions: dailyQuestions,
            numberOfQuestions: dailyQuestions.length,
            category: "daily",
            difficulty: "mixte",
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  Future<void> _startQuiz(
      BuildContext context,
      String categoryKey,
      String difficulty,
      int count,
      ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
    );

    try {
      final allQuestions = await loadQuestionsFromJson(category: categoryKey);
      final filtered = allQuestions
          .where((q) => q.difficulty.toLowerCase() == difficulty.toLowerCase())
          .toList();

      if (filtered.isEmpty) throw Exception("Aucune question pour cette difficulté");

      filtered.shuffle();
      final selected = filtered.take(count).toList();

      if (!context.mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            questions: selected,
            numberOfQuestions: selected.length,
            category: categoryKey,
            difficulty: difficulty,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: user != null
          ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        String username = 'Joueur';
        String? avatarUrl;
        int avatarIndex = 0;
        int currentScore = 0;
        int weeklyIncrease = 0;
        int coins = 0; // ← NOUVEAU : coins

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data()!;
          username = data['username'] ?? 'Joueur';
          avatarUrl = data['avatarUrl'] as String?;
          avatarIndex = (data['avatarIndex'] is int &&
              data['avatarIndex'] >= 0 &&
              data['avatarIndex'] < avatarAssets.length)
              ? data['avatarIndex'] as int
              : 0;
          currentScore = (data['dailyScore'] ?? 0) as int;
          coins = (data['coins'] ?? 0) as int; // ← Récupération des coins

          final weeklyScores = Map<String, dynamic>.from(data['weeklyScores'] ?? {});
          weeklyIncrease = _calculateWeeklyIncrease(weeklyScores);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profil
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.cyan.withOpacity(0.4), width: 1.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Image.asset(avatarAssets[avatarIndex], fit: BoxFit.cover)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Bonjour, @$username !", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const Text("Prêt à tester tes connaissances ?", style: const TextStyle(color: Colors.white70, fontSize: 15)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Score + Coins
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Score actuel
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("CURRENT SCORE", style: TextStyle(color: Colors.white54, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text("$currentScore pts", style: const TextStyle(color: Colors.cyan, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(weeklyIncrease >= 0 ? Icons.trending_up : Icons.trending_down,
                              color: weeklyIncrease >= 0 ? Colors.green : Colors.red, size: 20),
                          const SizedBox(width: 4),
                          Text("${weeklyIncrease >= 0 ? '+' : ''}$weeklyIncrease cette semaine",
                              style: TextStyle(color: weeklyIncrease >= 0 ? Colors.green : Colors.red, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),

                  // Coins à droite
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.amber, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          "$coins",
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ... le reste du code reste exactement le même
            const SizedBox(height: 30),
            const Text("Prêt à te challenger aujourd'hui ?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startDailyQuiz(context),
                icon: const Icon(Icons.play_circle_fill, size: 28),
                label: const Text("Lancer le Daily Quiz", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 10,
                  shadowColor: Colors.cyan.withOpacity(0.5),
                ),
              ),
            ),

            const SizedBox(height: 40),
            const Text("Choisis un thème", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => QuizSettingsDialog(
                        onStart: (difficulty, count) {
                          _startQuiz(context, cat["key"] as String, difficulty, count);
                        },
                      ),
                    );
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          cat["imageUrl"] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF2A2A3B),
                            child: Center(child: Icon(cat["icon"] as IconData, color: cat["color"] as Color, size: 50)),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(cat["icon"] as IconData, color: cat["color"] as Color, size: 32),
                            const SizedBox(height: 4),
                            Text(cat["name"] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}