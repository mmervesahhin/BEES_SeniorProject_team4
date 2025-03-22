import 'package:flutter/material.dart';
import 'package:bees/models/item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

class EditItemScreen extends StatefulWidget {
  final Item item;

  const EditItemScreen({Key? key, required this.item}) : super(key: key);

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late Item _editedItem;
  bool _isLoading = false;

  // Updated color palette
  final Color primaryColor = const Color(0xFFFFD700); // Vibrant yellow
  final Color secondaryColor = const Color(0xFFFFF8E1); // Light yellow
  final Color textColor = const Color(0xFF000000); // Black
  final Color errorColor = const Color(0xFFFF5252); // Red for errors
  final Color accentColor = const Color(0xFF333333); // Dark gray

  final ImagePicker _picker = ImagePicker();
  List<String> _photoUrls = []; // Existing photo URLs from Firestore
  List<File> _newPhotos = []; // New photos selected by the user
  List<String> _deletedPhotoUrls = []; // URLs of photos to be deleted

  // Available options for dropdowns
  final List<String> _conditions = ['New', 'Lightly Used', 'Moderately Used', 'Heavily Used'];
  final List<String> _categories = ['Notes', 'Books', 'Electronics', 'Stationary', 'Other'];
  final List<String> _itemTypes = ['Sale', 'Rent', 'Exchange', 'Donate'];
  final List<String> _departments = ['AMER', 'ARCH', 'CHEM', 'COMD', 'CS', 'CTIS', 'ECON', 'EDU', 'EEE', 'ELIT', 'FA', 'GRA', 'HART', 'IAED', 'IE', 'IR', 'LAUD', 'LAW', 'MAN', 'MATH', 'MBG', 'ME', 'MSC', 'PHIL', 'PHYS', 'POLS', 'PREP', 'PSYC', 'THM','THR','TRIN'];
  
  // Selected departments
  List<String> _selectedDepartments = [];

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
    
    // Initialize with existing photos
    if (widget.item.photoUrl != null && widget.item.photoUrl!.isNotEmpty) {
      _photoUrls = [widget.item.photoUrl!];
    }
    
    if (widget.item.additionalPhotos != null) {
      _photoUrls.addAll(widget.item.additionalPhotos!);
    }
    
