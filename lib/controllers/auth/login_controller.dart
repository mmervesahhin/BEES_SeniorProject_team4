import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

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
        // Show loading indicator
        _showLoadingDialog(context, "Logging in...");

        // Attempt to sign in with Firebase
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: emailAddress,
          password: password,
        );

        // Dismiss loading dialog
        Navigator.of(context).pop();

        if (userCredential.user != null) {
          // Check if email is verified
          if (!userCredential.user!.emailVerified) {
            await _auth.signOut();
            _showVerificationDialog(context, emailAddress, password);
            return;
          }

          // Get user data from Firestore
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (userDoc.exists) {
            // Check if user is banned
            bool isBanned = userDoc.get('isBanned') ?? false;
            Timestamp? banEndDate = userDoc.get('banEndDate');

            if (isBanned) {
              if (banEndDate == null) {
                // Permanent ban
                _showBanDialog(context, true);
                await _auth.signOut();
                return;
              } else {
                DateTime banEndDateTime = banEndDate.toDate();
                if (DateTime.now().isBefore(banEndDateTime)) {
                  // Temporary ban still active
                  _showBanDialog(context, false, banEndDate: banEndDateTime);
                  await _auth.signOut();
                  return;
                } else {
                  // Ban period has ended, update user status
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userCredential.user!.uid)
                      .update({'isBanned': false, 'banEndDate': null});
                }
              }
            }

            // If all checks pass, navigate to appropriate screen
            bool isAdmin =
                userDoc.exists ? (userDoc.get('isAdmin') ?? false) : false;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    isAdmin ? AdminHomeScreen() : HomeScreen(),
              ),
            );
          } else {
            _showError(context, 'User data not found. Please contact support.');
          }
        } else {
          _showError(context, 'Login failed. Please try again.');
        }
      } on FirebaseAuthException catch (e) {
        // Dismiss loading dialog if it's showing
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Handle specific Firebase Auth errors
        String errorMessage = _getAuthErrorMessage(e.code);
        _showError(context, errorMessage);
      } catch (e) {
        // Dismiss loading dialog if it's showing
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        _showError(context, 'An unexpected error occurred. Please try again.');
      }
    }
  }

  // Password reset functionality
  Future<void> sendPasswordResetEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return; // Success - caller will show success dialog
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getPasswordResetErrorMessage(e.code);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Helper method to get specific auth error messages
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many unsuccessful login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password login is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-credential':
        return 'The credentials provided are invalid. Please try again.';
      default:
        return 'Authentication failed. Please check your credentials.';
    }
  }

  // Helper method to get specific password reset error messages
  String _getPasswordResetErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'missing-android-pkg-name':
      case 'missing-ios-bundle-id':
      case 'missing-continue-uri':
      case 'invalid-continue-uri':
      case 'unauthorized-continue-uri':
        return 'There was a configuration error. Please contact support.';
      default:
        return 'Failed to send password reset email. Please try again.';
    }
  }

  // Show email verification dialog
  void _showVerificationDialog(
      BuildContext context, String email, String password) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.email, color: Color(0xFFFFC857)),
              SizedBox(width: 10),
              Text(
                "Email Verification Required",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your email address has not been verified yet. Please check your inbox for a verification link.",
                style: GoogleFonts.nunito(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                "Didn't receive an email?",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "1. Check your spam folder\n2. Request a new verification email",
                style: GoogleFonts.nunito(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: GoogleFonts.nunito(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFC857),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                // Show loading indicator
                _showLoadingDialog(context, "Sending verification email...");

                try {
                  // Sign in the user again to get a fresh user object
                  UserCredential userCredential =
                      await _auth.signInWithEmailAndPassword(
                    email: email,
                    password: password,
                  );

                  if (userCredential.user != null) {
                    // Send verification email
                    await userCredential.user!.sendEmailVerification();

                    // Sign out the user after sending verification
                    await _auth.signOut();

                    // Close loading dialog and verification dialog
                    Navigator.of(context).pop(); // Close loading dialog
                    Navigator.of(context).pop(); // Close verification dialog

                    // Show success message
                    _showSuccess(context,
                        "Verification email sent to $email. Please check your inbox and spam folder.");
                  } else {
                    throw Exception("Failed to get user object");
                  }
                } on FirebaseAuthException catch (e) {
                  // Close loading dialog if it's showing
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }

                  // Handle specific errors
                  String errorMessage;
                  switch (e.code) {
                    case 'too-many-requests':
                      errorMessage =
                          "Too many verification attempts. Please try again later.";
                      break;
                    case 'user-not-found':
                      errorMessage =
                          "User account not found. Please register first.";
                      break;
                    case 'wrong-password':
                      errorMessage =
                          "Incorrect password. Please try logging in again.";
                      break;
                    default:
                      errorMessage =
                          "Failed to send verification email: ${e.message}";
                  }

                  // Close verification dialog
                  Navigator.of(context).pop();

                  // Show error message
                  _showError(context, errorMessage);
                } catch (e) {
                  // Close loading dialog if it's showing
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }

                  // Close verification dialog
                  Navigator.of(context).pop();

                  // Show error message
                  _showError(
                      context, "An unexpected error occurred: ${e.toString()}");
                }
              },
              child: Text(
                "Resend Verification",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show ban dialog
  void _showBanDialog(BuildContext context, bool isPermanent,
      {DateTime? banEndDate}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.red),
              SizedBox(width: 10),
              Text(
                "Account Suspended",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPermanent
                    ? "Your account has been permanently suspended for violating our terms of service."
                    : "Your account has been temporarily suspended.",
                style: GoogleFonts.nunito(fontSize: 16),
              ),
              SizedBox(height: 12),
              if (!isPermanent && banEndDate != null) ...[
                Text(
                  "Ban will be lifted on:",
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${banEndDate.day}/${banEndDate.month}/${banEndDate.year} at ${banEndDate.hour}:${banEndDate.minute.toString().padLeft(2, '0')}",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16),
              Text(
                "If you believe this is a mistake, please contact our support team.",
                style: GoogleFonts.nunito(fontSize: 16),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFC857),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "OK",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show error message
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.nunito(),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
      ),
    );
  }

  // Show success message
  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.nunito(),
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
      ),
    );
  }

  // Show loading dialog
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC857)),
                ),
                SizedBox(width: 20),
                Text(
                  message,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
