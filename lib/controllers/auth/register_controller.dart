import 'package:bees/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:bees/views/screens/auth/login_screen.dart';
import 'package:bcrypt/bcrypt.dart'; // Importing bcrypt package
import 'package:bees/models/user_model.dart' as bees;

class RegisterController {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final BuildContext context;

  RegisterController({
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.context,
  });

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@(?:ug\.)?bilkent\.edu\.tr$").hasMatch(value)) {
      return 'Enter a valid Bilkent email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8 || value.length > 16) {
      return 'Password must be between 8 and 16 characters';
    }
    if (!RegExp("^(?=.*[A-Z])(?=.*\\d)(?=.*[!\"#\$%&'()*+,-./:;<=>?@[\\]^_`{|}~]).{8,}\$").hasMatch(value)) {
      return 'Password must be at least 8 characters long and contain at least one uppercase letter, one digit, and one special character.';}
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length < 2 || value.length > 16) {
      return 'Name must be between 2 and 16 characters';
    }
    return null;
  }

void submitForm() async {
  if (formKey.currentState?.validate() ?? false) {
    try {
      // Kullanıcıyı Firebase Auth'ta oluştur
      auth.UserCredential userCredential = await auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      auth.User? user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification email sent! Please check your inbox.')),
        );

        // **Kullanıcıyı çıkış yaptır**
        await auth.FirebaseAuth.instance.signOut();

        bool isVerified = false;
        while (!isVerified) {
          await Future.delayed(Duration(seconds: 3)); // 3 saniye bekleyerek Firebase'e yük bindirmeyelim

          try {
            // Kullanıcıyı tekrar giriş yaptır ve kontrol et
            auth.UserCredential reLoginCredential = await auth.FirebaseAuth.instance.signInWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );

            auth.User? reUser = reLoginCredential.user;
            if (reUser != null) {
              await reUser.reload(); // **Kullanıcı verisini güncelle**
              if (reUser.emailVerified) {
                isVerified = true;
              } else {
                await auth.FirebaseAuth.instance.signOut(); // Hâlâ doğrulanmadıysa çıkış yap
              }
            }
          } catch (e) {
            print("Re-login failed: $e"); // Hata olursa terminale yaz
          }
        }

        // 🔥 Kullanıcı doğrulandıysa Firestore’a ekle
        String hashedPassword = BCrypt.hashpw(passwordController.text, BCrypt.gensalt());

        User newUser = User(
          userID: user.uid,
          firstName: firstNameController.text,
          lastName: lastNameController.text,
          emailAddress: emailController.text,
          hashedPassword: hashedPassword,
          profilePicture: '',
          userRating: 0.0,
          accountStatus: 'active',
          isAdmin: false,
          favoriteItems: [],
        );

        await FirebaseFirestore.instance.collection('users').doc(newUser.userID).set(newUser.toMap());

        // **Başarılı kayıt sonrası giriş ekranına yönlendir**
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register: $e')),
      );
    }
  }
}
}
