import 'package:bees/models/item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class EditItemModel {
  final Item originalItem;
  late Item editedItem;
  
  // Available options for dropdowns
  final List<String> conditions = ['New', 'Lightly Used', 'Moderately Used', 'Heavily Used'];
  final List<String> categories = ['Sale', 'Rent', 'Exchange', 'Donate'];
  final List<String> itemTypes = ['Notes', 'Books', 'Electronics', 'Stationary', 'Other'];
  final List<String> departments = ['AMER', 'ARCH', 'CHEM', 'COMD', 'CS', 'CTIS', 'ECON', 'EDU', 'EEE', 'ELIT', 'FA', 'GRA', 'HART', 'IAED', 'IE', 'IR', 'LAUD', 'LAW', 'MAN', 'MATH', 'MBG', 'ME', 'MSC', 'PHIL', 'PHYS', 'POLS', 'PREP', 'PSYC', 'THM','THR','TRIN'];
  final List<String> paymentPlan = ['Per Hour', 'Per Day', 'Per Month'];
  
  List<String> photoUrls = []; // Existing photo URLs from Firestore
  List<File> newPhotos = []; // New photos selected by the user
  List<String> deletedPhotoUrls = []; // URLs of photos to be deleted
  List<String> selectedDepartments = [];
  String selectedPaymentPlan = ''; // Default
  
  EditItemModel({required this.originalItem}) {
    // Initialize edited item with original item data
    editedItem = Item(
      itemId: originalItem.itemId,
      itemOwnerId: originalItem.itemOwnerId,
      title: originalItem.title,
      description: originalItem.description,
      category: originalItem.category,
      condition: originalItem.condition,
      itemType: originalItem.itemType,
      departments: originalItem.departments,
      price: originalItem.price,
      paymentPlan: originalItem.paymentPlan,
      photoUrl: originalItem.photoUrl,
      additionalPhotos: originalItem.additionalPhotos,
      favoriteCount: originalItem.favoriteCount,
      itemStatus: originalItem.itemStatus,
    );
    
    // Initialize with existing photos
    if (originalItem.photoUrl != null && originalItem.photoUrl!.isNotEmpty) {
      photoUrls = [originalItem.photoUrl!];
    }
    
    if (originalItem.additionalPhotos != null) {
      photoUrls.addAll(originalItem.additionalPhotos!);
    }
    
    // Initialize selected departments
    selectedDepartments = List.from(originalItem.departments ?? []);
    
    // Initialize payment plan if available
    if (originalItem.paymentPlan != null) {
      selectedPaymentPlan = originalItem.paymentPlan!;
    }
  }
  
  // Compress image to reduce storage usage and improve loading speed
  Future<Uint8List> compressImage(File imageFile) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    // Here you would typically use a package like flutter_image_compress
    // For simplicity, we're just returning the bytes directly
    return bytes;
  }
  
  // Upload new photos to Firebase Storage
  Future<List<String>> uploadPhotos(List<File> photos) async {
    List<String> uploadedUrls = [];
    for (var photo in photos) {
      final String fileName = '${editedItem.itemId}_${DateTime.now().millisecondsSinceEpoch}';
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
  
  // Delete photos from Firebase Storage
  Future<void> deletePhotos(List<String> photoUrls) async {
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
  
  // Save item to Firestore
  Future<void> saveItem() async {
    // Upload new photos
    List<String> newPhotoUrls = await uploadPhotos(newPhotos);
    
    // Delete removed photos
    if (deletedPhotoUrls.isNotEmpty) {
      await deletePhotos(deletedPhotoUrls);
    }
    
    // Update item with new photo URLs
    if (photoUrls.isEmpty && newPhotoUrls.isNotEmpty) {
      // If there are no existing photos but new ones were added,
      // set the first new photo as the main photo
      editedItem.photoUrl = newPhotoUrls.first;
      newPhotoUrls.removeAt(0);
    }
    
    // Combine existing and new additional photos
    List<String> allAdditionalPhotos = [...photoUrls];
    if (editedItem.photoUrl != null && photoUrls.contains(editedItem.photoUrl)) {
      // Remove main photo from additional photos if it exists there
      allAdditionalPhotos.remove(editedItem.photoUrl);
    }
    allAdditionalPhotos.addAll(newPhotoUrls);
    
    // Update the item with all photos
    editedItem.additionalPhotos = allAdditionalPhotos.isEmpty ? null : allAdditionalPhotos;
    
    // Update item in Firestore
    await FirebaseFirestore.instance
        .collection('items')
        .doc(editedItem.itemId)
        .update(editedItem.toJson());
  }
  
  // Validate form data
  bool validateForm({
    required bool isFormValid,
    required Function(String) showError,
  }) {
    // Check if form is valid
    if (!isFormValid) {
      return false;
    }
    
    // Check if at least one photo is present
    if (photoUrls.isEmpty && newPhotos.isEmpty) {
      showError('Please add at least one photo');
      return false;
    }
    
    // Check if at least one department is selected
    if (selectedDepartments.isEmpty) {
      showError('Please select at least one department');
      return false;
    }
    
    return true;
  }
  
  // Update category and handle price logic
  void updateCategory(String? value) {
    if (value != null) {
      editedItem.category = value;
      
      // Set price to 0 if category is "Donate" or "Exchange"
      if (value == 'Donate' || value == 'Exchange') {
        editedItem.price = 0;
      }
    }
  }
  
  // Toggle department selection
  void toggleDepartment(String department) {
    if (selectedDepartments.contains(department)) {
      selectedDepartments.remove(department);
    } else {
      selectedDepartments.add(department);
    }
    editedItem.departments = selectedDepartments;
  }
  
  // Delete photo
  void deletePhoto(int index) {
    if (index < photoUrls.length) {
      deletedPhotoUrls.add(photoUrls[index]); // Add to deleted list
      photoUrls.removeAt(index); // Remove from displayed list
    } else {
      newPhotos.removeAt(index - photoUrls.length); // Remove from new photos
    }
  }
}