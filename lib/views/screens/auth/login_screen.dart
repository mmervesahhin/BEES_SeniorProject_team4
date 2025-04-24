import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bees/views/screens/auth/register_screen.dart';
import 'package:bees/controllers/auth/login_controller.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Define our brand colors
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

void showSuccessPopup(BuildContext context, String email) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Color(0xFFFFC857),
                size: 60,
              ),
              SizedBox(height: 16),
              Text(
                "Success!",
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Password reset link sent to\n$email",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFC857),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text(
                    "OK",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Top-right yellow shape
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: lightYellow,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(100),
                ),
              ),
            ),
          ),
          
          // Bottom-left yellow shape
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: primaryYellow,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(150),
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Login to BEES",
                            style: GoogleFonts.montserrat(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Please sign in to continue.",
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: textLight,
                            ),
                          ),
                          SizedBox(height: 30),
                          
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email field
                                Text(
                                  "EMAIL",
                                  style: GoogleFonts.workSans(
                                    fontSize: 12,
                                    color: textLight,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 8),
                                _buildTextField(
                                  controller: _emailController,
                                  hintText: 'Email Address',
                                  icon: Icons.email_outlined,
                                  onChanged: (value) => email = value,
                                  validator: _validateEmail,
                                  isPassword: false,
                                ),
                                SizedBox(height: 20),
                                
                                // Password field with forgot link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "PASSWORD",
                                      style: GoogleFonts.workSans(
                                        fontSize: 12,
                                        color: textLight,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _showForgotPasswordDialog(context);
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size(0, 20),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        "FORGOT PASSWORD",
                                        style: GoogleFonts.workSans(
                                          color: primaryYellow,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                _buildTextField(
                                  controller: _passwordController,
                                  hintText: '••••••••',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  onChanged: (value) => password = value,
                                  validator: _validatePassword,
                                ),
                                SizedBox(height: 30),
                                
                                // Login button
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildLoginButton(),
                                ),
                                
                                SizedBox(height: 30),
                                
                                // Sign up link
                                Center(
                                  child: _buildSignUpLink(),
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
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.nunito(
        color: textDark,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.nunito(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: textLight, size: 18),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: textLight,
                  size: 18,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryYellow),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
        errorStyle: GoogleFonts.nunito(
          color: Colors.red[400],
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 44,
      child: ElevatedButton(
        onPressed: () => _loginController.handleLogin(
          emailAddress: email,
          password: password,
          formKey: _formKey,
          context: context,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          padding: EdgeInsets.symmetric(horizontal: 30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LOGIN',
              style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 16),
          ],
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
          style: GoogleFonts.nunito(
            color: textLight,
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: "Sign up",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: primaryYellow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Forgot Password Dialog
  void _showForgotPasswordDialog(BuildContext context) {
    final _forgotPasswordFormKey = GlobalKey<FormState>();
    final _forgotPasswordEmailController = TextEditingController();
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Reset Password",
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
              content: Form(
                key: _forgotPasswordFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Enter your email address to receive a password reset link.",
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: textLight,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _forgotPasswordEmailController,
                      decoration: InputDecoration(
                        hintText: "Email Address",
                        hintStyle: GoogleFonts.nunito(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(Icons.email_outlined, color: textLight),
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryYellow),
                        ),
                      ),
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: GoogleFonts.nunito(
                        color: textDark,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.nunito(
                      color: textLight,
                      fontSize: 14,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_forgotPasswordFormKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            try {
                              // Send password reset email using Firebase
                              await FirebaseAuth.instance.sendPasswordResetEmail(
                                email: _forgotPasswordEmailController.text.trim(),
                              );
                              
                              Navigator.pop(context);
                              
                              showSuccessPopup(context, _forgotPasswordEmailController.text);
                            } catch (e) {
                              setState(() {
                                _isLoading = false;
                              });
                              
                              // Show error message
                              String errorMessage = "Failed to send password reset email";
                              
                              if (e.toString().contains('user-not-found')) {
                                errorMessage = "No user found with this email address";
                              } else if (e.toString().contains('invalid-email')) {
                                errorMessage = "Invalid email format";
                              }
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    errorMessage,
                                    style: GoogleFonts.nunito(),
                                  ),
                                  backgroundColor: Colors.red[400],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: EdgeInsets.all(16),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          "Send Link",
                          style: GoogleFonts.workSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}


// Simplified validation messages to match the clean design
String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  final passwordPattern = RegExp(
    r"^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+{}\[\]:;<>,.?~\\/-]).{8,}$"
  );
  if (!passwordPattern.hasMatch(value)) {
    return 'Password does not meet requirements';
  }
  return null;
}

String? _validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  final emailPattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  if (!emailPattern.hasMatch(value)) {
    return 'Please enter a valid Bilkent email address';
  }
  return null;
}