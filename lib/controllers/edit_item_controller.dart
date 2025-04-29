import 'package:bees/models/item_model.dart';
import 'package:bees/views/screens/edit_item_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bees/models/edit_item_model.dart';

class EditItemController extends ChangeNotifier {
  final EditItemModel model;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ImagePicker picker = ImagePicker();
  bool isLoading = false;

  EditItemController({required this.model});

  // Pick new photos from the gallery
  Future<void> pickPhotos() async {
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      model.newPhotos
          .addAll(pickedFiles.map((file) => File(file.path)).toList());
      notifyListeners();
    }
  }

  // Delete a photo
  void deletePhoto(int index) {
    model.deletePhoto(index);
    notifyListeners();
  }

  // Update title
  void updateTitle(String value) {
    model.editedItem.title = value;
    notifyListeners();
  }

  // Update description
  void updateDescription(String value) {
    model.editedItem.description = value;
    notifyListeners();
  }

  // Update price
  void updatePrice(String value) {
    model.editedItem.price = double.tryParse(value) ?? model.editedItem.price;
    notifyListeners();
  }

  // Update category
  void updateCategory(String? value) {
    model.updateCategory(value);
    notifyListeners();
  }

  // Update condition
  void updateCondition(String? value) {
    if (value != null) {
      model.editedItem.condition = value;
      notifyListeners();
    }
  }

  // Update item type
  void updateItemType(String? value) {
    if (value != null) {
      model.editedItem.itemType = value;
      notifyListeners();
    }
  }

  // Update payment plan
  void updatePaymentPlan(String? value) {
    if (value != null) {
      model.selectedPaymentPlan = value;
      model.editedItem.paymentPlan = value;
      notifyListeners();
    }
  }

  // Toggle department selection
  void toggleDepartment(String department) {
    model.toggleDepartment(department);
    notifyListeners();
  }

  // Validate title
  String? validateTitle(String? value) {
    return value?.isEmpty ?? true ? 'Title is required' : null;
  }

  // Validate price
  String? validatePrice(String? value) {
    if (value?.isEmpty ?? true) return 'Price is required';
    if (double.tryParse(value!) == null) return 'Invalid price';
    return null;
  }

  // Validate form
  bool validateForm(BuildContext context) {
    return model.validateForm(
      isFormValid: formKey.currentState?.validate() ?? false,
      showError: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  // Set loading state
  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  // Save item
  Future<bool> saveItem(BuildContext context) async {
    if (!validateForm(context)) {
      return false;
    }

    setLoading(true);

    try {
      await model.saveItem();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item updated successfully'),
            backgroundColor: const Color(0xFFFFD700),
          ),
        );
      }

      return true;
    } catch (e) {
      print('Error updating item: $e');

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return false;
    } finally {
      setLoading(false);
    }
  }

  // Check if category is sale or rent
  bool isSaleOrRent() {
    return model.editedItem.category == 'Sale' ||
        model.editedItem.category == 'Rent';
  }

  // Check if category is rent
  bool isRent() {
    return model.editedItem.category == 'Rent';
  }

  // Get all photos count
  int getTotalPhotosCount() {
    return model.photoUrls.length + model.newPhotos.length;
  }

  // Check if there are any photos
  bool hasPhotos() {
    return model.photoUrls.isNotEmpty || model.newPhotos.isNotEmpty;
  }

  // Check if a department is selected
  bool isDepartmentSelected(String department) {
    return model.selectedDepartments.contains(department);
  }

  // Get all departments
  List<String> getDepartments() {
    return model.departments;
  }

  // Get selected departments
  List<String> getSelectedDepartments() {
    return model.selectedDepartments;
  }

  // Get payment plans
  List<String> getPaymentPlans() {
    return model.paymentPlan;
  }

  // Get selected payment plan
  String getSelectedPaymentPlan() {
    return model.selectedPaymentPlan;
  }

  // Get categories
  List<String> getCategories() {
    return model.categories;
  }

  // Get conditions
  List<String> getConditions() {
    return model.conditions;
  }

  // Get item types
  List<String> getItemTypes() {
    return model.itemTypes;
  }
}
