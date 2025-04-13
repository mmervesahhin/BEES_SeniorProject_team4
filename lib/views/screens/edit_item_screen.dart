import 'package:bees/controllers/edit_item_controller.dart';
import 'package:bees/models/edit_item_model.dart';
import 'package:flutter/material.dart';
import 'package:bees/models/item_model.dart';


class EditItemScreen extends StatefulWidget {
  final Item item;

  const EditItemScreen({Key? key, required this.item}) : super(key: key);

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  late EditItemModel _model;
  late EditItemController _controller;
  
  // Updated color palette
  final Color primaryColor = const Color(0xFFFFD700); // Vibrant yellow
  final Color secondaryColor = const Color(0xFFFFF8E1); // Light yellow
  final Color textColor = const Color(0xFF000000); // Black
  final Color errorColor = const Color(0xFFFF5252); // Red for errors
  final Color accentColor = const Color(0xFF333333); // Dark gray

  @override
  void initState() {
    super.initState();
    _model = EditItemModel(originalItem: widget.item);
    _controller = EditItemController(model: _model);
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
      body: _controller.isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))) 
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _controller.formKey,
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
                  initialValue: _model.editedItem.title,
                  labelText: 'Title',
                  validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
                  onChanged: (value) => setState(() => _model.editedItem.title = value),
                ),
                const SizedBox(height: 16),

                // Description Field
                _buildFormField(
                  initialValue: _model.editedItem.description,
                  labelText: 'Description',
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true ? null : null,
                  onChanged: (value) => setState(() => _model.editedItem.description = value),
                ),
                const SizedBox(height: 24),

                // Pricing & Category
                _buildSectionTitle('Pricing & Details'),
                const SizedBox(height: 8),

                // Item Type (Sale/Rent/Exchange/Donate)
                _buildDropdownField(
                  value: _model.editedItem.category ?? _model.categories[0],
                  labelText: 'Category',
                  items: _model.categories,
                  onChanged: (value) {
                    setState(() {
                      _controller.updateCategory(value);
                    });
                  },
                ),
                const SizedBox(height: 16),

                if (_model.editedItem.category == 'Sale' || _model.editedItem.category == 'Rent')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Price Input Field
                          Expanded(
                            child: _buildFormField(
                              initialValue: _model.editedItem.price.toString(),
                              labelText: 'Price',
                              keyboardType: TextInputType.number,
                              prefixIcon: const Icon(Icons.currency_lira, color: Colors.black),
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Price is required';
                                if (double.tryParse(value!) == null) return 'Invalid price';
                                return null;
                              },
                              onChanged: (value) => setState(() => _model.editedItem.price = double.tryParse(value) ?? _model.editedItem.price),
                            ),
                          ),

                          // Show payment plan dropdown if category is Rent
                          if (_model.editedItem.category == 'Rent')
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Row(
                                children: [
                                  Text("/", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  DropdownButton<String>(
                                    value: _model.selectedPaymentPlan,
                                    items: _model.paymentPlan.map((String duration) {
                                      return DropdownMenuItem<String>(
                                        value: duration,
                                        child: Text(duration),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _controller.updatePaymentPlan(value);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Condition Dropdown
                _buildDropdownField(
                  value: _model.editedItem.condition,
                  labelText: 'Condition',
                  items: _model.conditions,
                  onChanged: (value) {
                    setState(() {
                      if (value != null) _model.editedItem.condition = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // ItemType Dropdown
                _buildDropdownField(
                  value: _model.editedItem.itemType,
                  labelText: 'Item Type',
                  items: _model.itemTypes,
                  onChanged: (value) {
                    setState(() {
                      if (value != null) _model.editedItem.itemType = value;
                    });
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
                    onPressed: _controller.isLoading ? null : _saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: _controller.isLoading
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

  Future<void> _saveItem() async {
    setState(() {
      _controller.isLoading = true;
    });
    
    final success = await _controller.saveItem(context);
    
    setState(() {
      _controller.isLoading = false;
    });
    
    if (success) {
      // Show success message and close screen
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item updated successfully'),
          backgroundColor: primaryColor,
        ),
      );
    }
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
                  for (int i = 0; i < _model.photoUrls.length; i++)
                    _buildPhotoTile(
                      isNetwork: true,
                      source: _model.photoUrls[i],
                      onDelete: () => setState(() => _controller.deletePhoto(i)),
                    ),

                  // Display new photos
                  for (int i = 0; i < _model.newPhotos.length; i++)
                    _buildPhotoTile(
                      isNetwork: false,
                      source: _model.newPhotos[i],
                      onDelete: () => setState(() => _controller.deletePhoto(_model.photoUrls.length + i)),
                    ),

                  // Add Photo Button
                  GestureDetector(
                    onTap: () async {
                      await _controller.pickPhotos();
                      setState(() {});
                    },
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
        if (_model.photoUrls.isEmpty && _model.newPhotos.isEmpty)
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
      padding: const EdgeInsets.all(10),
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
          const SizedBox(height: 12, width: 10,),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _model.departments.map((department) {
              final isSelected = _model.selectedDepartments.contains(department);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.toggleDepartment(department);
                  });
                },
                child: Container(
                  width: 70, // Set a fixed width
                  height: 30, // Set a fixed height
                  alignment: Alignment.center, // Center the text
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
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis, // Handle overflow
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}