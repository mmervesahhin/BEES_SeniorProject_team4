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
        // E-posta doğrulaması yapılmadıysa, çıkış yap ve hata mesajı göster
        if (!userCredential.user!.emailVerified) {
          await _auth.signOut();
          _showError(context, 'Please verify your email first!');
          return;
        }

        // Firestore'dan kullanıcının bilgilerini al
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          bool isBanned = userDoc.get('isBanned') ?? false;
          Timestamp? banEndDate = userDoc.get('banEndDate');

          if (isBanned) {
            if (banEndDate == null) {
              _showError(context, 'Your account is banned permanently.');
              await _auth.signOut();
              return;
            } else {
              DateTime banEndDateTime = banEndDate.toDate();
              if (DateTime.now().isBefore(banEndDateTime)) {
                _showError(context, 'Your account is banned temporarily.');
                await _auth.signOut();
                return;
              } else {
                // Ban süresi dolduysa isBanned'i false yap ve banEndDate'i null'a ayarla
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userCredential.user!.uid)
                    .update({'isBanned': false, 'banEndDate': null});
              }
            }
          }
        }

        // Eğer doğrulama ve ban kontrolü geçildiyse, ana sayfaya yönlendir
        bool isAdmin = userDoc.exists ? (userDoc.get('isAdmin') ?? false) : false;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isAdmin ? AdminHomeScreen() : HomeScreen(),
          ),
        );
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