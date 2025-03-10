import 'package:bees/views/screens/auth/login_screen.dart';
import 'package:bees/views/screens/favorites_screen.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/request_model.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isEditing = false;
  bool _showActiveItems = false;
  bool _showRequests = false;
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _currentPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  TextEditingController _newEmailController = TextEditingController();
  
  String? _currentProfilePictureUrl;
  var _selectedIndex = 3;
  
bool _currentPasswordVisible = false;
bool _newPasswordVisible = false;
bool _confirmPasswordVisible = false;

  // Define a consistent color scheme
  final Color primaryColor = Color.fromARGB(255, 59, 137, 62);
  final Color accentColor = Colors.yellow;
  final Color textColor = Color(0xFF2D3748);
  final Color lightTextColor = Color(0xFF718096);
  final Color backgroundColor = Color(0xFFF7FAFC);
  final Color cardColor = Colors.white;
  final Color errorColor = Color(0xFFE53E3E);
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: cardColor,
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
                  color: primaryColor,
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
          color: isDestructive ? errorColor.withOpacity(0.1) : primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? errorColor : primaryColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDestructive ? errorColor : textColor,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDestructive ? errorColor.withOpacity(0.5) : Colors.grey.shade400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
    );
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
          color: primaryColor,
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
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: errorColor, width: 1),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Content is required' : null,
              style: TextStyle(color: textColor),
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
                await FirebaseFirestore.instance
                    .collection('requests')
                    .doc(request.requestID)
                    .update({
                  'requestContent': contentController.text,
                  'lastModifiedDate': DateTime.now(),
                });
                Navigator.of(context).pop();
                _showSnackBar('Request updated successfully');
              } catch (e) {
                _showSnackBar('Error updating request', isError: true);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
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

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: cardColor,
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
                  color: textColor,
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
              if (_currentProfilePictureUrl != null || _image != null)
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
          color: isDestructive ? errorColor.withOpacity(0.05) : Colors.grey.shade50,
          border: Border.all(
            color: isDestructive ? errorColor.withOpacity(0.2) : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? errorColor.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive ? errorColor : primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? errorColor : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      if (await imageFile.length() <= 10 * 1024 * 1024) {
        setState(() => _image = imageFile);
      } else {
        _showSnackBar('Image size must be less than 10MB', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? errorColor : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
        elevation: 4,
      ),
    );
  }

  Future<void> _removeProfilePicture() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Delete from Firebase Storage
      if (_currentProfilePictureUrl != null) {
        Reference storageRef = FirebaseStorage.instance.refFromURL(_currentProfilePictureUrl!);
        await storageRef.delete();
      }

      // Update Firestore with an empty string instead of deleting the field
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profilePicture': "",
      });

      setState(() {
        _image = null;
        _currentProfilePictureUrl = "";
      });

      _showSnackBar('Profile picture removed successfully');
    } catch (e) {
      _showSnackBar('Error removing profile picture', isError: true);
    }
  }

  Future<String?> _uploadImage(File image, String uid) async {
    Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$uid.jpg');
    await storageRef.putFile(image);
    return await storageRef.getDownloadURL();
  }

  Future<void> _saveProfile(User user) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await _uploadImage(_image!, user.uid);
      }

      Map<String, dynamic> updatedData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
      };

      if (imageUrl != null) {
        updatedData['profilePicture'] = imageUrl;
      } else if (_currentProfilePictureUrl == null) {
        updatedData['profilePicture'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updatedData);

      setState(() => _isEditing = false);
      _showSnackBar('Profile updated successfully');
    } catch (e) {
      _showSnackBar('Error updating profile', isError: true);
    }
  }

  Widget _buildActiveItemsList(String userId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('items')
        .where('itemOwnerId', isEqualTo: userId)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
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
                    color: lightTextColor,
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
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Add favorite count indicator
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
                                color: lightTextColor,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8),
                            Wrap(
                            spacing: 4, // Horizontal space between chips
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
                                    ? primaryColor.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Status: ${item.itemStatus}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: item.itemStatus == 'active' 
                                      ? primaryColor
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
                          color: primaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          // BEESED button - Req 2.8
                          if (item.itemStatus == 'active')
                            ElevatedButton(
                              onPressed: () => _markItemAsBeesed(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
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
                            color: primaryColor,
                            onPressed: () => _showEditItemDialog(context, item),
                          ),
                          SizedBox(width: 4),
                          _buildIconButton(
                            icon: Icons.delete,
                            color: errorColor,
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

  // Implementation for Req 2.8
  Future<void> _markItemAsBeesed(Item item) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Text(
            'Mark as BEESED',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.info_outline, size: 18, color: primaryColor),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            splashRadius: 20,
            onPressed: () {
              // Show a custom info dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.info, color: primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'What is BEESED?',
                          style: TextStyle(
                            color: primaryColor,
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
                          foregroundColor: primaryColor,
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
            style: TextStyle(color: textColor),
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
            backgroundColor: primaryColor,
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
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );

      // Get the current item data from Firestore
      DocumentSnapshot itemDoc = await FirebaseFirestore.instance
          .collection('items')
          .doc(item.itemId)
          .get();

      if (!itemDoc.exists) {
        Navigator.of(context).pop();
        _showSnackBar('Error: Item not found', isError: true);
        return;
      }

      Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;
      itemData['itemStatus'] = 'beesed';
      itemData['beesedDate'] = FieldValue.serverTimestamp();

      // Move the item to the beesed_items collection
      await FirebaseFirestore.instance
          .collection('beesed_items')
          .add(itemData);

      // Delete the item from the items collection
      await FirebaseFirestore.instance
          .collection('items')
          .doc(item.itemId)
          .delete();

      // Update the user's activeItems list
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'activeItems': FieldValue.arrayRemove([item.itemId]),
          'beesedItems': FieldValue.arrayUnion([item.itemId]),
        });
      }

      // Close loading indicator
      Navigator.of(context).pop();

      // Remove the item from the UI
      setState(() {
        _showActiveItems = true;
        _showRequests = false;
      });

      _showSnackBar('Item marked as BEESED and removed succesfully');
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar('Error updating item status: ${e.toString()}', isError: true);
    }
  }
}

