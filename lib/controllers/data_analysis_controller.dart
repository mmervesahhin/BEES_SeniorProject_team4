import 'package:flutter/material.dart';

class DataAnalysisController extends ChangeNotifier {
  bool isLoading = false;

  DateTime? startDate;
  DateTime? endDate;

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
  bool canCreateReport(List<String> selectedItemTypes, List<String> selectedCategories) {
    return selectedItemTypes.isNotEmpty &&
        selectedCategories.isNotEmpty &&
        startDate != null &&
        endDate != null;
  }

  // Create report logic
  Future<void> createReport() async {
    
  }
  
  // Date formatting helper
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
