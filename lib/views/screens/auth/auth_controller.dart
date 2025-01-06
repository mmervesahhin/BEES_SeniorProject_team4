import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Login method
  Future<String> handleLogin(String email, String password) async {
    try {
      // Attempt to sign in with email and password
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return 'Login successful.';
    } on FirebaseAuthException catch (e) {
      // Handle different FirebaseAuthException errors
      if (e.code == 'wrong-password') {
        return 'Invalid password.';
      } else if (e.code == 'user-not-found') {
        return 'Email is not registered.';
      } else if (e.code == 'too-many-requests') {
        return 'Too many attempts. Please try again later.';
      }
      return 'An unexpected error occurred. Please try again.';
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Register new user
  Future<String> registerUser(String email, String password) async {
    try {
      // Attempt to create a new user with email and password
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return 'User registered successfully.';
    } on FirebaseAuthException catch (e) {
      // Handle registration errors
      if (e.code == 'email-already-in-use') {
        return 'Email is already in use.';
      } else if (e.code == 'weak-password') {
        return 'Password is too weak.';
      }
      return 'An unexpected error occurred. Please try again.';
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Logout user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Check if email is registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: 'dummyPassword');
      return true; // Email is registered
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return false; // Email is not registered
      }
      return false; // Other errors
    } catch (e) {
      return false; // Other unexpected errors
    }
  }

  // Check if password is correct
  Future<bool> isPasswordCorrect(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true; // Password is correct
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return false; // Password is incorrect
      }
      rethrow; // Rethrow other exceptions
    }
  }
}
