import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  // ✅ 5 avatars depuis assets
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
    _loadUserData();
  }

  // 🔄 Charger données utilisateur
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

  // 📸 Choisir image depuis téléphone
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

  // ☁️ Upload image vers Firebase Storage
  Future<String?> uploadAvatar(File image) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('avatars')
        .child('${user!.uid}.jpg');

    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  // 💾 Sauvegarder profil
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

    Navigator.pop(context);
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

            // 👤 AVATAR IMAGE (photo perso ou avatar prédéfini)
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
                    avatarAssets[selectedAvatarIndex],
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

            // 🎭 CHOIX DES 5 AVATARS PRÉDÉFINIS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(avatarAssets.length, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAvatarIndex = index;
                        selectedImage = null; // Désactive la photo perso
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
                        backgroundImage: AssetImage(avatarAssets[index]),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 30),

            // ✏️ NOM
            _inputField(
              controller: _nameController,
              hint: "Nom",
            ),

            const SizedBox(height: 16),

            // ✏️ USERNAME
            _inputField(
              controller: _usernameController,
              hint: "Pseudo",
              prefix: "@ ",
            ),

            const SizedBox(height: 30),

            // 💾 SAVE
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

  // ===== INPUT =====
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