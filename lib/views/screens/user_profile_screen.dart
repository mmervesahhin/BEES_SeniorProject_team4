import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/request_model.dart';
import 'package:firebase_database/firebase_database.dart';

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
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  String? _currentProfilePictureUrl;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Color.fromARGB(255, 59, 137, 62)),
                title: Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                onTap: () async {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color.fromARGB(255, 59, 137, 62)),
                title: Text('Take a Picture', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                onTap: () async {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_currentProfilePictureUrl != null || _image != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Remove Picture', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfilePicture();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      if (await imageFile.length() <= 10 * 1024 * 1024) {
        setState(() => _image = imageFile);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image size must be less than 10MB')),
        );
      }
    }
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing profile picture')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile')),
      );
    }
  }

  Widget _buildActiveItemsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .where('itemOwnerId', isEqualTo: userId)
          .where('itemStatus', isEqualTo: 'Active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Text("No active items found"),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final item = Item.fromJson(doc.data() as Map<String, dynamic>, doc.id);
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
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
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                item.description,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildChip(item.category),
                                  SizedBox(width: 8),
                                  _buildChip(item.condition),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₺${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 59, 137, 62),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Color.fromARGB(255, 59, 137, 62)),
                              onPressed: () => _showEditItemDialog(context, item),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
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

  Widget _buildChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item'),
        content: Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item')),
        );
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
        title: Text('Edit Item'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: editedItem.title,
                  decoration: InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Title is required' : null,
                  onChanged: (value) => editedItem.title = value,
                ),
                SizedBox(height: 16),
                TextFormField(
                  initialValue: editedItem.description,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Description is required' : null,
                  onChanged: (value) => editedItem.description = value,
                ),
                SizedBox(height: 16),
                TextFormField(
                  initialValue: editedItem.price.toString(),
                  decoration: InputDecoration(labelText: 'Price'),
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
                DropdownButtonFormField<String>(
                  value: editedItem.condition,
                  decoration: InputDecoration(labelText: 'Condition'),
                  items: ['New', 'Lightly Used', 'Moderately Used', 'Heavily Used']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) editedItem.condition = value;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await FirebaseFirestore.instance
                      .collection('items')
                      .doc(editedItem.itemId)
                      .update(editedItem.toJson());
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Item updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating item')),
                  );
                }
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(String userID) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance
          .ref()
          .child('requests')
          .orderByChild('requestOwnerID')
          .equalTo(userID)
          .onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Text("No requests found"),
          );
        }

        Map<dynamic, dynamic> requestsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        List<Request> requests = requestsMap.entries.map((entry) {
          return Request.fromJson(Map<String, dynamic>.from(entry.value)..['requestID'] = entry.key);
        }).toList();

        if (requests.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Text("No requests found"),
          );
        }

        return Column(
          children: requests.map((request) {
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(request.requestContent),
                subtitle: Text(request.requestStatus),
                trailing: Text(request.creationDate.toString().split(' ')[0]),
                onTap: () => _showRequestDetails(context, request),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showRequestDetails(BuildContext context, Request request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request ID: ${request.requestID}'),
            Text('Content: ${request.requestContent}'),
            Text('Status: ${request.requestStatus}'),
            Text('Creation Date: ${request.creationDate.toString()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return Scaffold(body: Center(child: Text("User not found.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromARGB(255, 59, 137, 62),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return Center(child: Text("User data not found. Please complete your profile."));
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
                    color: Color.fromARGB(255, 59, 137, 62),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _isEditing ? _showImagePickerOptions : null,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 55,
                              backgroundImage: _image != null
                                  ? FileImage(_image!)
                                  : (_currentProfilePictureUrl != null
                                      ? NetworkImage(_currentProfilePictureUrl!)
                                      : AssetImage("assets/default_avatar.png")) as ImageProvider,
                            ),
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showImagePickerOptions,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 18,
                                child: Icon(Icons.camera_alt, color: Color.fromARGB(255, 59, 137, 62), size: 20),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: "First Name",
                            border: OutlineInputBorder(),
                            enabled: _isEditing,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: "Last Name",
                            border: OutlineInputBorder(),
                            enabled: _isEditing,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        _buildInfoTile("Email", userData['emailAddress'] ?? 'Unknown'),
                        _buildInfoTile("Rating", (userData['userRating'] ?? 0).toString()),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showActiveItems = !_showActiveItems;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Active Items",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      (userData['activeItems']?.length ?? 0).toString(),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      _showActiveItems
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Color.fromARGB(255, 59, 137, 62),
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
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showRequests = !_showRequests;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "My Requests",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Icon(
                                  _showRequests
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Color.fromARGB(255, 59, 137, 62),
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
                        SizedBox(height: 24),
                        Center(
                          child: _isEditing
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _saveProfile(firebaseUser),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color.fromARGB(255, 59, 137, 62),
                                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                      ),
                                      child: Text("Save", style: TextStyle(color: Colors.white)),
                                    ),
                                    SizedBox(width: 16),
                                    OutlinedButton(
                                      onPressed: () => setState(() => _isEditing = false),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Color.fromARGB(255, 59, 137, 62),
                                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                      ),
                                      child: Text("Cancel"),
                                    ),
                                  ],
                                )
                              : ElevatedButton(
                                  onPressed: () => setState(() => _isEditing = true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color.fromARGB(255, 59, 137, 62),
                                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                  ),
                                  child: Text("Edit Profile", style: TextStyle(color: Colors.white)),
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
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
