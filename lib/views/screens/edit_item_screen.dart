import 'package:flutter/material.dart';
import 'package:bees/models/item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditItemScreen extends StatefulWidget {
  final Item item;

  const EditItemScreen({Key? key, required this.item}) : super(key: key);

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late Item _editedItem;

  final Color primaryColor = Color.fromARGB(255, 59, 137, 62);
  final Color textColor = Color(0xFF2D3748);
  final Color errorColor = Color(0xFFE53E3E);

  final ImagePicker _picker = ImagePicker();
  List<String> _photoUrls = []; // Existing photo URLs from Firestore
  List<File> _newPhotos = []; // New photos selected by the user
  List<String> _deletedPhotoUrls = []; // URLs of photos to be deleted

  @override
  @override
void initState() {
  super.initState();
  _editedItem = Item(
    itemId: widget.item.itemId,
    itemOwnerId: widget.item.itemOwnerId,
    title: widget.item.title,
    description: widget.item.description,
    category: widget.item.category,
    condition: widget.item.condition,
    itemType: widget.item.itemType,
    departments: widget.item.departments,
    price: widget.item.price,
    paymentPlan: widget.item.paymentPlan,
    photoUrl: widget.item.photoUrl,
    additionalPhotos: widget.item.additionalPhotos,
    favoriteCount: widget.item.favoriteCount,
    itemStatus: widget.item.itemStatus,
  );
  _photoUrls = widget.item.additionalPhotos ?? []; // Initialize with existing photos
}


  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Edit Item'),
      backgroundColor: primaryColor,
      actions: [
        IconButton(
          icon: Icon(Icons.save),
          onPressed: _saveItem,
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
             // Photo Section
            Text(
              'Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Display existing photos
                for (int i = 0; i < _photoUrls.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _photoUrls[i],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePhoto(i),
                        ),
                      ),
                    ],
                  ),

                // Display new photos
                for (int i = 0; i < _newPhotos.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _newPhotos[i],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePhoto(_photoUrls.length + i),
                        ),
                      ),
                    ],
                  ),

                // Add Photo Button
                GestureDetector(
                  onTap: _pickPhotos,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add, size: 40, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            // Title Field
            _buildFormField(
              initialValue: _editedItem.title,
              labelText: 'Title',
              validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
              onChanged: (value) => _editedItem.title = value,
            ),
            SizedBox(height: 16),

            // Description Field
            _buildFormField(
              initialValue: _editedItem.description,
              labelText: 'Description',
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
              onChanged: (value) => _editedItem.description = value,
            ),
            SizedBox(height: 16),

            // Price Field
            _buildFormField(
              initialValue: _editedItem.price.toString(),
              labelText: 'Price',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Price is required';
                if (double.tryParse(value!) == null) return 'Invalid price';
                return null;
              },
              onChanged: (value) => _editedItem.price = double.tryParse(value) ?? _editedItem.price,
            ),
            SizedBox(height: 16),

           
            SizedBox(height: 16),

            // Condition Dropdown
            _buildDropdownField(
              value: _editedItem.condition,
              labelText: 'Condition',
              items: ['New', 'Lightly Used', 'Moderately Used', 'Heavily Used'],
              onChanged: (value) {
                if (value != null) _editedItem.condition = value;
              },
            ),
            SizedBox(height: 16),

            // Category Dropdown
            _buildDropdownField(
              value: _editedItem.category,
              labelText: 'Category',
              items: ['Notes', 'Books', 'Electronics', 'Stationary', 'Other'],
              onChanged: (value) {
                if (value != null) _editedItem.category = value;
              },
            ),
          ],
        ),
      ),
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
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
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
    value: items.contains(value) ? value : null, // Ensure the value exists in the items list
    decoration: InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
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

// Pick new photos from the gallery or camera
Future<void> _pickPhotos() async {
  final List<XFile>? pickedFiles = await _picker.pickMultiImage();
  if (pickedFiles != null) {
    setState(() {
      _newPhotos.addAll(pickedFiles.map((file) => File(file.path)).toList());
    });
  }
}

// Delete an existing photo
void _deletePhoto(int index) {
  setState(() {
    if (index < _photoUrls.length) {
      _deletedPhotoUrls.add(_photoUrls[index]); // Add to deleted list
      _photoUrls.removeAt(index); // Remove from displayed list
    } else {
      _newPhotos.removeAt(index - _photoUrls.length); // Remove from new photos
    }
  });
}

// Upload new photos to Firebase Storage
Future<List<String>> _uploadPhotos(List<File> photos) async {
  List<String> uploadedUrls = [];
  for (var photo in photos) {
    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final Reference storageRef = FirebaseStorage.instance.ref().child('item_photos/$fileName.jpg');
    await storageRef.putFile(photo);
    final String downloadUrl = await storageRef.getDownloadURL();
    uploadedUrls.add(downloadUrl);
  }
  return uploadedUrls;
}

// Delete photos from Firebase Storage
Future<void> _deletePhotos(List<String> photoUrls) async {
  for (var url in photoUrls) {
    final Reference storageRef = FirebaseStorage.instance.refFromURL(url);
    await storageRef.delete();
  }
}

  Future<void> _saveItem() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await FirebaseFirestore.instance
            .collection('items')
            .doc(_editedItem.itemId)
            .update(_editedItem.toJson());
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item updated successfully'),
            backgroundColor: primaryColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }
}