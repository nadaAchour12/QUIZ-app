// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Pour debugPrint

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Inscription anonyme + création du profil utilisateur avec coins à 0
  Future<User?> signUp({
    required String name,
    required int age,
    required String username,
  }) async {
    try {
      UserCredential cred = await _auth.signInAnonymously();
      final uid = cred.user!.uid;

      await _db.collection('users').doc(uid).set({
        'name': name.trim(),
        'age': age,
        'username': username.trim().toLowerCase(),
        'onboarded': true,
        'createdAt': FieldValue.serverTimestamp(),
        'coins': 0,
        'dailyScore': 0,
        'avatarIndex': 0,
        'avatarUrl': null,
      }, SetOptions(merge: true));

      debugPrint("Utilisateur créé avec succès : $uid");
      return cred.user;
    } catch (e) {
      debugPrint("Erreur lors de l'inscription : $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint("Déconnexion réussie");
    } catch (e) {
      debugPrint("Erreur déconnexion : $e");
    }
  }

  Stream<User?> authState() => _auth.authStateChanges();

  /// Ajouter des coins
  Future<void> addCoins(int amount) async {
    final user = _auth.currentUser;
    if (user == null || amount <= 0) return;

    try {
      await _db.collection('users').doc(user.uid).update({
        'coins': FieldValue.increment(amount),
      });
      debugPrint("+$amount coins ajoutés");
    } catch (e) {
      debugPrint("Erreur ajout coins : $e");
    }
  }

  /// Récupérer les coins
  Future<int> getCoins() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      return (doc.data()?['coins'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint("Erreur lecture coins : $e");
      return 0;
    }
  }
}