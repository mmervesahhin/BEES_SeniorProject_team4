import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'register_screen.dart'; // Import the registration screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Registration App',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: RegistrationScreen(), // Set RegistrationScreen as the initial screen
    );
  }
}
