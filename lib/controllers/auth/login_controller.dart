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
        // E-posta doğrulaması yapılmadıysa, çıkış yap ve hata mesajı göster
        if (!userCredential.user!.emailVerified) {
          await _auth.signOut(); // Kullanıcıyı çıkart
          _showError(context, 'Please verify your email first!');
        } else {
          // Eğer doğrulama yapılmışsa, ana sayfaya yönlendir
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        _showError(context, 'Login failed. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Wrong email or invalid address.';
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

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}