void _refreshItemsList() {
  // This will force a refresh of the StreamBuilder in _buildActiveItemsList
  setState(() {});
// Helper method to build each explanation item
}
Widget _buildBEESEDExplanationItem(String letter, String meaning) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            meaning,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Item',
          style: TextStyle(
            color: errorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
          style: TextStyle(color: textColor),
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
              backgroundColor: errorColor,
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
        await FirebaseFirestore.instance
            .collection('items')
            .doc(item.itemId)
            .delete();
        _showSnackBar('Item deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting item', isError: true);
      }
    }
  }

  Future<void> _showEditItemDialog(BuildContext context, Item item) async {
    final editedItem = Item(
      itemId: item.itemId,
      itemOwnerId: item.itemOwnerId,
      title: item.title,
      description: item.description,
      category: item.category,
      condition: item.condition,
      itemType: item.itemType,
      departments: item.departments,
      price: item.price,
      paymentPlan: item.paymentPlan,
      photoUrl: item.photoUrl,
      additionalPhotos: item.additionalPhotos,
      favoriteCount: item.favoriteCount,
      itemStatus: item.itemStatus,
    );

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Item',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFormField(
                  initialValue: editedItem.title,
                  labelText: 'Title',
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Title is required' : null,
                  onChanged: (value) => editedItem.title = value,
                ),
                SizedBox(height: 16),
                _buildFormField(
                  initialValue: editedItem.description,
                  labelText: 'Description',
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? null : null,
                  onChanged: (value) => editedItem.description = value,
                ),
                SizedBox(height: 16),
                _buildFormField(
                  initialValue: editedItem.price.toString(),
                  labelText: 'Price',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Price is required';
                    if (double.tryParse(value!) == null) return 'Invalid price';
                    return null;
                  },
                  onChanged: (value) =>
                      editedItem.price = double.tryParse(value) ?? editedItem.price,
                ),
                SizedBox(height: 16),
                _buildDropdownField(
                  value: editedItem.condition,
                  labelText: 'Condition',
                  items: ['New', 'Lightly Used', 'Moderately Used', 'Heavily Used'],
                  onChanged: (value) {
                    if (value != null) editedItem.condition = value;
                  },
                ),
              ],
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
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await FirebaseFirestore.instance
                      .collection('items')
                      .doc(editedItem.itemId)
                      .update(editedItem.toJson());
                  Navigator.of(context).pop();
                  _showSnackBar('Item updated successfully');
                } catch (e) {
                  _showSnackBar('Error updating item', isError: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
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

  Widget _buildFormField({
    required String labelText,
    required String? Function(String?) validator,
    required Function(String) onChanged,
    String? initialValue,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText,
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
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: errorColor, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(color: textColor),
    );
  }

  Widget _buildDropdownField({
    required String labelText,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
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
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      icon: Icon(Icons.arrow_drop_down, color: primaryColor),
      style: TextStyle(color: textColor),
      dropdownColor: Colors.white,
    );
  }


  // Implementation for Req 2.9
Future<void> _markRequestAsSolved(Request request) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Mark as Solved',
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Are you sure you want to mark this request as solved? This will remove the request from your list.',
        style: TextStyle(color: textColor),
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
            backgroundColor: primaryColor,
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
      // Delete the request instead of updating its status
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(request.requestID)
          .delete();
      
      _showSnackBar('Request marked as solved and removed successfully');
    } catch (e) {
      _showSnackBar('Error processing request', isError: true);
    }
  }
}

