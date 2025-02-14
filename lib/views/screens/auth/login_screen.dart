import 'package:bees/views/screens/auth/register_screen.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bees/controllers/auth/login_controller.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LoginController _loginController = LoginController();

  String email = ''; 
  String password = ''; 
  bool _isPasswordVisible = false;

  //final FirebaseAuth _auth = FirebaseAuth.instance; // Instance of FirebaseAuth

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Static gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1B5E20),
                  Color(0xFF2E7D32),
                  Color(0xFF43A047),
                  Color(0xFF66BB6A),
                  Color(0xFF81C784),
                  Color(0xFFA5D6A7),
                  Color(0xFF81C784),
                  Color(0xFF66BB6A),
                  Color(0xFF43A047),
                  Color(0xFF2E7D32),
                  Color(0xFF1B5E20),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 3,
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "BEES",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Log in to your account",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Email input
                        TextFormField(
                          onChanged: (value) {
                            email = value;
                          },
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field is required';
                            }
                            final emailPattern = RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            );
                            if (!emailPattern.hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            // Trigger login when "Enter" is pressed in the email field
                            FocusScope.of(context).nextFocus();
                          },
                          decoration: InputDecoration(
                            hintText: 'Email Address',
                            prefixIcon: const Icon(Icons.email, color: Colors.green),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Colors.green,
                                width: 2,
                              ),
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),
                        const SizedBox(height: 20),
                        // Password input
                        TextFormField(
                          onChanged: (value) {
                            password = value;
                          },
                          controller: _passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field is required';
                            }
                            // final passwordPattern = RegExp(
                            //   r'^(?=.[A-Z])(?=.\d)(?=.*[\W_]).{8,16}$',
                            // );
                            // if (!passwordPattern.hasMatch(value)) {
                            //   return 'Invalid password';
                            // }
                            return null;
                          },
                          obscureText: !_isPasswordVisible,
                          onFieldSubmitted: (_) {
                            // Trigger login when "Enter" is pressed in the password field
                            _loginController.handleLogin(
                            emailAddress: email,
                            password: password,
                            formKey: _formKey,
                            context: context,
                          );

                          },
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock, color: Colors.green),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Colors.green,
                                width: 2,
                              ),
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),
                        const SizedBox(height: 25),
                        // Login button
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              // Login button
                              ElevatedButton(
                                onPressed: () {
                                    _loginController.handleLogin(
                                      emailAddress: email,
                                      password: password,
                                      formKey: _formKey,
                                      context: context,
                                    );
                                  },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                  backgroundColor: Colors.green[700],
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10), // Space between buttons
                              // Sign Up link
                              TextButton(
                                onPressed: () {
                                  // Navigate to the sign-up screen or perform action
                                  // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen()));
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                                  );
                                },
                                child: Text(
                                  'Don\'t have an account? Sign Up',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}