
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Access Firebase lazily, only when an operation is needed.
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Listen to login and logout changes.
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  // Register a new learner.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Login an existing learner.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Logout the current learner.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
