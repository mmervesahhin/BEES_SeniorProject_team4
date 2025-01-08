import 'dart:io';

import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/auth/register_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
//import 'views/screens/item_upload.dart';
import 'views/screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Check if Firebase is already initialized
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyA5R4lMmDbLPDo_JnWH39FwPlniSiEjDGo',
        appId: '1:819551270360:android:f1bc026a801070a6522ead',
        messagingSenderId: '819551270360',
        projectId: 'bees-a5c0c',
        storageBucket: 'gs://bees-a5c0c.firebasestorage.app',
      ),
    );
  } catch (e) {
    // If Firebase is already initialized, this will handle the error
    print('Firebase already initialized: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}