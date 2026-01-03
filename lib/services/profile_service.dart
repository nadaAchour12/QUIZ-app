import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String get uid => _auth.currentUser!.uid;

  Future<Map<String, dynamic>> getProfileData() async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final historySnap = await _firestore
        .collection('quiz_history')
        .where('userId', isEqualTo: uid)
        .get();

    int totalXP = 0;
    int wins = 0;

    for (var doc in historySnap.docs) {
      totalXP += (doc['xp'] as num).toInt();
      if (doc['score'] >= 50) wins++;
    }

    final games = historySnap.docs.length;
    final winRate = games == 0 ? 0 : ((wins / games) * 100).round();

    return {
      'username': userDoc['username'],
      'avatar': userDoc['avatar'],
      'age': userDoc['age'],
      'xp': totalXP,
      'games': games,
      'winRate': winRate,
    };
  }
}
