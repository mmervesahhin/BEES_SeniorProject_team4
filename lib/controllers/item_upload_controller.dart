import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';
import '../views/screens/item_upload_success_screen.dart';

class ItemController {
  // Firestore ve Firebase Storage referansları
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // TextEditingController'lar
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  // Validatorlar
  String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please fill in the title';
    }
    return null;
  }
  // Kategoriye göre fiyat alanını güncelle
  void updatePriceField(String category, TextEditingController priceController) {
    if (category == 'Exchange' || category == 'Donate') {
      priceController.text = '0';
    } else {
      priceController.clear(); // Alanı boşalt
    }
  }

  String? validatePrice(String? value, String category) {
    if (value == null || value.isEmpty) {
      return 'Please enter the price';
    }
    final price = double.tryParse(value);
    if ((category == 'Sale' || category == 'Rent') && (price == null || price <= 0)) {
      return 'Price must be greater than 0';
    }
    return null;
  }

  bool validateCoverPhoto(File? imageFileCover) {
    return imageFileCover != null;
  }



  // Yeni Ürün Yükleme
  Future<void> uploadItem(Item item, File? imageFileCover, List<File> additionalImages) async {
    try {
      // Kullanıcının UID'sini al
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('Error: User is not logged in.');
        return;
      }
      // 1. Ana Resmi Firebase Storage'a Yükleme
      String? imageUrlCover;
      if (imageFileCover != null) {
        imageUrlCover = await _uploadImageToStorage(imageFileCover, "cover_\${DateTime.now().millisecondsSinceEpoch}.jpg");
      }

      // 2. Ek Resimleri Yükleme
      List<String> additionalImageUrls = [];
      for (File image in additionalImages) {
        String imageUrl = await _uploadImageToStorage(image, "additional_\${DateTime.now().millisecondsSinceEpoch}.jpg");
        additionalImageUrls.add(imageUrl);
      }

      // 3. Firestore'a Ürün Verisi Ekleme
      // DocumentReference docRef = await _firestore.collection('items').add({
      //   ...item.toJson(),
      //   'photo': imageUrlCover,
      //   'additionalPhotos': additionalImageUrls,
      //   'itemOwnerId': userId, 
      // });

          String itemId = _firestore.collection('items').doc().id;


          // **Firestore'a `itemId` ile ekleme (add() yerine set() kullanıyoruz)**
          await _firestore.collection('items').doc(itemId).set({
            ...item.toJson(),
            'itemId': itemId, // **Firestore'un oluşturduğu ID `itemId` olarak kaydedildi**
            'itemOwnerId': userId, // Kullanıcı ID
            'photo': imageUrlCover,
            'additionalPhotos': additionalImageUrls,
          });


      //String itemId = docRef.id; // Firestore'un oluşturduğu belge ID
      print('Item successfully uploaded!');
    } catch (e) {
      print('Upload failed: \$e');
    }
  }

  Future<void> validateAndUploadItem({
    required String category,
    required String condition,
    required File? coverImage,
    required List<File> additionalImages,
    required List<String> selectedDepartments,
    required BuildContext context,
  }) async {

       // Kullanıcı UID'sini al
     String? userId = FirebaseAuth.instance.currentUser?.uid;
     if (userId == null) {
       print('Error: User is not logged in.');
       return;
     }
     
      String itemId = FirebaseFirestore.instance.collection('items').doc().id;
    String? titleError = validateTitle(titleController.text);
    String? priceError = validatePrice(priceController.text, category);
    bool isCoverPhotoMissing = !validateCoverPhoto(coverImage);
// && !isCoverPhotoMissing
    if (titleError == null && priceError == null  ) {
      Item newItem = Item(
      itemOwnerId: userId , // Sahip ID'si atanmalı
      itemId: itemId,
      title: titleController.text,
      description: descriptionController.text,
      category: category,
      condition: condition,
      itemType: '', // Eksik olan itemType burada belirtilmeli
      departments: selectedDepartments,
      price: double.parse(priceController.text),
      paymentPlan: category == 'Rent' ? 'Per Day' : null, // Kira seçeneği için eklendi
      photoUrl: null, // Varsayılan olarak boş bırakıldı, eklenecekse ayarlanmalı
      additionalPhotos: [], // Varsayılan olarak boş liste
      favoriteCount: 0, // Yeni oluşturulan öğe için favori sayısı sıfır olarak ayarlandı
      itemStatus: "active", 
    );

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      await uploadItem(newItem, coverImage, additionalImages);

      Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UploadSuccessPage(itemId: itemId)), // Pass itemId
    );
      Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UploadSuccessPage(itemId: itemId)),
    );


    } 
  }

  /// **Kapak Resmi Seçme ve Boyut Doğrulama**
  Future<File?> pickCoverImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final selectedImage = File(pickedFile.path);
      if (isImageSizeValid(selectedImage)) {
        return selectedImage;
      } else {
        throw Exception('The selected image exceeds the 5MB size limit.');
      }
    }
    return null;
  }

  /// **Resim Seçme ve Boyut Doğrulama (Ek Resimler için)**
  Future<File?> pickAdditionalImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final selectedImage = File(pickedFile.path);
      if (isImageSizeValid(selectedImage)) {
        return selectedImage;
      } else {
        throw Exception('The selected image exceeds the 5MB size limit.');
      }
    }
    return null;
  }

  /// **Resim Boyutu Doğrulama (5MB sınırı)**
  bool isImageSizeValid(File imageFile) {
    const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
    final fileSize = imageFile.lengthSync();
    return fileSize <= maxSizeInBytes;
  }

  // Firebase Storage'a Resim Yükleme ve URL Alma
  Future<String> _uploadImageToStorage(File image, String fileName) async {
    final ref = _storage.ref().child('item_images').child(fileName);
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  // Bellek sızıntısını önlemek için controller'ları serbest bırak
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
  }

}
