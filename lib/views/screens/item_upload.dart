import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '/views/screens/item_upload_success.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // InputFormatter için gerekli
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
    Future<void> uploadItemToFirestore(
      String title,
      String description,
      String category,
      String condition,
      String itemType,
      List<String> departments,
      double price,
      File? imageFile,
      String? paymentPlan, // Payment Plan 
  ) async {
    try {
      // Resmi Firebase Storage'a yükle
      String? imageUrl;
      if (imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('item_images')
            .child('${DateTime.now().toIso8601String()}.jpg');

        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      // Firestore'a belge ekle
      await FirebaseFirestore.instance.collection('items').add({
        'title': title,
        'description': description,
        'category': category,
        'condition': condition,
        'itemType': itemType,
        'departments': departments,
        'price': price,
        'paymentPlan': paymentPlan, // Payment Plan
        'photo': imageUrl,
      });

      print('Item successfully uploaded to Firestore!');
    } catch (e) {
      print('Failed to upload item: $e');
    }
  }

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

  // Function to handle "All Departments" selection
  void toggleAllDepartments(bool isSelected) {
    setState(() {
      if (isSelected) {
        // Select all departments
        selectedDepartments = List<String>.from(departments);
      } else {
        // Deselect all departments
        selectedDepartments.clear();
      }
    });
  }
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Upload Item'),
          centerTitle: true,
          backgroundColor: Colors.green, // AppBar'ın arka plan rengi
          foregroundColor: Colors.white, // AppBar'daki yazı ve ikon renkleri
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fotoğraf Yükleme
                const Text('Upload Photo', style: TextStyle(color: Colors.black)),
                Row(
                  children: [
                    _image == null
                        ? uploadImagePlaceholder() // Eğer resim yoksa placeholder göster
                        : Image.file(
                            _image!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ), // Resim varsa göster
                    const SizedBox(width: 16),
                    uploadImagePlaceholder(),
                  ],
                ),
                const SizedBox(height: 20),

                // Kategori Dropdown
                const Text('Category', style: TextStyle(color: Colors.black)),
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
                      updatePriceField(); // Fiyat alanını güncelle
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Başlık Alanı
                const Text('Title', style: TextStyle(color: Colors.black)),
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Enter title',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                if (_isTitleEmpty)
                  const Text(
                    'Please fill in the title',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                const SizedBox(height: 10),

                // Açıklama Alanı
                const Text('Description', style: TextStyle(color: Colors.black)),
                TextFormField(
                  controller: descriptionController,
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
                  items: ['Other', 'Electronic', 'Stationary', 'Book', 'Note']
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
                  items: [
                    MultiSelectItem('All Departments', 'All Departments'),
                    ...departments.map((dept) => MultiSelectItem(dept, dept)).toList(),
                  ],
                  initialValue: selectedDepartments,
                  title: const Text("Departments"),
                  buttonText: const Text("Select Departments"),
                  onConfirm: (results) {
                  setState(() {
                    if (results.contains('All Departments')) {
                      selectedDepartments = List<String>.from(departments); // Tüm departmanları ekler
                    } else {
                      selectedDepartments = 
                          List<String>.from(results.where((item) => item != 'All Departments')); // Sadece seçili olanları ekler
                    }
                  });
                },
                  chipDisplay: MultiSelectChipDisplay(
                  onTap: (item) {
                    setState(() {
                      selectedDepartments.remove(item);
                    });
                  },
                ),
                searchable: true,
                listType: MultiSelectListType.CHIP,

                onSelectionChanged: (results) {
                setState(() {
                  if (results.contains('All Departments')) {
            selectedDepartments = List.from(departments);
                  } else {
                    selectedDepartments = results
                    .where((item) => item != 'All Departments')
                    .map((item) => item as String) // Türü açıkça belirt
                    .toList();
                  }
                });
              },
                ),
                const SizedBox(height: 10),

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
                  // Payment Plan Dropdown
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Plan', style: TextStyle(color: Colors.black)),
                        DropdownButton<String>(
                          value: paymentPlan,
                          isExpanded: true,
                          items: ['Per Hour', 'Per Day']
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
                              : null, // Eğer Rent seçili değilse disable
                          disabledHint: const Text(
                            'Not available',
                            style: TextStyle(color: Colors.grey),
                          ), // Devre dışı olduğunda gösterilecek metin
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16), // İki alan arasında boşluk
                  // Price TextField
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Price (₺)', style: TextStyle(color: Colors.black)),
                        TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            prefixText: '₺ ',
                            prefixStyle: const TextStyle(color: Colors.black),
                            hintText: 'Enter price',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                const SizedBox(height: 20),

                // Yükleme Butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Buton arka plan rengi
                      foregroundColor: Colors.white, // Buton yazı rengi
                    ),
                    onPressed: () async {
                      setState(() {
                        _isTitleEmpty = titleController.text.isEmpty;
                        _isPriceEmpty = priceController.text.isEmpty;
                        _isPriceInvalid = !_isPriceEmpty &&
                            (double.tryParse(priceController.text) == null ||
                                double.parse(priceController.text) <= 0);
                        if (!_isTitleEmpty && !_isPriceEmpty && !_isPriceInvalid ) {

                              uploadItemToFirestore( // burda aslında await olmalı ama bi türlü çalışmadığı için çıkarttım
                          titleController.text,
                          descriptionController.text,
                          category,
                          condition,
                          itemType,
                          selectedDepartments,
                          double.parse(priceController.text),
                          _image,
                          category == 'Rent' ? paymentPlan : null, // Rent değilse null gönderiliyor
                        );

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => UploadSuccessPage()),
                          );
                        }
                      });
                    },
                    child: const Text('Upload Item'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

}