Widget _buildRequestsList(String userID) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('requests')
        .where('requestOwnerID', isEqualTo: userID)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
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
                    color: lightTextColor,
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
                      color: textColor,
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
                          color: lightTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Solved button - now deletes the request
                      ElevatedButton(
                        onPressed: () => _markRequestAsSolved(request),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
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
                        color: primaryColor,
                        onPressed: () => _showEditRequestDialog(context, request),
                      ),
                      SizedBox(width: 4),
                      _buildIconButton(
                        icon: Icons.delete,
                        color: errorColor,
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
Future<void> _showDeleteRequestConfirmation(BuildContext context, Request request) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Delete Request',
        style: TextStyle(
          color: errorColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Are you sure you want to delete this request? This action cannot be undone.',
        style: TextStyle(color: textColor),
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
            backgroundColor: errorColor,
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
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(request.requestID)
          .delete();
      _showSnackBar('Request deleted successfully');
    } catch (e) {
      _showSnackBar('Error deleting request', isError: true);
    }
  }
}

  // Implementation for Req 10.4.7.1
Future<void> _showChangePasswordDialog() async {
  _currentPasswordController.clear();
  _newPasswordController.clear();
  _confirmPasswordController.clear();
  
  // Reset visibility states
  setState(() {
    _currentPasswordVisible = false;
    _newPasswordVisible = false;
    _confirmPasswordVisible = false;
  });

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder( // Use StatefulBuilder to manage state within dialog
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(
            'Change Password',
            style: TextStyle(
              color: primaryColor,
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
                key: _passwordFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current Password Field with visibility toggle
                    TextFormField(
                      controller: _currentPasswordController,
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
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: errorColor, width: 1),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600, size: 18),
                        // Add suffix icon for visibility toggle
                        suffixIcon: IconButton(
                          icon: Icon(
                            _currentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey.shade600,
                            size: 18,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _currentPasswordVisible = !_currentPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_currentPasswordVisible, // Toggle visibility
                      validator: (value) => value?.isEmpty ?? true ? 'Current password is required' : null,
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                    SizedBox(height: 12),
                    
                    // New Password Field with visibility toggle
                    TextFormField(
                      controller: _newPasswordController,
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
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: errorColor, width: 1),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: Icon(Icons.lock, color: Colors.grey.shade600, size: 18),
                        // Add suffix icon for visibility toggle
                        suffixIcon: IconButton(
                          icon: Icon(
                            _newPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey.shade600,
                            size: 18,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _newPasswordVisible = !_newPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_newPasswordVisible, // Toggle visibility
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'New password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                    SizedBox(height: 12),
                    
                    // Confirm Password Field with visibility toggle
                    TextFormField(
                      controller: _confirmPasswordController,
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
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: errorColor, width: 1),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: Icon(Icons.lock, color: Colors.grey.shade600, size: 18),
                        // Add suffix icon for visibility toggle
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey.shade600,
                            size: 18,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _confirmPasswordVisible = !_confirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_confirmPasswordVisible, // Toggle visibility
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                    SizedBox(height: 12),
                    
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'A verification email will be sent to your email address. You must verify your email before the password change will take effect.',
                              style: TextStyle(
                                fontSize: 11,
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
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_passwordFormKey.currentState?.validate() ?? false) {
                  await _changePassword();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
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
  @override
  Widget build(BuildContext context) {
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
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
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
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
                color: accentColor,
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
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
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
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          _currentProfilePictureUrl = userData['profilePicture'];

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: primaryColor,
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
                            onTap: _isEditing ? _showImagePickerOptions : null,
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 55,
                                backgroundImage: _image != null
                                ? FileImage(_image!) as ImageProvider
                                : (_currentProfilePictureUrl != null && _currentProfilePictureUrl!.isNotEmpty
                                    ? NetworkImage(_currentProfilePictureUrl!)
                                    : AssetImage("images/anon_avatar.jpg")),

                              ),
                            ),
                          ),
                        ),
                        if (_isEditing)
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
                                  backgroundColor: primaryColor,
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Personal Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _firstNameController,
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
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: errorColor, width: 1),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            enabled: _isEditing,
                            prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field is required';
                            }
                            return null;
                          },
                          style: TextStyle(color: textColor),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
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
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: errorColor, width: 1),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            enabled: _isEditing,
                            prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field is required';
                            }
                            return null;
                          },
                          style: TextStyle(color: textColor),
                        ),
                        SizedBox(height: 24),
                        _buildInfoCard("Email", userData['emailAddress'] ?? 'Unknown', Icons.email_outlined),
                        SizedBox(height: 12, width:10000),
                        _buildInfoCard("Rating", (userData['userRating'] ?? 0).toString(), Icons.star_outline),
                        
                        SizedBox(height: 24),

                        Center(
                          child: _isEditing
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _saveProfile(firebaseUser),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
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
                                      onPressed: () => setState(() => _isEditing = false),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primaryColor,
                                        side: BorderSide(color: primaryColor),
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
                                  onPressed: () => setState(() => _isEditing = true),
                                  icon: Icon(Icons.edit),
                                  label: Text("Edit Profile"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
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
                if (!_isEditing)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showActiveItems = !_showActiveItems;
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
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "My Items",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    _showActiveItems
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: primaryColor,
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
                        crossFadeState: _showActiveItems ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: Duration(milliseconds: 300),
                      ),
                    ],
                  ),
                ),
                
                // Requests Section - Only show when not in edit mode
                if (!_isEditing)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showRequests = !_showRequests;
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
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.assignment,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "My Requests",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                _showRequests
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: SizedBox.shrink(),
                        secondChild: _buildRequestsList(firebaseUser.uid),
                        crossFadeState: _showRequests ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 0 ? primaryColor.withOpacity(0.1) : Colors.transparent,
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
                  color: _selectedIndex == 1 ? primaryColor.withOpacity(0.1) : Colors.transparent,
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
                  color: _selectedIndex == 2 ? primaryColor.withOpacity(0.1) : Colors.transparent,
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
                  color: _selectedIndex == 3 ? primaryColor.withOpacity(0.0) : Colors.transparent,
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

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
        break;
      case 1:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => RequestsScreen()));
        break;
      case 2:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => FavoritesScreen()));
        break;
    }
  }
  
  Widget _buildInfoCard(String title, String value, IconData icon) {
  // Special handling for email to make it swipable
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
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: primaryColor,
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
                    color: lightTextColor,
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
                          color: textColor,
                        ),
                      ),
                      // Add a small indicator to show it's swipable
                      if (value.length > 20) // Only show indicator if email is long
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          
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
  
  // Regular info card for other fields
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
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: primaryColor,
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
                  color: lightTextColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
  
  // Implementation for Req 10.4.7.1
 Future<void> _changePassword() async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // Step 1: Re-authenticate the user with current password
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: _currentPasswordController.text,
    );

    // Reauthenticate
    await user.reauthenticateWithCredential(credential);
    
    // Step 2: Send password reset email
    await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
    
    // Step 3: Show success message with instructions
    _showSnackBar(
      'A password reset link has been sent to ${user.email}. Please check your inbox and click the link. When prompted, enter the new password you specified.',
      isError: false
    );
    
    // Close the dialog
    Navigator.of(context).pop();
    
  } catch (e) {
    String errorMessage = 'Error initiating password change: ';
    
    if (e.toString().contains('wrong-password')) {
      errorMessage += 'The current password is incorrect.';
    } else if (e.toString().contains('requires-recent-login')) {
      errorMessage += 'Please log out and log back in before trying again.';
    } else {
      errorMessage += e.toString();
    }
    
    _showSnackBar(errorMessage, isError: true);
    print('Detailed error: $e'); // Log the detailed error for debugging
  }
}

