import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '/views/screens/item_upload_success.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // InputFormatter için gerekli
import 'dart:io';

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
        primarySwatch: Colors.green,
      ),
      home: const UploadItemPage(),
    );
  }
}

class UploadItemPage extends StatefulWidget {
  const UploadItemPage({super.key});

  @override
  State<UploadItemPage> createState() => _UploadItemPageState();
}

class _UploadItemPageState extends State<UploadItemPage> {
  // Variables for dropdowns
  String category = 'Sale';
  String itemType = 'Other';
  String condition = 'New';

  // Controllers for text fields
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

// Image picker
  final ImagePicker _picker = ImagePicker();
  File? _image;

  // Title validator
  String? titleValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please fill in the title';
    }
    return null;
  }

  // Placeholder for uploaded image
  Widget uploadImagePlaceholder() {
    return GestureDetector(
      onTap: () => _pickImage(),  // Trigger image picker when placeholder is tapped
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.green[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.add_a_photo, size: 40, color: Colors.white),
      ),
    );
  }
  // Method to pick an image from gallery or camera
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Department list for multi-select dropdown
  List<String> departments = [
    'CTIS', 'CS', 'COMD', 'CHEM', 'MBG', 'PHYS', 'ARCH', 'IAED', 'IR', 'POLS', 
    'PSYC', 'ME', 'MAN', 'IE', 'EEE', 'AMER', 'ELIT', 'GRA', 'PHIL', 'THM', 'MUS', 
    'FA', 'TRIN', 'PREP'
  ];

  // Selected departments
  List<String> selectedDepartments = [];

  // Payment plan options
  String paymentPlan = 'Per Hour';
  bool isPaymentPlanEnabled = false;

  // Validate if price is a positive number
  String? priceValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter the price'; // Error message when price is empty
  }
  final price = double.tryParse(value);
  if ((category == 'Sale' || category == 'Rent') && (price == null || price <= 0)) {
    return 'Please enter a value greater than 0';
  }
  return null;
}


  bool _isTitleEmpty = false; // Flag to check if title is empty on submit
  bool _isPriceEmpty = false; // Flag for empty price field
  bool _isPriceInvalid = false; // Flag for invalid price (e.g., <= 0)

  // Update the price based on selected category
  void updatePriceField() {
    if (category == 'Exchange' || category == 'Donate') {
      priceController.text = '0';
    } else {
      priceController.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Item'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Upload Section
              Row(
                children: [
                  _image == null 
                      ? uploadImagePlaceholder() // Show placeholder if no image is selected
                      : Image.file(_image!, width: 80, height: 80, fit: BoxFit.cover), // Show selected image
                  const SizedBox(width: 16),
                  uploadImagePlaceholder(),
                ],
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              const Text('Category'),
              DropdownButton<String>(
                value: category,
                isExpanded: true,
                items: ['Sale', 'Rent', 'Exchange', 'Donate']
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    category = newValue!;
                    updatePriceField(); // Update price when category changes
                  });
                },
              ),
              const SizedBox(height: 10),

              // Title TextField (Required)
              const Text('Title'),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter title',
                ),
                validator: titleValidator, // Apply title validator
              ),
              const SizedBox(height: 5),

              // Display error if title is empty after trying to upload
              if (_isTitleEmpty && titleController.text.isEmpty)
                const Text(
                  'Please fill in the title',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              const SizedBox(height: 10),

              // Description (Optional)
              const Text('Description'),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter description',
                ),
              ),
              const SizedBox(height: 10),

              // Row for Item Type and Department Dropdowns
              Row(
                children: [
                  // Item Type Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Item Type'),
                        DropdownButton<String>(
                          value: itemType,
                          isExpanded: true,
                          items: ['Other', 'Electronic', 'Stationary', 'Book', 'Note']
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Department Dropdown (multi-select)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Department'),
                        MultiSelectDialogField(
                          items: departments.map((dept) => MultiSelectItem(dept, dept)).toList(),
                          initialValue: selectedDepartments,
                          onConfirm: (results) {
                            setState(() {
                              selectedDepartments = List.from(results);
                            });
                          },
                          title: const Text("Departments"),
                          buttonText: const Text("Select Departments"),
                          chipDisplay: MultiSelectChipDisplay.none(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Condition Dropdown (Empty option for some types)
              const Text('Condition'),
              DropdownButton<String>(
                value: condition,
                isExpanded: true,
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
              const SizedBox(height: 10),

              // Row for Price Field and Payment Plan
              Row(
                children: [
                  // Price Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Price'),
                        TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixText: '₺ ',
                          ),
                          validator: priceValidator,
                          readOnly: category == 'Exchange' || category == 'Donate', // Make price field readonly for certain categories
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Allow only positive numbers
                          ],
                        ),
                        if (_isPriceEmpty)
                          const Text(
                            'Please fill in the price',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        if (_isPriceInvalid)
                          const Text(
                            'Price must be greater than 0',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Payment Plan Dropdown (Enabled for Rent only)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Plan'),
                        DropdownButton<String>(
                          value: paymentPlan,
                          isExpanded: true,
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
                              : null, // Disabled for categories other than Rent
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Upload Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: () {
                    setState(() {
                      // Check if title and price are empty or invalid
                      _isTitleEmpty = titleController.text.isEmpty;
                      _isPriceEmpty = priceController.text.isEmpty;

                      if (category == 'Sale' || category == 'Rent'){
                          _isPriceInvalid = !_isPriceEmpty &&
                          (double.tryParse(priceController.text) == null ||
                           double.parse(priceController.text) <= 0);
                      }else if (category == 'Exchange' || category == 'Donate') {
                        _isPriceInvalid = false; // No need to check for price for these categories
                      } else {
                        _isPriceInvalid = false; // Any other categories (if any)
                      }

                      
                    });

                    // Only navigate if title is not empty
                    if (!_isTitleEmpty && !_isPriceEmpty && !_isPriceInvalid && _image != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UploadSuccessPage()),
                      );
                    }
                  },
                  child: const Text('Upload Item', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
