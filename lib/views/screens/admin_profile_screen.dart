import 'package:bees/controllers/user_profile_controller.dart';
import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bees/models/request_model.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminProfileScreen extends StatefulWidget {
  @override
  _AdminProfileScreenState createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen>
    with TickerProviderStateMixin {
  final UserProfileController _controller = UserProfileController();
  late TabController _tabController;

  // Modern trading app color palette
  final Color primaryYellow = Color(0xFFFFC857);
  final Color secondaryYellow = Color(0xFFFFD166);
  final Color accentColor = Color(0xFF06D6A0);
  final Color backgroundColor = Colors.white;
  final Color cardColor = Colors.white;
  final Color textDark = Color(0xFF1F2937);
  final Color textMedium = Color(0xFF6B7280);
  final Color textLight = Color(0xFF8A8A8A);
  final Color errorColor = Color(0xFFEF4444);
  final Color successColor = Color(0xFF10B981);
  final Color borderColor = Color(0xFFE5E7EB);

  // Animation controller for profile stats
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Initialize scroll controller directly instead of using late
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.initializeUserData();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Initialize tab controller with a separate vsync
    _tabController = TabController(length: 2, vsync: this);

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showSnackBar(String message,
      {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : (isSuccess
                      ? Icons.check_circle_outline
                      : Icons.info_outline),
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? errorColor : (isSuccess ? successColor : primaryYellow),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(top: 16, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Text(
                          "Settings",
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, thickness: 1, color: borderColor),

                  // Settings list - make it scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSettingsCategory("Account"),
                          _buildSettingsListTile(
                            icon: Icons.lock_outline,
                            title: "Change Password",
                            subtitle: "Update your account password",
                            onTap: () {
                              Navigator.pop(context);
                              _showChangePasswordDialog();
                            },
                          ),
                          _buildSettingsListTile(
                            icon: Icons.email_outlined,
                            title: "Change Email Address",
                            subtitle: "Update your email address",
                            onTap: () {
                              Navigator.pop(context);
                              _showChangeEmailDialog();
                            },
                          ),
                          _buildSettingsCategory("Account Actions",
                              isDanger: true),
                          _buildSettingsListTile(
                            icon: Icons.logout,
                            title: "Log Out",
                            subtitle: "Sign out of your account",
                            isDestructive: true,
                            onTap: () {
                              Navigator.pop(context);
                              _logout();
                            },
                          ),
                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsCategory(String title, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDanger ? errorColor : primaryYellow,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: isDanger
                  ? errorColor.withOpacity(0.2)
                  : primaryYellow.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? errorColor.withOpacity(0.1)
              : primaryYellow.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive ? errorColor : primaryYellow,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDestructive ? errorColor : textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(
          fontSize: 13,
          color: textMedium,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive ? errorColor.withOpacity(0.5) : textMedium,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
              ),
              Text(
                "Profile Photo",
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              SizedBox(height: 24),
              _buildImagePickerOption(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              SizedBox(height: 16),
              _buildImagePickerOption(
                icon: Icons.camera_alt_outlined,
                title: 'Take a Picture',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_controller.currentProfilePictureUrl != null ||
                  _controller.image != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildImagePickerOption(
                    icon: Icons.delete_outline,
                    title: 'Remove Picture',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfilePicture();
                    },
                  ),
                ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isDestructive
              ? errorColor.withOpacity(0.05)
              : primaryYellow.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive
                ? errorColor.withOpacity(0.1)
                : primaryYellow.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? errorColor : primaryYellow,
              size: 24,
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDestructive ? errorColor : textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      await _controller.pickImage(source);
      setState(() {});
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _removeProfilePicture() async {
    try {
      bool success = await _controller.removeProfilePicture();
      if (success) {
        setState(() {});
        _showSnackBar('Profile picture removed successfully', isSuccess: true);
      } else {
        _showSnackBar('Error removing profile picture', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error removing profile picture', isError: true);
    }
  }

  Future<void> _saveProfile(User user) async {
    try {
      bool success = await _controller.saveProfile();
      if (success) {
        setState(() => _controller.isEditing = false);
        _showSnackBar('Profile updated successfully', isSuccess: true);
      } else {
        _showSnackBar('Error updating profile', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error updating profile', isError: true);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    _controller.currentPasswordController.clear();
    _controller.newPasswordController.clear();
    _controller.confirmPasswordController.clear();

    setState(() {
      _controller.currentPasswordVisible = false;
      _controller.newPasswordVisible = false;
      _controller.confirmPasswordVisible = false;
    });

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              'Change Password',
              style: GoogleFonts.nunito(
                color: textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _controller.passwordFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _controller.currentPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          labelStyle: GoogleFonts.nunito(
                              color: textMedium, fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryYellow, width: 1),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon:
                              Icon(Icons.lock_outline, color: textMedium),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _controller.currentPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: textMedium,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                _controller.currentPasswordVisible =
                                    !_controller.currentPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_controller.currentPasswordVisible,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Current password is required'
                            : null,
                        style: GoogleFonts.nunito(color: textDark),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _controller.newPasswordController,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: GoogleFonts.nunito(
                              color: textMedium, fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryYellow, width: 1),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon:
                              Icon(Icons.lock_outline, color: textMedium),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _controller.newPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: textMedium,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                _controller.newPasswordVisible =
                                    !_controller.newPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_controller.newPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'New password is required';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                        style: GoogleFonts.nunito(color: textDark),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _controller.confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          labelStyle: GoogleFonts.nunito(
                              color: textMedium, fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryYellow, width: 1),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon:
                              Icon(Icons.lock_outline, color: textMedium),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _controller.confirmPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: textMedium,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                _controller.confirmPasswordVisible =
                                    !_controller.confirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_controller.confirmPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _controller.newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        style: GoogleFonts.nunito(color: textDark),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This password will be used for future logins. Make sure to remember it or store it securely.',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: Colors.blue.shade700,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.nunito(
                    color: textMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_controller.passwordFormKey.currentState?.validate() ??
                      false) {
                    String? error = await _controller.changePassword();
                    if (error == null) {
                      Navigator.of(context).pop();
                      _showSnackBar('Password changed successfully',
                          isSuccess: true);
                    } else {
                      _showSnackBar(error, isError: true);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryYellow,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(
                  'Verify & Change',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showChangeEmailDialog() async {
    _controller.newEmailController.clear();
    _controller.currentPasswordController.clear();

    // Check if there's a pending email verification
    User? user = FirebaseAuth.instance.currentUser;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    String? pendingEmail = userData['pendingEmail'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Email Address',
          style: GoogleFonts.nunito(
            color: textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: pendingEmail != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.amber[700], size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You have a pending email change to: $pendingEmail\n\nPlease check your email and click the verification link to complete the change.',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: Colors.amber[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Resend verification email
                          _controller.resendEmailVerification(pendingEmail!);
                          Navigator.of(context).pop();
                          _showSnackBar(
                              'Verification email resent to $pendingEmail',
                              isSuccess: true);
                        },
                        icon: Icon(Icons.send, size: 18),
                        label: Text('Resend Verification Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryYellow,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () async {
                          // Cancel the pending email change
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user?.uid)
                              .update({
                            'pendingEmail': FieldValue.delete(),
                            'emailChangeRequestTime': FieldValue.delete(),
                          });
                          Navigator.of(context).pop();
                          _showSnackBar('Email change request cancelled');
                        },
                        icon: Icon(Icons.cancel_outlined, size: 18),
                        label: Text('Cancel Email Change'),
                        style: TextButton.styleFrom(
                          foregroundColor: errorColor,
                        ),
                      ),
                    ],
                  )
                : Form(
                    key: _controller.emailFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _controller.currentPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            labelStyle: GoogleFonts.nunito(
                                color: textMedium, fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: primaryYellow, width: 1),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            prefixIcon:
                                Icon(Icons.lock_outline, color: textMedium),
                          ),
                          obscureText: true,
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Password is required for verification'
                              : null,
                          style: GoogleFonts.nunito(color: textDark),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _controller.newEmailController,
                          decoration: InputDecoration(
                            labelText: 'New Email Address',
                            labelStyle: GoogleFonts.nunito(
                                color: textMedium, fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: primaryYellow, width: 1),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            prefixIcon:
                                Icon(Icons.email_outlined, color: textMedium),
                            helperText:
                                'Must be a Bilkent email (example@bilkent.edu.tr)',
                            helperStyle: GoogleFonts.nunito(
                                fontSize: 12, color: textMedium),
                            errorMaxLines: 4,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(
                                    r"^[a-zA-Z0-9._%+-]+@(?:ug\.)?bilkent\.edu\.tr$")
                                .hasMatch(value)) {
                              return 'Please enter a valid Bilkent email address';
                            }
                            return null;
                          },
                          style: GoogleFonts.nunito(color: textDark),
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade700, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'A verification email will be sent to the new address. Your email will only be updated after you verify the new address and log in again.',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: pendingEmail != null
            ? [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.nunito(
                      color: textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.nunito(
                      color: textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_controller.emailFormKey.currentState?.validate() ??
                        false) {
                      String? error = await _controller.changeEmail();
                      if (error == null) {
                        // Start checking for email verification
                        _controller.startEmailVerificationCheck();
                        Navigator.of(context).pop();
                        _showSnackBar(
                            'Verification email sent to ${_controller.newEmailController.text}. Please check your inbox and verify the new email address.',
                            isSuccess: true);
                      } else {
                        _showSnackBar(error, isError: true);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(
                    'Send Verification',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
      ),
    );
  }

  Future<void> _logout() async {
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: errorColor),
              SizedBox(width: 8),
              Text(
                "Log Out",
                style: GoogleFonts.nunito(
                  color: errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to log out?",
            style: GoogleFonts.nunito(color: textDark),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Cancel",
                style: GoogleFonts.nunito(
                  color: textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: Text(
                "Log Out",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      try {
        bool success = await _controller.signOut();
        if (success) {
          _controller.navigateToLogin(context);
        } else {
          _showSnackBar("Error logging out", isError: true);
        }
      } catch (e) {
        _showSnackBar("Error logging out: ${e.toString()}", isError: true);
      }
    }
  }

  Widget _buildProfileHeader(User user, Map<String, dynamic> userData) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: backgroundColor,
      child: Column(
        children: [
          // Profile picture and edit button
          Stack(
            children: [
              GestureDetector(
                onTap: _controller.isEditing ? _showImagePickerOptions : null,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryYellow, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: _controller.image != null
                        ? Image.file(
                            _controller.image!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : (_controller.currentProfilePictureUrl != null &&
                                _controller.currentProfilePictureUrl!.isNotEmpty
                            ? Image.network(
                                _controller.currentProfilePictureUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                primaryYellow),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: Icon(Icons.person,
                                        color: Colors.grey, size: 50),
                                  );
                                },
                              )
                            : Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[200],
                                child: Icon(Icons.person,
                                    color: Colors.grey, size: 50),
                              )),
                  ),
                ),
              ),
              if (_controller.isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: primaryYellow,
                      radius: 16,
                      child: Icon(Icons.camera_alt_outlined,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),

          // User name
          Text(
            "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}",
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),

          // User email
          Text(
            userData['emailAddress'] ?? 'No email',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: textMedium,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),

          // Admin badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryYellow),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings,
                    color: primaryYellow, size: 16),
                SizedBox(width: 4),
                Text(
                  "Administrator",
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryYellow,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Edit profile button
          if (_controller.isEditing)
            _buildEditProfileForm()
          else
            ElevatedButton.icon(
              onPressed: () => setState(() => _controller.isEditing = true),
              icon: Icon(Icons.edit_outlined, size: 18),
              label: Text("Edit Profile"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditProfileForm() {
    return Column(
      children: [
        Form(
          key: _controller.formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _controller.firstNameController,
                decoration: InputDecoration(
                  labelText: "First Name",
                  labelStyle: GoogleFonts.nunito(color: textMedium),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryYellow, width: 1),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(Icons.person_outline, color: textMedium),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
                style: GoogleFonts.nunito(color: textDark),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _controller.lastNameController,
                decoration: InputDecoration(
                  labelText: "Last Name",
                  labelStyle: GoogleFonts.nunito(color: textMedium),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryYellow, width: 1),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(Icons.person_outline, color: textMedium),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
                style: GoogleFonts.nunito(color: textDark),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _controller.isEditing = false),
              style: OutlinedButton.styleFrom(
                foregroundColor: textMedium,
                side: BorderSide(color: borderColor),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Cancel",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: () => _saveProfile(FirebaseAuth.instance.currentUser!),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Save",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? firebaseUser = _controller.model.currentUser;
    if (firebaseUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: 24),
              Text(
                "User not found",
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  color: textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Please sign in to continue",
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: textMedium,
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  _controller.navigateToLogin(context);
                },
                icon: Icon(Icons.login, size: 18),
                label: Text("Go to Login"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryYellow,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'BEES ',
                  style: GoogleFonts.nunito(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryYellow,
                  ),
                ),
                TextSpan(
                  text: 'admin',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: primaryYellow,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textDark),
            onPressed: _showSettingsMenu,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                strokeWidth: 2,
              ),
            );
          }
          if (!snapshot.hasData ||
              snapshot.data == null ||
              !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: 24),
                  Text(
                    "User data not found",
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      color: textDark,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Please complete your profile",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          _controller.firstNameController.text = userData['firstName'] ?? '';
          _controller.lastNameController.text = userData['lastName'] ?? '';
          _controller.currentProfilePictureUrl = userData['profilePicture'];

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(firebaseUser, userData),
                SizedBox(height: 16),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Admin Information",
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryYellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings,
                                color: primaryYellow, size: 24),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Administrator Access",
                                    style: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "You have full administrative privileges to manage the BEES platform",
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      color: textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4, // şu anki sayfa Profile ise bu 4 olmalı
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryYellow,
        unselectedItemColor: textLight,
        selectedLabelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontSize: 12,
        ),
        iconSize: 22,
        elevation: 8,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.shop),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AdminHomeScreen(),
              ));
              break;
            case 1:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AdminRequestsScreen(),
              ));
              break;
            case 2:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AdminReportsScreen(),
              ));
              break;
            case 3:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AdminDataAnalysisScreen(),
              ));
              break;
            case 4:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AdminProfileScreen(),
              ));
              break;
          }
        },
      ),
    );
  }
}