void _setupPasswordChangeVerificationListener(String userId, String newPassword) {
  // This listener will check for email verification
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null && user.emailVerified) {
      try {
        // Get the pending password change info
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        
        if (userData.containsKey('pendingPasswordChange') && 
            userData['pendingPasswordChange'] == true) {
          
          // Extract the stored password (remove the secure_ prefix)
          String storedPassword = userData['pendingPasswordHash'].toString().replaceFirst('secure_', '');
          
          // Verify it matches what we expect
          if (storedPassword == newPassword) {
            // Update the password
            await user.updatePassword(newPassword);
            
            // Clean up the temporary data
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({
              'pendingPasswordChange': FieldValue.delete(),
              'pendingPasswordHash': FieldValue.delete(),
              'passwordChangeRequestTime': FieldValue.delete(),
            });
            
            _showSnackBar('Password changed successfully after verification.');
          }
        }
      } catch (e) {
        _showSnackBar('Error completing password change: ${e.toString()}', isError: true);
      }
    }
  });
}

// Add this method to listen for email verification
void _listenForPasswordChangeVerification(String userId) {
  // Set up a listener to check for email verification
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null && user.emailVerified) {
      try {
        // Get the pending password from Firestore
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        
        if (userData.containsKey('pendingPasswordChange') && 
            userData['pendingPasswordChange'] == true &&
            userData.containsKey('pendingPasswordHash')) {
          
          // Extract the password (remove the temp_ prefix)
          String newPassword = userData['pendingPasswordHash'].toString().replaceFirst('temp_', '');
          
          // Update the password
          await user.updatePassword(newPassword);
          
          // Clean up the temporary data
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'pendingPasswordChange': FieldValue.delete(),
            'pendingPasswordHash': FieldValue.delete(),
            'passwordChangeRequestTime': FieldValue.delete(),
          });
          
          _showSnackBar('Password changed successfully after verification.');
        }
      } catch (e) {
        _showSnackBar('Error completing password change: ${e.toString()}', isError: true);
      }
    }
  });
}

  // Implementation for Req 10.4.7.4
  Future<void> _showChangeEmailDialog() async {
  _newEmailController.clear();
  _currentPasswordController.clear(); // Reuse the password controller

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Change Email Address',
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize:12,
        ),
      ),
      content: Form(
        key: _emailFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: Colors.grey.shade700,fontSize: 12),
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
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: errorColor, width: 1),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
              ),
              obscureText: true,
              validator: (value) => value?.isEmpty ?? true ? 'Password is required for verification' : null,
              style: TextStyle(color: textColor),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _newEmailController,
              decoration: InputDecoration(
                labelText: 'New Email Address',
                labelStyle: TextStyle(color: Colors.grey.shade700,fontSize:12),
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
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: errorColor, width: 1),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
              style: TextStyle(color: textColor),
            ),
            SizedBox(height: 2),
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
                      'A verification email will be sent to the new address. Your current email will remain active until verification is complete. Please check your spam folder if you don\'t see the email.',
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
            if (_emailFormKey.currentState?.validate() ?? false) {
              await _changeEmail();
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Save Changes'),
        ),
      ],
    ),
  );
}

  // Implementation for Req 10.4.7.4
  Future<void> _changeEmail() async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // Step 1: Re-authenticate the user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: _currentPasswordController.text,
    );
    await user.reauthenticateWithCredential(credential);

    // Step 2: Update the email address
    await user.verifyBeforeUpdateEmail(_newEmailController.text);

    // Step 3: Store the pending email in Firestore for reference
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'pendingEmail': _newEmailController.text,
    });

    // Step 4: Show success message
    _showSnackBar('Verification email sent to ${_newEmailController.text}. Please check your inbox and spam folder.');

    // Step 5: Listen for email verification
    _listenForEmailVerification(user.uid, _newEmailController.text);
  } catch (e) {
    // Handle errors
    String errorMessage = 'Error changing email: ';
    
    if (e.toString().contains('requires-recent-login')) {
      errorMessage += 'Please log out and log back in before trying again.';
    } else if (e.toString().contains('invalid-email')) {
      errorMessage += 'The email address is not valid.';
    } else if (e.toString().contains('email-already-in-use')) {
      errorMessage += 'This email is already in use by another account.';
    } else {
      errorMessage += e.toString();
    }
    
    _showSnackBar(errorMessage, isError: true);
    print('Detailed error: $e');
  }
}
void _listenForEmailVerification(String userId, String newEmail) {
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null && user.emailVerified) {
      // Step 1: Update the emailAddress field in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'emailAddress': newEmail,
        'pendingEmail': FieldValue.delete(), // Remove the pendingEmail field
      });

      // Step 2: Show success message
      _showSnackBar('Email successfully updated to $newEmail.');

      // Step 3: Stop listening (optional)
      // You can stop listening here if you no longer need to track changes.
    }
  });
}

  // Implementation for Req 10.4.7.2
  Future<void> _logout() async {
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Log Out",
            style: TextStyle(
              color: errorColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to log out?",
            style: TextStyle(color: textColor),
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
                backgroundColor: errorColor,
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
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } catch (e) {
        _showSnackBar("Error logging out: ${e.toString()}", isError: true);
      }
    }
  }
  
  void _showRequestDetails(BuildContext context, Request request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Request Details',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              request.requestContent,
              style: TextStyle(color: textColor),
            ),
            SizedBox(height: 12),
            Text(
              'Status:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              request.requestStatus,
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditRequestDialog(context, request);
            },
            child: Text(
              'Edit',
              style: TextStyle(color: primaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _markRequestAsSolved(request);
            },
            style: TextButton.styleFrom(foregroundColor: primaryColor),
            child: Text('Mark as Solved'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteRequestConfirmation(context, request);
            },
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: Text('Delete'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: textColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}