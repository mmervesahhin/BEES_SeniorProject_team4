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

class AdminProfileScreen extends StatefulWidget {
  @override
  _AdminProfileScreenState createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final UserProfileController _controller = UserProfileController();
  
  @override
  void initState() {
    super.initState();
    _controller.initializeUserData();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? _controller.model.errorColor : _controller.model.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
        elevation: 4,
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: _controller.model.cardColor,
      elevation: 8,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Account Settings",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _controller.model.primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 24),
              _buildSettingsListTile(
                icon: Icons.lock,
                title: "Change Password",
                onTap: () {
                  Navigator.pop(context);
                  _showChangePasswordDialog();
                },
              ),
              Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
              _buildSettingsListTile(
                icon: Icons.email,
                title: "Change Email Address",
                onTap: () {
                  Navigator.pop(context);
                  _showChangeEmailDialog();
                },
              ),
              Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
              SizedBox(height: 8),
              _buildSettingsListTile(
                icon: Icons.exit_to_app,
                title: "Log Out",
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? _controller.model.errorColor.withOpacity(0.1) : _controller.model.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? _controller.model.errorColor : _controller.model.primaryColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDestructive ? _controller.model.errorColor : _controller.model.textColor,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDestructive ? _controller.model.errorColor.withOpacity(0.5) : Colors.grey.shade400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
    );
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: _controller.model.cardColor,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Profile Photo",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _controller.model.textColor,
                ),
              ),
              SizedBox(height: 16),
              _buildImagePickerOption(
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              SizedBox(height: 8),
              _buildImagePickerOption(
                icon: Icons.camera_alt,
                title: 'Take a Picture',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_controller.currentProfilePictureUrl != null || _controller.image != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildImagePickerOption(
                    icon: Icons.delete,
                    title: 'Remove Picture',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfilePicture();
                    },
                  ),
                ),
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
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDestructive ? _controller.model.errorColor.withOpacity(0.05) : Colors.grey.shade50,
          border: Border.all(
            color: isDestructive ? _controller.model.errorColor.withOpacity(0.2) : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? _controller.model.errorColor.withOpacity(0.1) : _controller.model.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive ? _controller.model.errorColor : _controller.model.primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? _controller.model.errorColor : _controller.model.textColor,
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
        _showSnackBar('Profile picture removed successfully');
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
        _showSnackBar('Profile updated successfully');
      } else {
        _showSnackBar('Error updating profile', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error updating profile', isError: true);
    }
  }

  Future<void> _showEditRequestDialog(BuildContext context, Request request) async {
    final TextEditingController contentController = TextEditingController(text: request.requestContent);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Request',
          style: TextStyle(
            color: _controller.model.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: contentController,
                decoration: InputDecoration(
                  labelText: 'Request Content',
                  labelStyle: TextStyle(color: Colors.grey.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _controller.model.primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _controller.model.errorColor, width: 1),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Content is required' : null,
                style: TextStyle(color: _controller.model.textColor),
              ),
            ],
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
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  bool success = await _controller.updateRequestContent(
                    request.requestID, 
                    contentController.text
                  );
                  Navigator.of(context).pop();
                  if (success) {
                    _showSnackBar('Request updated successfully');
                  } else {
                    _showSnackBar('Error updating request', isError: true);
                  }
                } catch (e) {
                  _showSnackBar('Error updating request', isError: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _controller.model.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
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
              style: TextStyle(
                color: _controller.model.primaryColor,
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
                          labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _controller.model.primaryColor, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _controller.model.errorColor, width: 1),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _controller.currentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                _controller.currentPasswordVisible = !_controller.currentPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_controller.currentPasswordVisible,
                        validator: (value) => value?.isEmpty ?? true ? 'Current password is required' : null,
                        style: TextStyle(color: _controller.model.textColor, fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _controller.newPasswordController,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _controller.model.primaryColor, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _controller.model.errorColor, width: 1),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: Icon(Icons.lock, color: Colors.grey.shade600, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _controller.newPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                _controller.newPasswordVisible = !_controller.newPasswordVisible;
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
                        style: TextStyle(color: _controller.model.textColor, fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _controller.confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _controller.model.primaryColor, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _controller.model.errorColor, width: 1),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: Icon(Icons.lock, color: Colors.grey.shade600, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _controller.confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                _controller.confirmPasswordVisible = !_controller.confirmPasswordVisible;
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
                        style: TextStyle(color: _controller.model.textColor, fontSize: 14),
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
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_controller.passwordFormKey.currentState?.validate() ?? false) {
                    String? error = await _controller.changePassword();
                    if (error == null) {
                      Navigator.of(context).pop();
                      _showSnackBar('Password changed successfully');
                    } else {
                      _showSnackBar(error, isError: true);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _controller.model.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text('Verify & Change', style: TextStyle(fontSize: 13)),
              ),
            ],
            contentPadding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          );
        },
      ),
    );
  }

  Future<void> _showChangeEmailDialog() async {
    _controller.newEmailController.clear();
    _controller.currentPasswordController.clear();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Email Address',
          style: TextStyle(
            color: _controller.model.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        content: Form(
          key: _controller.emailFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _controller.currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _controller.model.primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _controller.model.errorColor, width: 1),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
                ),
                obscureText: true,
                validator: (value) => value?.isEmpty ?? true ? 'Password is required for verification' : null,
                style: TextStyle(color: _controller.model.textColor),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _controller.newEmailController,
                decoration: InputDecoration(
                  labelText: 'New Email Address',
                  labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _controller.model.primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _controller.model.errorColor, width: 1),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
                  helperText: "Must be a Bilkent email (example@bilkent.edu.tr or example@ug.bilkent.edu.tr)",
                  helperStyle: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  errorMaxLines: 4,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r"^[a-zA-Z0-9._%+-]+@(?:ug\.)?bilkent\.edu\.tr$").hasMatch(value)) {
                    return 'Please enter a valid Bilkent email address';
                  }
                  return null;
                },
                style: TextStyle(color: _controller.model.textColor),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A verification email will be sent to the new address. Your email will only be updated after you verify the new address. Please check your spam folder if you don\'t see the email.',
                        style: TextStyle(
                          fontSize: 12,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_controller.emailFormKey.currentState?.validate() ?? false) {
                String? error = await _controller.changeEmail();
                if (error == null) {
                  Navigator.of(context).pop();
                  _showSnackBar('Verification email sent to ${_controller.newEmailController.text}. Please check your inbox and verify the new email address before the change takes effect.');
                } else {
                  _showSnackBar(error, isError: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _controller.model.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Send Verification'),
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
          title: Text(
            "Log Out",
            style: TextStyle(
              color: _controller.model.errorColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to log out?",
            style: TextStyle(color: _controller.model.textColor),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey.shade700),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: Text("Log Out"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _controller.model.errorColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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

  Widget _buildChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _controller.model.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _controller.model.primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: _controller.model.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    if (title == "Email") {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _controller.model.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: _controller.model.primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: _controller.model.lightTextColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _controller.model.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _controller.model.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: _controller.model.primaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: _controller.model.lightTextColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _controller.model.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 16),
              Text(
                "User not found.",
                style: TextStyle(
                  fontSize: 18,
                  color: _controller.model.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _controller.navigateToLogin(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _controller.model.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text("Go to Login"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _controller.model.backgroundColor,
      appBar: AppBar(
        backgroundColor: _controller.model.primaryColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
            children: [
            RichText(
              text: TextSpan(
              children: [
                TextSpan(
                text: 'BEES ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _controller.model.accentColor,
                ),
                ),
                TextSpan(
                text: 'admin',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.yellow,
                ),
                ),
              ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: _showSettingsMenu,
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_controller.model.primaryColor),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "User data not found. Please complete your profile.",
                    style: TextStyle(
                      fontSize: 16,
                      color: _controller.model.textColor,
                      fontWeight: FontWeight.w500,
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
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: _controller.model.primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: _controller.isEditing ? _showImagePickerOptions : null,
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 55,
                                backgroundImage: _controller.image != null
                                  ? FileImage(_controller.image!) as ImageProvider
                                  : (_controller.currentProfilePictureUrl != null && _controller.currentProfilePictureUrl!.isNotEmpty
                                      ? NetworkImage(_controller.currentProfilePictureUrl!)
                                      : AssetImage("images/anon_avatar.jpg")),
                              ),
                            ),
                          ),
                        ),
                        if (_controller.isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showImagePickerOptions,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  backgroundColor: _controller.model.primaryColor,
                                  radius: 16,
                                  child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _controller.model.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Personal Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _controller.model.textColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _controller.firstNameController,
                          decoration: InputDecoration(
                            labelText: "First Name",
                            labelStyle: TextStyle(color: Colors.grey.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _controller.model.primaryColor, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _controller.model.errorColor, width: 1),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            enabled: _controller.isEditing,
                            prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field is required';
                            }
                            return null;
                          },
                          style: TextStyle(color: _controller.model.textColor),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _controller.lastNameController,
                          decoration: InputDecoration(
                            labelText: "Last Name",
                            labelStyle: TextStyle(color: Colors.grey.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _controller.model.primaryColor, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _controller.model.errorColor, width: 1),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            enabled: _controller.isEditing,
                            prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field is required';
                            }
                            return null;
                          },
                          style: TextStyle(color: _controller.model.textColor),
                        ),
                        SizedBox(height: 24),
                        _buildInfoCard("Email", userData['emailAddress'] ?? 'Unknown', Icons.email_outlined),
                        
                        SizedBox(height: 24),

                        Center(
                          child: _controller.isEditing
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _saveProfile(firebaseUser),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _controller.model.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        "Save",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    OutlinedButton(
                                      onPressed: () => setState(() => _controller.isEditing = false),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _controller.model.primaryColor,
                                        side: BorderSide(color: _controller.model.primaryColor),
                                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text("Cancel"),
                                    ),
                                  ],
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => setState(() => _controller.isEditing = true),
                                  icon: Icon(Icons.edit),
                                  label: Text("Edit Profile"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _controller.model.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 59, 137, 62),
        currentIndex: 4, // Set the selected index to Profile
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
            label: 'Reports',
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
      ),
    );
  }
}