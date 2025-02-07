import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:bees/views/screens/auth/login_screen.dart';
import 'package:bcrypt/bcrypt.dart'; // Importing bcrypt package
import 'package:bees/models/user.dart';

class RegisterController {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final BuildContext context;
  bool termsAccepted = false;

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
    if (!RegExp(r"(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*])").hasMatch(value)) {
      return 'Password must contain at least one uppercase letter, one digit, and one special character';
    }
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
    if (!termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must accept the terms and conditions')),
      );
      return;
    }

    try {
      // Hash the password
       String hashedPassword = BCrypt.hashpw(passwordController.text, BCrypt.gensalt());

      // Create a new User object
      User newUser = User(
        userID: auth.FirebaseAuth.instance.currentUser?.uid ?? '',  // Get the user ID from Firebase Auth
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        emailAddress: emailController.text,
        hashedPassword: hashedPassword,
        profilePicture: '',  // Default or empty, could be updated later
        userRating: 0.0,      // Default rating, can be updated later
        accountStatus: 'active',  // Default status
      );

      // Save user data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(newUser.userID).set(newUser.toMap());

      // Optionally, you can also update the user's profile picture here after registration
      // For example, if they uploaded a profile picture.

      // Send email verification
      auth.UserCredential userCredential = await auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      auth.User? user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification email sent! Please check your inbox.')),
        );
      }

      // Navigate to Login screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register: $e')),
      );
    }
  }
}
}