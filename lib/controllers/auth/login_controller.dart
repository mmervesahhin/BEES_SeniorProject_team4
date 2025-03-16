import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bees/views/screens/home_screen.dart';

class LoginController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

Future<void> handleLogin({
  required String emailAddress,
  required String password,
  required GlobalKey<FormState> formKey,
  required BuildContext context,
}) async {
  if (formKey.currentState?.validate() == true) {
    try {
      // Firebase ile giriş yapmayı dene
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );

        if (userCredential.user != null) {
          // Firestore'dan kullanıcının isAdmin olup olmadığını al
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          bool isAdmin = userDoc.exists ? (userDoc.get('isAdmin') ?? false) : false;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => isAdmin ?  AdminHomeScreen() : HomeScreen(),
            ),
          );
        } else {
          _showError(context, 'Login failed. Please try again.');
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Wrong password or invalid address.';
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Incorrect password.';
        }
        _showError(context, errorMessage);
      } catch (e) {
        _showError(context, 'An unexpected error occurred. Please try again.');
      }
    }
  }

  // Add this method to handle password reset
  Future<void> sendPasswordResetEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password reset link sent to $email."),
          backgroundColor: Colors.green[700],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send password reset email.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email address.';
      }
      _showError(context, errorMessage);
    } catch (e) {
      _showError(context, 'An unexpected error occurred. Please try again.');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}