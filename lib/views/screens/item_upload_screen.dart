import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'item_upload_success_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

// Import item model and controller
import '../../models/item_model.dart';
import '../../controllers/item_upload_controller.dart';

void main() {
  runApp(const UploadItemApp());
}

class UploadItemApp extends StatelessWidget {
  const UploadItemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upload Item',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.amber,
      ),
      home: const UploadItemPage(),
    );
  }
}

class UploadItemPage extends StatefulWidget {
  final Map<String, dynamic>? itemToEdit;
  final String? itemId;

  const UploadItemPage({super.key, this.itemToEdit, this.itemId});

  @override
  State<UploadItemPage> createState() => _UploadItemPageState();
}

class _UploadItemPageState extends State<UploadItemPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Color scheme
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);

  // Variables for dropdowns
  String category = 'Sale';
  String itemType = 'Other';
  String condition = 'New';

  final ItemController itemController = ItemController();

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _imageCover;

  // List to hold additional images
  List<File> _additionalImages = [];

  // Department list for multi-select dropdown
  List<String> departments = [
    'AMER', 'ARCH', 'CHEM', 'COMD', 'CS', 'CTIS', 'ECON', 'EDU', 'EEE', 
    'ELIT', 'FA', 'GRA', 'HART', 'IAED', 'IE', 'IR', 'LAUD', 'LAW', 
    'MAN', 'MATH', 'MBG', 'ME', 'MSC', 'PHIL', 'PHYS', 'POLS', 'PREP', 
    'PSYC', 'THM', 'THR', 'TRIN'
  ];

  // Add departmentList with All Departments option
  late List<String> departmentList;
  
  // Selected departments
  List<String> selectedDepartments = [];

  // Add a Map for filters
  Map<String, dynamic> _filters = {
    'departments': <String>[],
  };
  
  // Payment plan options
  String paymentPlan = 'Per Hour';
  bool isPaymentPlanEnabled = false;
  bool showCoverError = false;
  
  @override
  void initState() {
    super.initState();
    selectedDepartments = List<String>.from(departments); // Default to all departments
    departmentList = ['All Departments'];
    departmentList.addAll(departments);
  }

  // Check if price field should be disabled
  bool isPriceFieldDisabled() {
    return category == 'Donate' || category == 'Exchange';
  }

  // Check if all departments are selected
  bool get allSelected => selectedDepartments.length == departments.length;
  
  // Toggle all departments selection
  void toggleSelection() {
    setState(() {
      if (allSelected) {
        selectedDepartments = []; // Remove all
      } else {
        selectedDepartments = List<String>.from(departments); // Select all
      }
    });
  }

  // Add the _showDepartmentDialog method after the toggleSelection method
  void _showDepartmentDialog(StateSetter setDialogState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> tempSelection = selectedDepartments.length == departments.length
            ? List.from(departmentList)
            : List.from(selectedDepartments);

        return StatefulBuilder(
          builder: (context, innerSetState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Select Departments',
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: primaryYellow),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    CheckboxListTile(
                      value: tempSelection.contains('All Departments') || tempSelection.length == departments.length,
                      title: Text('All Departments', style: GoogleFonts.nunito()),
                      activeColor: primaryYellow,
                      onChanged: (bool? value) {
                        innerSetState(() {
                          if (value == true) {
                            tempSelection = List.from(departmentList);
                          } else {
                            tempSelection.clear();
                          }
                        });
                      },
                    ),
                    Divider(),
                    ...departmentList.where((dept) => dept != 'All Departments').map((dept) {
                      return CheckboxListTile(
                        value: tempSelection.contains(dept),
                        title: Text(dept, style: GoogleFonts.nunito()),
                        activeColor: primaryYellow,
                        onChanged: (bool? value) {
                          innerSetState(() {
                            if (value == true) {
                              tempSelection.add(dept);
                            } else {
                              tempSelection.remove(dept);
                            }

                            // Check All Departments logic after each change
                            bool isAllSelected = tempSelection.contains('All Departments');
                            int normalDeptCount = departments.length;
                            int selectedNormal = tempSelection
                                .where((e) => e != 'All Departments')
                                .length;

                            if (selectedNormal == normalDeptCount && !isAllSelected) {
                              tempSelection.add('All Departments');
                            } else if (selectedNormal < normalDeptCount && isAllSelected) {
                              tempSelection.remove('All Departments');
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: primaryYellow,
                    textStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  ),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setDialogState(() {
                      selectedDepartments = tempSelection.contains('All Departments') 
                          ? List.from(departments)
                          : tempSelection;
                      // Keep All Departments in UI but not in filters
                      _filters['departments'] = selectedDepartments.where((d) => d != 'All Departments').toList();
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Upload cover image
  Widget uploadCoverImagePlaceholder() {
    return GestureDetector(
      onTap: () async {
        try {
          final selectedImage = await itemController.pickCoverImage();
          if (selectedImage != null) {
            setState(() {
              _imageCover = selectedImage;
              showCoverError = false; // Clear error when image is selected
            });
          }
        } catch (e) {
          _showImageSizeError();
        }
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryYellow, width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 36, color: primaryYellow),
            SizedBox(height: 8),
            Text(
              'Cover Photo',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add more photos placeholder
  Widget addMorePhotosPlaceholder() {
    return GestureDetector(
      onTap: () async {
        try {
          final selectedImage = await itemController.pickAdditionalImage();
          if (selectedImage != null) {
            setState(() {
              _additionalImages.add(selectedImage);
            });
          }
        } catch (e) {
          _showImageSizeError();
        }
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textLight.withOpacity(0.3), width: 1, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 28, color: textLight),
            SizedBox(height: 4),
            Text(
              'Add Photo',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show image size error dialog
  void _showImageSizeError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Image Too Large',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          content: Text(
            'The selected image exceeds the 5MB size limit. Please choose a smaller image.',
            style: GoogleFonts.nunito(
              color: textDark,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: GoogleFonts.nunito(
                  color: primaryYellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  // Upload item
  void _uploadItem() async {
    setState(() {
      showCoverError = _imageCover == null;
    });

    if (_formKey.currentState?.validate() ?? false) {
      if (_imageCover == null) {
        return; // Stop if no cover image
      }
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Uploading your item...',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Upload the item
      await itemController.validateAndUploadItem(
        category: category,
        condition: condition,
        itemType: itemType,
        paymentPlan: paymentPlan,
        coverImage: _imageCover,
        additionalImages: _additionalImages,
        selectedDepartments: selectedDepartments,
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Upload Item',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Yellow header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                color: primaryYellow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add a New Item',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Fill in the details below to list your item',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photos section
                    _buildSectionHeader('Photos', true),
                    SizedBox(height: 12),
                    
                    // Cover photo
                    Row(
                      children: [
                        _imageCover == null
                            ? uploadCoverImagePlaceholder()
                            : Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _imageCover!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -5,
                                    right: -5,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 2,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.close, color: Colors.red, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(
                                          minWidth: 24,
                                          minHeight: 24,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _imageCover = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        SizedBox(width: 16),
                        addMorePhotosPlaceholder(),
                      ],
                    ),
                    
                    // Cover photo error
                    if (showCoverError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Please upload a cover photo',
                          style: GoogleFonts.nunito(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    
                    SizedBox(height: 16),
                    
                    // Additional photos
                    if (_additionalImages.isNotEmpty) ...[
                      Text(
                        'Additional Photos',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textLight,
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _additionalImages.map((image) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    image,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -5,
                                right: -5,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.close, color: Colors.red, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _additionalImages.remove(image);
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24),
                    ],
                    
                    // Item details section
                    _buildSectionHeader('Item Details', true),
                    SizedBox(height: 16),
                    
                    // Category
                    _buildFormLabel('Category', true),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: category,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: InputBorder.none,
                        ),
                        style: GoogleFonts.nunito(
                          color: textDark,
                          fontSize: 16,
                        ),
                        icon: Icon(Icons.arrow_drop_down, color: primaryYellow),
                        items: ['Sale', 'Rent', 'Exchange', 'Donate']
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ))
                            .toList(),
                        onChanged: (newValue) {
                          setState(() {
                            category = newValue!;
                            itemController.updatePriceField(category, itemController.priceController);
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Title
                    _buildFormLabel('Title', true),
                    TextFormField(
                      controller: itemController.titleController,
                      validator: (value) => itemController.validateTitle(value),
                      style: GoogleFonts.nunito(
                        color: textDark,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter item title',
                        hintStyle: GoogleFonts.nunito(
                          color: textLight,
                          fontSize: 16,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryYellow),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Description
                    _buildFormLabel('Description', false),
                    TextFormField(
                      controller: itemController.descriptionController,
                      maxLines: 4,
                      style: GoogleFonts.nunito(
                        color: textDark,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter item description',
                        hintStyle: GoogleFonts.nunito(
                          color: textLight,
                          fontSize: 16,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryYellow),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Item Type
                    _buildFormLabel('Item Type', false),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: itemType,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: InputBorder.none,
                        ),
                        style: GoogleFonts.nunito(
                          color: textDark,
                          fontSize: 16,
                        ),
                        icon: Icon(Icons.arrow_drop_down, color: primaryYellow),
                        items: ['Notes', 'Books', 'Electronics', 'Stationary', 'Other']
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ))
                            .toList(),
                        onChanged: (newValue) {
                          setState(() {
                            itemType = newValue!;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Departments section
                    _buildSectionHeader('Departments', false),
                    SizedBox(height: 12),
                    
                    // Replace the Department selection UI in the build method with this improved version
                    // Find the section that starts with "// Department selection UI - matching home screen filter style"
                    // and replace it with:

                    // Department selection UI with dialog
                    Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Selected departments:',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showDepartmentDialog(setState),
                                icon: Icon(Icons.edit, size: 16, color: primaryYellow),
                                label: Text(
                                  "Change",
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryYellow,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  backgroundColor: primaryYellow.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          
                          // Show selected departments or "All Departments" if all are selected
                          selectedDepartments.length == departments.length
                            ? Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: primaryYellow,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryYellow.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'All Departments',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : selectedDepartments.isEmpty
                              ? Text(
                                  'No departments selected',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: textLight,
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: selectedDepartments.map((dept) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: primaryYellow,
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryYellow.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        dept,
                                        style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Condition
                    _buildFormLabel('Condition', false),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: condition,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: InputBorder.none,
                        ),
                        style: GoogleFonts.nunito(
                          color: textDark,
                          fontSize: 16,
                        ),
                        icon: Icon(Icons.arrow_drop_down, color: primaryYellow),
                        items: (itemType == 'Other'
                                ? ['New', 'Lightly Used', 'Moderately Used', 'Heavily Used', '']
                                : ['New', 'Lightly Used', 'Moderately Used', 'Heavily Used'])
                            .map((value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ))
                            .toList(),
                        onChanged: (newValue) {
                          setState(() {
                            condition = newValue!;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Price section
                    _buildSectionHeader('Pricing', true),
                    SizedBox(height: 16),
                    
                    // Price and Payment Plan
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price field
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('Price (₺)', !isPriceFieldDisabled()),
                              TextFormField(
                                controller: itemController.priceController,
                                keyboardType: TextInputType.number,
                                enabled: !isPriceFieldDisabled(),
                                validator: (value) => itemController.validatePrice(value, category),
                                style: GoogleFonts.nunito(
                                  color: isPriceFieldDisabled() ? textLight : textDark,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: isPriceFieldDisabled() ? 'N/A' : 'Enter price',
                                  hintStyle: GoogleFonts.nunito(
                                    color: textLight,
                                    fontSize: 16,
                                  ),
                                  prefixText: '₺ ',
                                  prefixStyle: GoogleFonts.nunito(
                                    color: isPriceFieldDisabled() ? textLight : textDark,
                                    fontSize: 16,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryYellow),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                                  ),
                                  filled: isPriceFieldDisabled(),
                                  fillColor: isPriceFieldDisabled() ? backgroundColor : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        
                        // Payment Plan
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('Payment Plan', false),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: category == 'Rent' 
                                        ? Colors.grey.withOpacity(0.3) 
                                        : Colors.grey.withOpacity(0.1),
                                  ),
                                  color: category == 'Rent' ? null : backgroundColor,
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: paymentPlan,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    border: InputBorder.none,
                                  ),
                                  style: GoogleFonts.nunito(
                                    color: category == 'Rent' ? textDark : textLight,
                                    fontSize: 16,
                                  ),
                                  icon: Icon(
                                    Icons.arrow_drop_down, 
                                    color: category == 'Rent' ? primaryYellow : textLight,
                                  ),
                                  items: ['Per Hour', 'Per Day', 'Per Month']
                                      .map((value) => DropdownMenuItem(
                                            value: value,
                                            child: Text(value),
                                          ))
                                      .toList(),
                                  onChanged: category == 'Rent'
                                      ? (newValue) {
                                          setState(() {
                                            paymentPlan = newValue!;
                                          });
                                        }
                                      : null,
                                  disabledHint: Text(
                                    'Not available',
                                    style: GoogleFonts.nunito(
                                      color: textLight,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    
                    // Upload button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryYellow,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _uploadItem,
                        child: Text(
                          'Upload Item',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build section headers
  Widget _buildSectionHeader(String title, bool required) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
      ],
    );
  }

  // Helper method to build form labels
  Widget _buildFormLabel(String label, bool required) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          if (required)
            Text(
              ' *',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}