    // Initialize selected departments
    _selectedDepartments = List.from(widget.item.departments ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // Black icons for contrast
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))) 
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Section
                _buildSectionTitle('Photos (Required)'),
                const SizedBox(height: 8),
                _buildPhotoSection(),
                const SizedBox(height: 24),

                // Basic Information
                _buildSectionTitle('Item Information'),
                const SizedBox(height: 8),
                
                // Title Field
                _buildFormField(
                  initialValue: _editedItem.title,
                  labelText: 'Title',
                  validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
                  onChanged: (value) => _editedItem.title = value,
                ),
                const SizedBox(height: 16),

                // Description Field
                _buildFormField(
                  initialValue: _editedItem.description,
                  labelText: 'Description',
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true ? null : null,
                  onChanged: (value) => _editedItem.description = value,
                ),
                const SizedBox(height: 24),

                // Pricing & Category
                _buildSectionTitle('Pricing & Details'),
                const SizedBox(height: 8),

                // Item Type (Sale/Rent/Exchange/Donate)
                _buildDropdownField(
                  value: _editedItem.itemType ?? _itemTypes[0],
                  labelText: 'Item Type',
                  items: _itemTypes,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _editedItem.itemType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Price Field (only show if Sale or Rent)
                if (_editedItem.itemType == 'Sale' || _editedItem.itemType == 'Rent')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormField(
                        initialValue: _editedItem.price.toString(),
                        labelText: 'Price (${_editedItem.itemType == 'Rent' ? 'per month' : 'Turkish Lira'})',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.currency_lira, color: Colors.black),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Price is required';
                          if (double.tryParse(value!) == null) return 'Invalid price';
                          return null;
                        },
                        onChanged: (value) => _editedItem.price = double.tryParse(value) ?? _editedItem.price,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Condition Dropdown
                _buildDropdownField(
                  value: _editedItem.condition,
                  labelText: 'Condition',
                  items: _conditions,
                  onChanged: (value) {
                    if (value != null) _editedItem.condition = value;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                _buildDropdownField(
                  value: _editedItem.category,
                  labelText: 'Category',
                  items: _categories,
                  onChanged: (value) {
                    if (value != null) _editedItem.category = value;
                  },
                ),
                const SizedBox(height: 24),

                // Departments Section
                _buildSectionTitle('Relevant Departments'),
                const SizedBox(height: 8),
                _buildDepartmentsSelector(),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Black text for contrast
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add at least one photo of your item',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Display existing photos
                  for (int i = 0; i < _photoUrls.length; i++)
                    _buildPhotoTile(
                      isNetwork: true,
                      source: _photoUrls[i],
                      onDelete: () => _deletePhoto(i),
                    ),

                  // Display new photos
                  for (int i = 0; i < _newPhotos.length; i++)
                    _buildPhotoTile(
                      isNetwork: false,
                      source: _newPhotos[i],
                      onDelete: () => _deletePhoto(_photoUrls.length + i),
                    ),

                  // Add Photo Button
                  GestureDetector(
                    onTap: _pickPhotos,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 32,
                            color: primaryColor.withOpacity(0.8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_photoUrls.isEmpty && _newPhotos.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'At least one photo is required',
              style: TextStyle(
                color: errorColor,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoTile({
    required bool isNetwork,
    required dynamic source,
    required VoidCallback onDelete,
  }) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: isNetwork
              ? Image.network(
                  source,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                      ),
                    );
                  },
                )
              : Image.file(
                  source,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String labelText,
    required String? Function(String?) validator,
    required Function(String) onChanged,
    String? initialValue,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixIcon,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: prefixIcon,
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
      value: items.contains(value) ? value : items.first,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildDepartmentsSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select departments relevant to this item:',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _departments.map((department) {
              final isSelected = _selectedDepartments.contains(department);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDepartments.remove(department);
                    } else {
                      _selectedDepartments.add(department);
                    }
                    _editedItem.departments = _selectedDepartments;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    department,
                    style: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Pick new photos from the gallery or camera
  Future<void> _pickPhotos() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
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
      final String fileName = '${_editedItem.itemId}_${DateTime.now().millisecondsSinceEpoch}';
      final Reference storageRef = FirebaseStorage.instance.ref().child('item_photos/$fileName.jpg');
      
      // Compress image before uploading
      final Uint8List compressedImage = await compressImage(photo);
      
      // Upload compressed image
      await storageRef.putData(
        compressedImage,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final String downloadUrl = await storageRef.getDownloadURL();
      uploadedUrls.add(downloadUrl);
    }
    return uploadedUrls;
  }

  // Compress image to reduce storage usage and improve loading speed
  Future<Uint8List> compressImage(File imageFile) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    // Here you would typically use a package like flutter_image_compress
    // For simplicity, we're just returning the bytes directly
    return bytes;
  }

  // Delete photos from Firebase Storage
  Future<void> _deletePhotos(List<String> photoUrls) async {
    for (var url in photoUrls) {
      try {
        final Reference storageRef = FirebaseStorage.instance.refFromURL(url);
        await storageRef.delete();
      } catch (e) {
        print('Error deleting photo: $e');
        // Continue with other deletions even if one fails
      }
    }
  }

  // Validate form before saving
  bool _validateForm() {
    // Check if form is valid
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }
    
    // Check if at least one photo is present
    if (_photoUrls.isEmpty && _newPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add at least one photo'),
          backgroundColor: errorColor,
        ),
      );
      return false;
    }
    
    // Check if at least one department is selected
    if (_selectedDepartments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one department'),
          backgroundColor: errorColor,
        ),
      );
      return false;
    }
    
    return true;
  }

  Future<void> _saveItem() async {
    if (!_validateForm()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Upload new photos
      List<String> newPhotoUrls = await _uploadPhotos(_newPhotos);
      
      // Delete removed photos
      if (_deletedPhotoUrls.isNotEmpty) {
        await _deletePhotos(_deletedPhotoUrls);
      }
      
      // Update item with new photo URLs
      if (_photoUrls.isEmpty && newPhotoUrls.isNotEmpty) {
        // If there are no existing photos but new ones were added,
        // set the first new photo as the main photo
        _editedItem.photoUrl = newPhotoUrls.first;
        newPhotoUrls.removeAt(0);
      }
      
      // Combine existing and new additional photos
      List<String> allAdditionalPhotos = [..._photoUrls];
      if (_editedItem.photoUrl != null && _photoUrls.contains(_editedItem.photoUrl)) {
        // Remove main photo from additional photos if it exists there
        allAdditionalPhotos.remove(_editedItem.photoUrl);
      }
      allAdditionalPhotos.addAll(newPhotoUrls);
      
      // Update the item with all photos
      _editedItem.additionalPhotos = allAdditionalPhotos.isEmpty ? null : allAdditionalPhotos;
      
      // Update item in Firestore
      await FirebaseFirestore.instance
          .collection('items')
          .doc(_editedItem.itemId)
          .update(_editedItem.toJson());
      
      // Show success message and close screen
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item updated successfully'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      print('Error updating item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating item: ${e.toString()}'),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}