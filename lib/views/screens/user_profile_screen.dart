import 'package:bees/controllers/user_profile_controller.dart';
import 'package:bees/views/screens/blocked_users_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/request_model.dart';
import 'package:bees/views/screens/edit_item_screen.dart';
import 'package:bees/views/screens/auth/login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserProfileController _controller = UserProfileController();
  
  @override
void initState() {
  super.initState();
  _controller.initializeUserData();
  
  // Set callback for email verification
  _controller.onEmailVerified = () {
    setState(() {}); // Refresh the UI
    _showSnackBar('Email address has been successfully updated!');
  };
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

 // Update the _showSettingsMenu method in the _UserProfileScreenState class

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
            _buildSettingsListTile(
              icon: Icons.block,
              title: "Blocked Users",
              onTap: () {
                Navigator.pop(context);
                _navigateToBlockedUsers();
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

// Add this method to the _UserProfileScreenState class if it's not already defined

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

// Add this method to the _UserProfileScreenState class
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

  Widget _buildActiveItemsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.getActiveItemsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_controller.model.primaryColor),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No active items found",
                    style: TextStyle(
                      fontSize: 16,
                      color: _controller.model.lightTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final item = Item.fromJson(doc.data() as Map<String, dynamic>, doc.id);
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item.photoUrl != null
                              ? Image.network(
                                  item.photoUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image, color: Colors.grey),
                                ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _controller.model.textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.favorite,
                                          color: Colors.red,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '${item.favoriteCount}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                item.description,
                                style: TextStyle(
                                  color: _controller.model.lightTextColor,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                children: [
                                  _buildChip(item.category),
                                  _buildChip(item.condition),
                                ],
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: item.itemStatus == 'active' 
                                      ? _controller.model.primaryColor.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Status: ${item.itemStatus}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: item.itemStatus == 'active' 
                                        ? _controller.model.primaryColor
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24, thickness: 1, color: Colors.grey.shade200),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₺${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _controller.model.primaryColor,
                          ),
                        ),
                        Row(
                          children: [
                            if (item.itemStatus == 'active')
                              ElevatedButton(
                                onPressed: () => _markItemAsBeesed(item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _controller.model.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'BEESED',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            SizedBox(width: 8),
                            _buildIconButton(
                              icon: Icons.edit,
                              color: _controller.model.primaryColor,
                              onPressed: () => _controller.navigateToEditItemScreen(context, item),
                            ),
                            SizedBox(width: 4),
                            _buildIconButton(
                              icon: Icons.delete,
                              color: _controller.model.errorColor,
                              onPressed: () => _showDeleteConfirmation(context, item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.all(8),
        constraints: BoxConstraints(),
        splashRadius: 24,
      ),
    );
  }

  Future<void> _markItemAsBeesed(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              'Mark as BEESED',
              style: TextStyle(
                color: _controller.model.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.info_outline, size: 18, color: _controller.model.primaryColor),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              splashRadius: 20,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.info, color: _controller.model.primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'What is BEESED?',
                            style: TextStyle(
                              color: _controller.model.primaryColor,
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
                            'Marking an item as BEESED means it is no longer available because it has been sold, rented, exchanged, or donated.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: _controller.model.primaryColor,
                          ),
                          child: Text('Got it'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to mark this item as BEESED?',
              style: TextStyle(color: _controller.model.textColor),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This item will be removed from active listings on the home screen and from your "My Items" section.',
                      style: TextStyle(
                        fontSize: 12,
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
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _controller.model.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Confirm'),
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
              valueColor: AlwaysStoppedAnimation<Color>(_controller.model.primaryColor),
            ),
          ),
        );

        bool success = await _controller.markItemAsBeesed(item);
        
        Navigator.of(context).pop();
        
        if (success) {
          setState(() {
            _controller.showActiveItems = true;
            _controller.showRequests = false;
          });
          _showSnackBar('Item marked as BEESED and removed successfully');
        } else {
          _showSnackBar('Error updating item status', isError: true);
        }
      } catch (e) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar('Error updating item status: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Item',
          style: TextStyle(
            color: _controller.model.errorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this item from your active listings? It will be marked as inactive.',
          style: TextStyle(color: _controller.model.textColor),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _controller.model.errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Remove'),
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
              valueColor: AlwaysStoppedAnimation<Color>(_controller.model.primaryColor),
            ),
          ),
        );

        bool success = await _controller.markItemAsInactive(item);
        
        Navigator.of(context, rootNavigator: true).pop();
        
        if (success) {
          _showSnackBar('Item marked as inactive');
          setState(() {});
        } else {
          _showSnackBar('Error updating item status', isError: true);
        }
      } catch (e) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar('Error updating item status: ${e.toString()}', isError: true);
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
              valueColor: AlwaysStoppedAnimation<Color>(_controller.model.primaryColor),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No requests found",
                    style: TextStyle(
                      fontSize: 16,
                      color: _controller.model.lightTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        List<Request> requests = snapshot.data!.docs.map((doc) {
          return Request.fromJson(
            Map<String, dynamic>.from(doc.data() as Map<String, dynamic>)
              ..['requestID'] = doc.id
          );
        }).toList();

        return Column(
          children: requests.map((request) {
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requestContent,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _controller.model.textColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Status: ${request.requestStatus}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        Text(
                          request.creationDate.toString().split(' ')[0],
                          style: TextStyle(
                            color: _controller.model.lightTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () => _markRequestAsSolved(request),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _controller.model.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Solved',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        _buildIconButton(
                          icon: Icons.edit,
                          color: _controller.model.primaryColor,
                          onPressed: () => _showEditRequestDialog(context, request),
                        ),
                        SizedBox(width: 4),
                        _buildIconButton(
                          icon: Icons.delete,
                          color: _controller.model.errorColor,
                          onPressed: () => _showDeleteRequestConfirmation(context, request),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _markRequestAsSolved(Request request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Mark as Solved',
          style: TextStyle(
            color: _controller.model.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to mark this request as solved? This will remove the request from your list.',
          style: TextStyle(color: _controller.model.textColor),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _controller.model.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        bool success = await _controller.markRequestAsSolved(request);
        if (success) {
          _showSnackBar('Request marked as solved and removed successfully');
        } else {
          _showSnackBar('Error processing request', isError: true);
        }
      } catch (e) {
        _showSnackBar('Error processing request', isError: true);
      }
    }
  }

  Future<void> _showDeleteRequestConfirmation(BuildContext context, Request request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Request',
          style: TextStyle(
            color: _controller.model.errorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this request? This action cannot be undone.',
          style: TextStyle(color: _controller.model.textColor),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _controller.model.errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        bool success = await _controller.deleteRequest(request.requestID);
        if (success) {
          _showSnackBar('Request deleted successfully');
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

  // Check if there's a pending email verification
  User? user = FirebaseAuth.instance.currentUser;
  DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
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
        style: TextStyle(
          color: _controller.model.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
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
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You have a pending email change to: $pendingEmail\n\nPlease check your email and click the verification link to complete the change.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Resend verification email
                      _controller.resendEmailVerification(pendingEmail!);
                      Navigator.of(context).pop();
                      _showSnackBar('Verification email resent to $pendingEmail');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _controller.model.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Resend Verification Email'),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      // Cancel the pending email change
                      await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                        'pendingEmail': FieldValue.delete(),
                        'emailChangeRequestTime': FieldValue.delete(),
                      });
                      _controller.stopEmailVerificationCheck();
                      Navigator.of(context).pop();
                      _showSnackBar('Email change request cancelled');
                    },
                    child: Text(
                      'Cancel Email Change',
                      style: TextStyle(color: _controller.model.errorColor),
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
                        helperText: 'Must be a Bilkent email (example@bilkent.edu.tr)',
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
                              'A verification email will be sent to the new address. Your email will only be updated after you verify the new address and log in again. Please check your spam folder if you don\'t see the email.',
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
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ]
        : [
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
                    // Start checking for email verification
                    _controller.startEmailVerificationCheck();
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
            SizedBox(width: 8),
            Text(
              'BEES',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _controller.model.accentColor,
                letterSpacing: 1,
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
          _controller.newEmailController.text = userData['emailAddress']?? '';

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
                        SizedBox(height: 12, width: 10000),
                        _buildInfoCard("Rating", (userData['userRating'] ?? 0).toString(), Icons.star_outline),
                        
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
                
                // Active Items Section - Only show when not in edit mode
                if (!_controller.isEditing)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _controller.showActiveItems = !_controller.showActiveItems;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _controller.model.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: _controller.model.primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "My Items",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _controller.model.textColor,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _controller.model.primaryColor.withOpacity(0.0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    _controller.showActiveItems
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: _controller.model.primaryColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: SizedBox.shrink(),
                        secondChild: _buildActiveItemsList(firebaseUser.uid),
                        crossFadeState: _controller.showActiveItems ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: Duration(milliseconds: 300),
                      ),
                    ],
                  ),
                ),
                
                // Requests Section - Only show when not in edit mode
                if (!_controller.isEditing)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _controller.showRequests = !_controller.showRequests;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _controller.model.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.assignment,
                                      color: _controller.model.primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "My Requests",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _controller.model.textColor,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                _controller.showRequests
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: _controller.model.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: SizedBox.shrink(),
                        secondChild: _buildRequestsList(firebaseUser.uid),
                        crossFadeState: _controller.showRequests ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: Duration(milliseconds: 300),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
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
          selectedItemColor: _controller.model.primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _controller.selectedIndex,
          onTap: (index) => _controller.navigateTo(context, index),
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _controller.selectedIndex == 0 ? _controller.model.primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(FontAwesomeIcons.shop),
              ),
              label: 'Items',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _controller.selectedIndex == 1 ? _controller.model.primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.assignment),
              ),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _controller.selectedIndex == 2 ? _controller.model.primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.favorite),
              ),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _controller.selectedIndex == 3 ? _controller.model.primaryColor.withOpacity(0.0) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.account_circle),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}