import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'item_upload_success_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // InputFormatter için gerekli
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // FormKey for validation

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


  // Placeholder for uploaded image
Widget uploadCoverImagePlaceholder() {
  return GestureDetector(
    onTap: () async {
      try {
        final selectedImage = await itemController.pickCoverImage();
        if (selectedImage != null) {
          setState(() {
            _imageCover = selectedImage;
          });
        }
      } catch (e) {
        _showImageSizeError(); // Hata mesajı göster
      }
    },
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


  // Placeholder for adding multiple photos
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
        _showImageSizeError(); // Hata mesajı göster
      }
    },
    child: Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.green[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.add, size: 30, color: Colors.white),
      ),
    ),
  );
}

  // Function to show an error dialog or message if the image exceeds the size limit
  void _showImageSizeError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text('The selected image exceeds the 5MB size limit. Please choose a smaller image.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to handle form submission
  void _uploadItem() async {
    if (_formKey.currentState?.validate() ?? false) {
      // If the form is valid, upload the item
      await itemController.validateAndUploadItem(
        category: category,
        condition: condition,
        coverImage: _imageCover,
        additionalImages: _additionalImages,
        selectedDepartments: selectedDepartments,
        context: context,
      );
    }
  }


  // Department list for multi-select dropdown
  List<String> departments = ['AMER', 'ARCH', 'CHEM', 'COMD', 'CS', 'CTIS', 'ECON', 'EDU', 'EEE', 'ELIT', 'FA', 'GRA', 'HART', 'IAED', 'IE', 'IR', 'LAUD', 'LAW', 'MAN', 'MATH', 'MBG', 'ME', 'MSC', 'PHIL', 'PHYS', 'POLS', 'PREP', 'PSYC', 'THM','THR','TRIN'];
  
  // Selected departments
  List<String> selectedDepartments = [];

  // Payment plan options
  String paymentPlan = 'Per Hour';
  bool isPaymentPlanEnabled = false;
  // Update to disable price field when category is 'Donate' or 'Exchange'
  bool isPriceFieldDisabled() {
    return category == 'Donate' || category == 'Exchange';
  }

  bool get allSelected => selectedDepartments.length == departments.length;
  // Function to handle "All Departments" selection
   void toggleSelection() {
    setState(() {
      if (allSelected) {
        selectedDepartments = []; // Hepsini kaldır
      } else {
        selectedDepartments = List<String>.from(departments); // Hepsini seç
      }
    });
  }
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Upload Item'),
          backgroundColor: Colors.green, // AppBar'ın arka plan rengi
          foregroundColor: Colors.white, // AppBar'daki yazı ve ikon renkleri
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
            key: _formKey,
            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fotoğraf Yükleme
                const Text('Upload Photo* and Additional Photos', style: TextStyle(color: Colors.black)),
              
             Row(
              children: [
                _imageCover == null
                    ? Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: uploadCoverImagePlaceholder(),
                      )
                    : Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _imageCover!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                const SizedBox(width: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: addMorePhotosPlaceholder(),
                ),
              ],
            ),
                const SizedBox(height: 20),

                // Display additional images
                const Text('Additional Photos', style: TextStyle(color: Colors.black)),
                Wrap(
                  spacing: 8, // Horizontal spacing
                  runSpacing: 8, // Vertical spacing
                  children: _additionalImages
                      .map((image) => Stack(
                            clipBehavior: Clip.none, // To allow the button to go outside the image
                            children: [
                              // Display the image
                              Image.file(
                                image,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                              // Delete button
                              Positioned(
                                top: -7,
                                right: -7,
                                child: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _additionalImages.remove(image); // Remove the image from the list
                                    });
                                  },
                                ),
                              ),
                            ],
                          ))
                      .toList(),
                ),

                const SizedBox(height: 20),

                // Kategori Dropdown
                const Text('Category*', style: TextStyle(color: Colors.black)),
                DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  dropdownColor: Colors.white, // Dropdown arka plan rengi
                  items: ['Sale', 'Rent', 'Exchange', 'Donate']
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value, style: const TextStyle(color: Colors.black)),
                          ))
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      category = newValue!;
                      itemController.updatePriceField(category, itemController.priceController); // Controller'dan çağırıyoruz
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Başlık Alanı
                const Text('Title*', style: TextStyle(color: Colors.black)),
                TextFormField(
                  controller: itemController.titleController,
                  validator: (value) => itemController.validateTitle(value),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Enter title',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 10),

                // Açıklama Alanı
                const Text('Description', style: TextStyle(color: Colors.black)),
                TextFormField(
                  controller: itemController.descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Enter description',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 10),

                // Item Type Dropdown
                const Text('Item Type', style: TextStyle(color: Colors.black)),
                DropdownButton<String>(
                  value: itemType,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  items: [ 'Notes', 'Books', 'Electronics', 'Stationary', 'Other']
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value, style: const TextStyle(color: Colors.black)),
                          ))
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      itemType = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Departman Dropdown (Multi-Select)
const Text('Department', style: TextStyle(color: Colors.black)),
        MultiSelectDialogField(
          items: departments.map((dept) => MultiSelectItem(dept, dept)).toList(),
          initialValue: selectedDepartments,
          title: const Text("Departments"),
          buttonText: const Text("Select Departments"),
          searchable: true,
          listType: MultiSelectListType.CHIP,
          onConfirm: (results) {
            setState(() {
              selectedDepartments = List<String>.from(results);
            });
          },
          chipDisplay: MultiSelectChipDisplay(
            onTap: (item) {
              setState(() {
                selectedDepartments.remove(item);
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: toggleSelection,
          child: Text(allSelected ? "Deselect All" : "Select All"),
        ),



                // Şart Dropdown
                const Text('Condition', style: TextStyle(color: Colors.black)),
                DropdownButton<String>(
                  value: condition,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  items: (itemType == 'Other'
                          ? ['New', 'Lightly Used', 'Moderately Used', 'Heavily Used', '']
                          : ['New', 'Lightly Used', 'Moderately Used', 'Heavily Used'])
                      .map((value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(color: Colors.black)),
                          ))
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      condition = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 10),

              Row(
                children: [
                  // Price TextField
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Price* (₺)', style: TextStyle(color: Colors.black)),
                        TextFormField(
                        controller: itemController.priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          prefixText: '₺ ',
                          prefixStyle: const TextStyle(color: Colors.black),
                          hintText: 'Enter price',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                        ),
                        enabled: !isPriceFieldDisabled(), // Disable when category is 'Donate' or 'Exchange'
                        
                        // Hata: TextEditingController yerine doğru validator fonksiyonunu kullanıyoruz.
                        validator: (value) => itemController.validatePrice(value, category),
                      ),

                      ],
                    ),
                  ),
                  const SizedBox(width: 16), // Space between fields
              
                  // Payment Plan Dropdown with opacity change
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Plan', style: TextStyle(color: Colors.black)),
                        Opacity(
                          opacity: category == 'Rent' ? 1.0 : 0.5,  // Adjust opacity based on category
                          child: DropdownButton<String>(
                            value: paymentPlan,
                            isExpanded: true,
                            items: ['Per Hour', 'Per Day', 'Per Month']
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value, style: const TextStyle(color: Colors.black)),
                                    ))
                                .toList(),
                            onChanged: category == 'Rent'
                                ? (newValue) {
                                    setState(() {
                                      paymentPlan = newValue!;
                                    });
                                  }
                                : null, // Disable when Rent is not selected
                            disabledHint: const Text(
                              'Not available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

                const SizedBox(height: 20), // Add space between Price fields and the Upload button
                
                SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Buton arka plan rengi
                    foregroundColor: Colors.white, // Buton yazı rengi
                  ),
                  onPressed: _uploadItem,  // Fonksiyonu buraya eklemen gerekiyor
                  child: const Text('Upload Item'),
                ),
              ),

              ],
            ),
          ),
          ),
        ),
      );
    }
}
