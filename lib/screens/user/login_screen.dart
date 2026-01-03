// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedAvatar;

  final List<String> avatars = [
    "https://img.freepik.com/free-vector/cute-boy-cartoon_138676-2400.jpg",
    "https://img.freepik.com/free-vector/cute-girl-cartoon_138676-2410.jpg",
    "https://img.freepik.com/free-vector/cute-robot-cartoon_138676-2420.jpg",
    "https://img.freepik.com/free-vector/cute-cat-cartoon_138676-2430.jpg",
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAvatar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez choisir un avatar")),
      );
      return;
    }

    // Créer un utilisateur anonyme Firebase (pour avoir un uid unique)
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    final uid = userCredential.user!.uid;

    // Sauvegarder les infos dans Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'username': _nameController.text.trim(),
      'age': int.parse(_ageController.text.trim()),
      'photoURL': _selectedAvatar,
      'onboarded': true,
      'totalScore': 0,
    });

    // Retour à l'écran Home
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2F),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  "Bienvenue sur QuizMaster",
                  style: TextStyle(color: Colors.cyan, fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Nom
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Nom",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyan),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => (value == null || value.isEmpty) ? "Entrez votre nom" : null,
                ),
                const SizedBox(height: 16),

                // Age
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: "Âge",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyan),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Entrez votre âge";
                    final age = int.tryParse(value);
                    if (age == null || age <= 0) return "Âge invalide";
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Choix de l'avatar
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Choisis un avatar",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: avatars.length,
                    itemBuilder: (context, index) {
                      final avatar = avatars[index];
                      final isSelected = _selectedAvatar == avatar;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatar = avatar;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: isSelected ? Border.all(color: Colors.cyan, width: 3) : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(avatar, width: 80, height: 80, fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Commencer",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
