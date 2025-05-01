import 'package:bees/controllers/beesed_transaction_controller.dart';
import 'package:bees/controllers/user_profile_controller.dart';
import 'package:bees/views/screens/detailed_item_screen.dart';
import 'package:bees/views/screens/item_history_screen.dart';
import 'package:bees/views/screens/blocked_users_screen.dart';
import 'package:bees/views/screens/request_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/request_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
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
  final Color textLight = Color(0xFFD1D5DB);
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

    // Set callback for email verification
    _controller.onEmailVerified = () {
      setState(() {}); // Refresh the UI
      _showSnackBar('Email address has been successfully updated!');
    };
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
                          _buildSettingsCategory("History"),
                          _buildSettingsListTile(
                            icon: Icons.inventory_2_outlined,
                            title: "Item History",
                            subtitle: "View your past items",
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToItemHistory();
                            },
                          ),
                          _buildSettingsListTile(
                            icon: Icons.assignment_outlined,
                            title: "Request History",
                            subtitle: "View your past requests",
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToRequestHistory();
                            },
                          ),
                          _buildSettingsListTile(
                            icon: Icons.block_outlined,
                            title: "Blocked Users",
                            subtitle: "Manage blocked users",
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToBlockedUsers();
                            },
                          ),
                          _buildSettingsCategory("Account Actions",
                              isDanger: true),
                          _buildSettingsListTile(
                            icon: Icons.delete_outline,
                            title: "Delete Account",
                            subtitle: "Permanently delete your account",
                            isDestructive: true,
                            onTap: () {
                              Navigator.pop(context);
                              _showDeleteAccountDialog();
                            },
                          ),
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

  void _navigateToRequestHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RequestHistoryScreen(),
      ),
    );
  }

  void _navigateToItemHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemHistoryScreen(),
      ),
    );
  }

  void _navigateToBlockedUsers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlockedUsersScreen(),
      ),
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

  Future<void> _showDeleteAccountDialog() async {
    final passwordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: errorColor),
                SizedBox(width: 8),
                Text(
                  'Delete Account',
                  style: GoogleFonts.nunito(
                    color: errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Warning: This action cannot be undone!',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: errorColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Deleting your account will permanently remove all your data, including your profile, items, and requests.',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Please enter your password to confirm:',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle:
                          GoogleFonts.nunito(color: textMedium, fontSize: 14),
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
                        borderSide: BorderSide(color: errorColor, width: 1),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.lock_outline, color: textMedium),
                    ),
                    obscureText: true,
                    style: GoogleFonts.nunito(color: textDark),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage!,
                        style: GoogleFonts.nunito(
                          color: errorColor,
                          fontSize: 12,
                        ),
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
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.nunito(
                    color: textMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (passwordController.text.isEmpty) {
                          setState(() {
                            errorMessage = 'Please enter your password';
                          });
                          return;
                        }

                        setState(() {
                          isLoading = true;
                          errorMessage = null;
                        });

                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return Dialog(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      primaryYellow),
                                ),
                              ),
                            );
                          },
                        );

                        String? error = await _controller
                            .deleteUserAccount(passwordController.text);

                        // Close loading dialog
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }

                        if (error == null) {
                          // Success - navigate to login screen
                          if (context.mounted) {
                            Navigator.of(context)
                                .pop(); // Close the delete account dialog
                            _controller.navigateToLogin(context);

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        color: Colors.white),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Your account has been deleted successfully.',
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: successColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                margin: EdgeInsets.all(16),
                              ),
                            );
                          }
                        } else {
                          // Error
                          setState(() {
                            isLoading = false;
                            errorMessage = error;
                          });
                        }
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
                child: Text(
                  'Delete Account',
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

  Future<void> _showEditRequestDialog(
      BuildContext context, Request request) async {
    final TextEditingController contentController =
        TextEditingController(text: request.requestContent);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Request',
          style: GoogleFonts.nunito(
            color: textDark,
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
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Content is required' : null,
                style: GoogleFonts.nunito(color: textDark),
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
              style: GoogleFonts.nunito(
                color: textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  bool success = await _controller.updateRequestContent(
                      request.requestID, contentController.text);
                  Navigator.of(context).pop();
                  if (success) {
                    _showSnackBar('Request updated successfully',
                        isSuccess: true);
                  } else {
                    _showSnackBar('Error updating request', isError: true);
                  }
                } catch (e) {
                  _showSnackBar('Error updating request', isError: true);
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
              'Save',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveItemsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.getActiveItemsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
              strokeWidth: 2,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: 16),
                Text(
                  "No active items",
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Items you post will appear here",
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: textMedium,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(top: 8),
          physics: AlwaysScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final item =
                Item.fromJson(doc.data() as Map<String, dynamic>, doc.id);

            return _buildItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildItemCard(Item item) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetailedItemScreen(itemId: item.itemId),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image with status badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: item.photoUrl != null
                      ? Image.network(
                          item.photoUrl!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: 150,
                          color: Colors.grey[200],
                          child: Icon(Icons.image_outlined,
                              color: Colors.grey, size: 48),
                        ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: item.itemStatus == 'active'
                          ? primaryYellow
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.itemStatus == 'active'
                              ? Icons.check_circle
                              : Icons.hourglass_empty,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          item.itemStatus == 'active'
                              ? 'Active'
                              : item.itemStatus,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.all(8),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.red.shade400,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${item.favoriteCount}',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Item details
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    item.description ?? "",
                    style: GoogleFonts.nunito(
                      color: textMedium,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.category != null && item.category!.isNotEmpty)
                        _buildChip(item.category!),
                      if (item.condition != null && item.condition!.isNotEmpty)
                        _buildChip(item.condition!),
                      if (item.itemType != null && item.itemType!.isNotEmpty)
                        _buildChip(item.itemType!),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Price and actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₺${item.price.toStringAsFixed(2)}',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryYellow,
                        ),
                      ),
                      Row(
                        children: [
                          if (item.itemStatus == 'active')
                            ElevatedButton(
                              onPressed: () => _markItemAsBeesed(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryYellow,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              child: Text(
                                'BEESED',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: textMedium),
                            onPressed: () => _controller
                                .navigateToEditItemScreen(context, item),
                            tooltip: 'Edit',
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(),
                            splashRadius: 24,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: errorColor),
                            onPressed: () =>
                                _showDeleteConfirmation(context, item),
                            tooltip: 'Delete',
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(),
                            splashRadius: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markItemAsBeesed(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: primaryYellow),
            SizedBox(width: 8),
            Text(
              'Mark as BEESED',
              style: GoogleFonts.nunito(
                color: textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to mark this item as BEESED?',
              style: GoogleFonts.nunito(color: textDark),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This item will be removed from active listings on the home screen and from your "My Items" section.',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
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
              'Confirm',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Use the BeesedTransactionHandler to show the user selection dialog
        final BeesedTransactionHandler beesedHandler =
            BeesedTransactionHandler();
        await beesedHandler.showBeesedDialog(context, item);

        // Refresh the UI after the transaction is completed
        setState(() {});
      } catch (e) {
        _showSnackBar('Error updating item status: ${e.toString()}',
            isError: true);
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: errorColor),
            SizedBox(width: 8),
            Text(
              'Remove Item',
              style: GoogleFonts.nunito(
                color: errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove this item from your active listings? It will be marked as inactive.',
          style: GoogleFonts.nunito(color: textDark),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
              strokeWidth: 2,
            ),
          ),
        );

        bool success = await _controller.markItemAsInactive(item);

        Navigator.of(context, rootNavigator: true).pop();

        if (success) {
          setState(() {});
          _showSnackBar('Item marked as inactive successfully',
              isSuccess: true);
        } else {
          _showSnackBar('Error updating item status', isError: true);
        }
      } catch (e) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar('Error updating item status: ${e.toString()}',
            isError: true);
      }
    }
  }

  Widget _buildRequestsList(String userID) {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.getRequestsStream(userID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
              strokeWidth: 2,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: 16),
                Text(
                  "No active requests",
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Requests you create will appear here",
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: textMedium,
                  ),
                ),
              ],
            ),
          );
        }

        List<Request> requests = snapshot.data!.docs.map((doc) {
          return Request.fromJson(
              Map<String, dynamic>.from(doc.data() as Map<String, dynamic>)
                ..['requestID'] = doc.id);
        }).toList();

        return ListView.builder(
          padding: EdgeInsets.only(top: 8),
          physics: AlwaysScrollableScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(request);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(Request request) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryYellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        request.requestStatus,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  request.creationDate.toString().split(' ')[0],
                  style: GoogleFonts.nunito(
                    color: textMedium,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              request.requestContent,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _markRequestAsSolved(request),
                  icon: Icon(Icons.check_circle_outline, size: 16),
                  label: Text('Solved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: textMedium),
                  onPressed: () => _showEditRequestDialog(context, request),
                  tooltip: 'Edit',
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(),
                  splashRadius: 24,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: errorColor),
                  onPressed: () =>
                      _showDeleteRequestConfirmation(context, request),
                  tooltip: 'Delete',
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(),
                  splashRadius: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markRequestAsSolved(Request request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: primaryYellow),
            SizedBox(width: 8),
            Text(
              'Mark as Solved',
              style: GoogleFonts.nunito(
                color: textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to mark this request as solved? It will be moved to your solved requests history.',
          style: GoogleFonts.nunito(color: textDark),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
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
              'Confirm',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        bool success = await _controller.markRequestAsSolved(request);
        if (success) {
          _showSnackBar('Request marked as solved successfully',
              isSuccess: true);
        } else {
          _showSnackBar('Error processing request', isError: true);
        }
      } catch (e) {
        _showSnackBar('Error processing request', isError: true);
      }
    }
  }

  Future<void> _showDeleteRequestConfirmation(
      BuildContext context, Request request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: errorColor),
            SizedBox(width: 8),
            Text(
              'Delete Request',
              style: GoogleFonts.nunito(
                color: errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this request? This action cannot be undone.',
          style: GoogleFonts.nunito(color: textDark),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        bool success = await _controller.deleteRequest(request.requestID);
        if (success) {
          _showSnackBar('Request deleted successfully', isSuccess: true);
        } else {
          _showSnackBar('Error deleting request', isError: true);
        }
      } catch (e) {
        _showSnackBar('Error deleting request', isError: true);
      }
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

    if (pendingEmail != null) {
      _controller.startEmailVerificationCheck();
    }

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
                          _controller.stopEmailVerificationCheck();
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

  Widget _buildChip(String? label) {
    if (label == null || label.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryYellow.withOpacity(0.2), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 12,
          color: primaryYellow,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      {Color? color}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1) ?? primaryYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color ?? primaryYellow,
                size: 15,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color ?? primaryYellow,
            ),
          ),
        ],
      ),
    );
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

          // User name and rating
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

          // User rating
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: primaryYellow, size: 20),
              SizedBox(width: 4),
              Text(
                (userData['userRating'] ?? 0).toStringAsFixed(1),
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryYellow,
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Stats row - make it scrollable
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(height: 24),
                _buildProfileStats(
                    user), // Replace your old stats row with this
                SizedBox(height: 24),
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

  Widget _buildProfileStats(User user) {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.getActiveItemsStream(user.uid),
      builder: (context, activeItemsSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _controller.getBeesedItemsStream(user.uid),
          builder: (context, beesedItemsSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: _controller.getRequestsStream(user.uid),
              builder: (context, requestsSnapshot) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatCard(
                        "Active Items",
                        activeItemsSnapshot.hasData
                            ? "${activeItemsSnapshot.data!.docs.length}"
                            : "0",
                        Icons.inventory_2_outlined,
                      ),
                      SizedBox(width: 12),
                      _buildStatCard(
                        "Beesed Items",
                        beesedItemsSnapshot.hasData
                            ? "${beesedItemsSnapshot.data!.docs.length}"
                            : "0",
                        Icons.check_circle_outline,
                        color: accentColor,
                      ),
                      SizedBox(width: 12),
                      _buildStatCard(
                        "Requests",
                        requestsSnapshot.hasData
                            ? "${requestsSnapshot.data!.docs.length}"
                            : "0",
                        Icons.assignment_outlined,
                        color: secondaryYellow,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
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
                  } else if (value.length < 2) {
                    return 'First name must be at least 2 characters long';
                    return null;
                  }
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
                  } else if (value.length < 2) {
                    return 'Last name must be at least 2 characters long';
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
          _controller.newEmailController.text = userData['emailAddress'] ?? '';

          if (_controller.isEditing) {
            // When editing, just show the profile header with edit form
            return SingleChildScrollView(
              child: Column(
                children: [
                  AppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: backgroundColor,
                    elevation: 0,
                    title: Text(
                      'Edit Profile',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                  _buildProfileHeader(firebaseUser, userData),
                ],
              ),
            );
          }

          // When not editing, use NestedScrollView with SliverAppBar for collapsible header
          return SafeArea(
            child: DefaultTabController(
              length: 2,
              child: CustomScrollView(
                controller: _scrollController,
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  // App Bar
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    floating: false,
                    pinned: true,
                    backgroundColor: backgroundColor,
                    elevation: 0,
                    title: Text(
                      'Profile',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textDark,
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

                  // Profile Header
                  SliverToBoxAdapter(
                    child: _buildProfileHeader(firebaseUser, userData),
                  ),

                  // Tab Bar
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: primaryYellow,
                        indicatorWeight: 3,
                        labelColor: textDark,
                        unselectedLabelColor: textMedium,
                        labelStyle: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedLabelStyle: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: [
                          Tab(text: "Active Items"),
                          Tab(text: "Requests"),
                        ],
                      ),
                    ),
                    pinned: true,
                  ),

                  // Tab Content
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Active Items Tab - Use a NotificationListener to detect when at top
                        NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification scrollInfo) {
                            if (scrollInfo is ScrollStartNotification &&
                                scrollInfo.metrics.pixels == 0) {
                              // Allow parent scroll to take over when at the top
                              return false;
                            }
                            return true;
                          },
                          child: _buildActiveItemsList(firebaseUser.uid),
                        ),

                        // Requests Tab - Use a NotificationListener to detect when at top
                        NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification scrollInfo) {
                            if (scrollInfo is ScrollStartNotification &&
                                scrollInfo.metrics.pixels == 0) {
                              // Allow parent scroll to take over when at the top
                              return false;
                            }
                            return true;
                          },
                          child: _buildRequestsList(firebaseUser.uid),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryYellow,
        unselectedItemColor: textMedium,
        backgroundColor: Colors.white,
        iconSize: 22,
        currentIndex: _controller.selectedIndex,
        onTap: (index) => _controller.navigateTo(context, index),
        selectedLabelStyle:
            GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle:
            GoogleFonts.nunito(fontWeight: FontWeight.normal, fontSize: 12),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.shop),
            activeIcon: Icon(FontAwesomeIcons.shop),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            activeIcon: Icon(Icons.assignment),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            activeIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Custom SliverPersistentHeaderDelegate for the tab bar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
