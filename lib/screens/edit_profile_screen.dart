import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../constants/avatar_constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();

  bool isLoading = false;
  File? selectedImage;
  int selectedAvatarIndex = 0;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    final data = doc.data();
    if (data == null) return;

    _nameController.text = data['name'] ?? '';
    _usernameController.text = data['username'] ?? '';
    selectedAvatarIndex = data['avatarIndex'] ?? 0;

    setState(() {});
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<String?> uploadAvatar(File image) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('avatars')
        .child('${user!.uid}.jpg');

    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> saveProfile() async {
    if (user == null) return;

    if (_nameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tous les champs sont obligatoires")),
      );
      return;
    }

    setState(() => isLoading = true);

    String? avatarUrl;

    if (selectedImage != null) {
      avatarUrl = await uploadAvatar(selectedImage!);
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'avatarIndex': selectedAvatarIndex,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });

    setState(() => isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil mis à jour avec succès !"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2F),
        elevation: 0,
        title: const Text("Modifier le profil"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar principal
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey.shade800,
                backgroundImage: selectedImage != null
                    ? FileImage(selectedImage!)
                    : null,
                child: selectedImage == null
                    ? ClipOval(
                  child: Image.asset(
                    AvatarConstants.getAvatarAsset(selectedAvatarIndex),
                    fit: BoxFit.cover,
                    width: 110,
                    height: 110,
                  ),
                )
                    : null,
              ),
            ),

            const SizedBox(height: 10),
            const Text(
              "Appuyer pour changer l'image",
              style: TextStyle(color: Colors.white54),
            ),

            const SizedBox(height: 30),

            // Titre section avatars gratuits
            const Text(
              "Avatars gratuits",
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Choix des 10 premiers avatars GRATUITS (indices 0-9)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final ownedAvatars = snapshot.hasData
                    ? List<int>.from(snapshot.data!.get('ownedAvatars') ?? [0])
                    : [0];

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      10, // ← SEULEMENT LES 10 PREMIERS (indices 0-9)
                          (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedAvatarIndex = index;
                              selectedImage = null;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedAvatarIndex == index
                                    ? Colors.cyan
                                    : Colors.transparent,
                                width: 4,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 35,
                              backgroundImage: AssetImage(
                                AvatarConstants.avatarAssets[index],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // Section avatars premium
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.deepPurple.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        "Avatars Premium",
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Débloque plus d'avatars dans la boutique !",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Affichage des avatars premium (indices 10-19)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final ownedAvatars = snapshot.hasData
                          ? List<int>.from(
                          snapshot.data!.get('ownedAvatars') ?? [0])
                          : [0];

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(
                            10, // Les 10 avatars premium
                                (i) {
                              final index = i + 10; // Indices 10-19
                              final isOwned = ownedAvatars.contains(index);

                              return GestureDetector(
                                onTap: isOwned
                                    ? () {
                                  setState(() {
                                    selectedAvatarIndex = index;
                                    selectedImage = null;
                                  });
                                }
                                    : null,
                                child: Opacity(
                                  opacity: isOwned ? 1.0 : 0.4,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selectedAvatarIndex == index
                                            ? Colors.amber
                                            : Colors.transparent,
                                        width: 4,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 35,
                                          backgroundImage: AssetImage(
                                            AvatarConstants.avatarAssets[index],
                                          ),
                                        ),
                                        if (!isOwned)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.lock,
                                                color: Colors.white70,
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Nom
            _inputField(
              controller: _nameController,
              hint: "Nom",
            ),

            const SizedBox(height: 16),

            // Username
            _inputField(
              controller: _usernameController,
              hint: "Pseudo",
              prefix: "@ ",
            ),

            const SizedBox(height: 30),

            // Bouton Enregistrer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Enregistrer",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    String? prefix,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        prefixStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}