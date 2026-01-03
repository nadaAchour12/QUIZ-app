import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../home/home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int currentStep = 0;
  String name = '';
  int age = 18;
  String username = '';
  int selectedAvatarIndex = 0;

  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController usernameController;

  // ✅ LES 5 AVATARS PNG DEPUIS ASSETS (même liste que partout ailleurs)
  final List<String> avatarAssets = [
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

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    ageController = TextEditingController(text: '18');
    usernameController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  void nextStep() async {
    if (currentStep == 0 && name.trim().isEmpty) return;
    if (currentStep == 1 && age < 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimum age required: 13")),
      );
      return;
    }

    if (currentStep < 2) {
      setState(() => currentStep++);
    } else {
      // Dernière étape → sauvegarde dans Firestore
      final user = FirebaseAuth.instance.currentUser;
      final Map<String, dynamic> userData = {
        'name': name.trim(),
        'username': username.trim(),
        'age': age,
        'avatarIndex': selectedAvatarIndex,
        'onboarded': true,
        'totalScore': 0,
      };

      if (user == null) {
        // Connexion anonyme si besoin
        final cred = await FirebaseAuth.instance.signInAnonymously();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set(userData);
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData, SetOptions(merge: true));
      }

      // Aller à l'écran principal
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1E2F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: currentStep > 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => setState(() => currentStep--),
        )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LinearProgressIndicator(
                  value: (currentStep + 1) / 3,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.cyan),
                  minHeight: 6,
                ),
                const SizedBox(height: 40),

                // ÉTAPE 1 : NOM
                if (currentStep == 0) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 50, color: Colors.cyan),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'STEP 1 OF 3\nWhat\'s your name?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Let\'s start with introductions. This name will be displayed on your profile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: nameController,
                    onChanged: (v) => name = v,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "Your name",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Continue →", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],

                // ÉTAPE 2 : ÂGE
                if (currentStep == 1) ...[
                  const Icon(Icons.calendar_today, size: 50, color: Colors.cyan),
                  const SizedBox(height: 30),
                  const Text(
                    'STEP 2 OF 3\nHow old are you?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'This helps us personalize your quiz experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => age = int.tryParse(v) ?? 18,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "Ex: 25",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Continue →", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],

                // ÉTAPE 3 : AVATAR + USERNAME
                if (currentStep == 2) ...[
                  const Text(
                    "Choose your avatar",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 30),

                  // Grand avatar actuel
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey.shade800,
                    child: ClipOval(
                      child: Image.asset(
                        avatarAssets[selectedAvatarIndex],
                        fit: BoxFit.cover,
                        width: 140,
                        height: 140,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Sélection des avatars
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(avatarAssets.length, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => selectedAvatarIndex = index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedAvatarIndex == index ? Colors.cyan : Colors.transparent,
                                width: 4,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: AssetImage(avatarAssets[index]),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Pseudo
                  TextField(
                    controller: usernameController,
                    onChanged: (v) => username = v,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "GamerPro",
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixText: "@",
                      prefixStyle: const TextStyle(color: Colors.white70, fontSize: 18),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        "Start Playing!",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
                const Text(
                  'By continuing you agree to our Terms of Use.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}