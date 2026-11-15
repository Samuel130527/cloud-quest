import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/quest_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Connect to the local Firebase Authentication emulator.
  await FirebaseAuth.instance.useAuthEmulator(
    '127.0.0.1',
    9099,
    automaticHostMapping: false,
  );

  // Connect to the local Firestore emulator.
  FirebaseFirestore.instance.useFirestoreEmulator(
    '127.0.0.1',
    8080,
    automaticHostMapping: false,
  );

  // Connect to the local Cloud Functions emulator.
  FirebaseFunctions.instance.useFunctionsEmulator(
    '127.0.0.1',
    5001,
    automaticHostMapping: false,
  );

  runApp(const CloudQuestApp());
}


class CloudQuestApp extends StatelessWidget {
  const CloudQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloud Quest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          return QuestScreen(email: user.email ?? 'Learner');
        }

        return const AuthScreen();
      },
    );
  }
}
