import 'package:flutter/material.dart';
import 'package:bees/views/screens/auth/register_screen.dart';
import 'package:bees/controllers/auth/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LoginController _loginController = LoginController();

  String email = '';
  String password = '';
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 59, 137, 62)!,
                  Colors.green[500]!,
                  Colors.green[300]!,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.hive,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "BEES",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Log in to your account",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _emailController,
                                hintText: 'Email Address',
                                icon: Icons.email,
                                onChanged: (value) => email = value,
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _passwordController,
                                hintText: 'Password',
                                icon: Icons.lock,
                                isPassword: true,
                                onChanged: (value) => password = value,
                                validator: _validatePassword,
                              ),
                              const SizedBox(height: 24),
                              _buildLoginButton(),
                              const SizedBox(height: 16),
                              _buildSignUpLink(),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    required Function(String) onChanged,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.green[700]),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _loginController.handleLogin(
          emailAddress: email,
          password: password,
          formKey: _formKey,
          context: context,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.green[700],
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        child: const Text(
          'Log In',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return TextButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const RegistrationScreen()),
  ),
  child: Text.rich(
    TextSpan(
      text: "Don't have an account? ",
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      children: [
        TextSpan(
          text: "Sign Up",
          style: TextStyle(
            fontWeight: FontWeight.bold, // Make only "Sign Up" bold
          ),
        ),
      ],
    ),
  ),
);
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailPattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailPattern.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    // Add more password validation if needed
    return null;
  }
}