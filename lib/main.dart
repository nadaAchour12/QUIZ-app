import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizmaster/screens/onBoarding/splash_screen.dart';
import 'firebase_options.dart';
import 'home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ NE PAS utiliser Platform sur le web
  if (!kIsWeb) {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('platform thread')) {
        debugPrint('Ignoré: ${details.exception}');
        return;
      }
      FlutterError.presentError(details);
    };
  }

  // ✅ Firebase initialisé AVANT runApp
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint("🔥 Firebase initialisé");

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuizMaster',
      theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor:
          const Color(0xFF0A1E2F),
          primaryColor: Colors.cyan),
      home: const AuthCheck(),
    );
  }
}
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.cyan))
            );
          }
          if (snapshot.hasData) {
            final uid = snapshot.data!.uid;
            // Vérifie si l'utilisateur a déjà complété l'onboarding
            return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator(color: Colors.cyan)));
                  }
                  final data = userSnap.data!.data() as Map<String, dynamic>?;
                  final bool onboarded = data?['onboarded'] == true;
                   // if (onboarded) {
                   //    return const HomeScreen();
                   //    // Directement à l'accueil //
                   // } else {
                   //    return const ProfileSetupScreen();
                   //    // Demande les infos //
                   // }
                  return HomeScreen();
                   },
            );
          }
          // Pas connecté du tout → commence par le splash
          return const SplashScreen();
          },
    );
  }
}

