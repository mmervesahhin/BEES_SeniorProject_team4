import 'package:flutter/material.dart';

class DataAnalysisController extends ChangeNotifier {
  bool isLoading = false;

  DateTime? startDate;
  DateTime? endDate;

  List<String> itemTypes = ['Books', 'Notes', 'Stationery', 'Electronics', 'Others'];
  List<String> categories = ['Sale', 'Rent', 'Exchange', 'Donation'];

  List<String> selectedItemTypes = [];
  List<String> selectedCategories = [];

Future<DateTime?> selectStartDate(BuildContext context) async {
  DateTime? picked = await showDatePicker(
    context: context,
    initialDate: startDate ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );
  return picked;
}

Future<DateTime?> selectEndDate(BuildContext context) async {
  DateTime? picked = await showDatePicker(
    context: context,
    initialDate: endDate ?? DateTime.now(),
    firstDate: startDate ?? DateTime.now(),  // Prevents picking an earlier date
    lastDate: DateTime(2101),
  );

  return picked;
}

  // Check if the report can be created
  bool canCreateReport() {
    return selectedItemTypes.isNotEmpty &&
        selectedCategories.isNotEmpty &&
        startDate != null &&
        endDate != null;
  }

  // Create report logic
  Future<void> createReport() async {
    
  }

  // Filter chip selection
  void toggleSelectedItemType(String itemType) {
    if (selectedItemTypes.contains(itemType)) {
      selectedItemTypes.remove(itemType);
    } else {
      selectedItemTypes.add(itemType);
    }
    notifyListeners();
  }

  void toggleSelectedCategory(String category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
    notifyListeners();
  }

  // Date formatting helper
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
