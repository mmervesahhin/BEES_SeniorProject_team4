import 'package:bees/controllers/edit_item_controller.dart';
import 'package:bees/models/edit_item_model.dart';
import 'package:flutter/material.dart';
import 'package:bees/models/item_model.dart';
import 'package:google_fonts/google_fonts.dart';

class EditItemScreen extends StatefulWidget {
  final Item item;

  const EditItemScreen({Key? key, required this.item}) : super(key: key);

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  late EditItemModel _model;
  late EditItemController _controller;

  // Updated color palette to match other screens
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();
    _model = EditItemModel(originalItem: widget.item);
    _controller = EditItemController(model: _model);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Item',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: textDark),
      ),
      body: _controller.isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _controller.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo Section
                          _buildSectionTitle('Photos (Required)'),
                          const SizedBox(height: 12),
                          _buildPhotoSection(),
                          const SizedBox(height: 24),

                          // Basic Information
                          _buildSectionTitle('Item Information'),
                          const SizedBox(height: 12),

                          // Title Field
                          _buildFormField(
                            initialValue: _model.editedItem.title,
                            labelText: 'Title',
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Title is required'
                                : null,
                            onChanged: (value) =>
                                setState(() => _model.editedItem.title = value),
                          ),
                          const SizedBox(height: 16),

                          // Description Field
                          _buildFormField(
                            initialValue: _model.editedItem.description,
                            labelText: 'Description',
                            maxLines: 3,
                            validator: (value) => null,
                            onChanged: (value) => setState(
                                () => _model.editedItem.description = value),
                          ),
                          const SizedBox(height: 24),

                          // Pricing & Category
                          _buildSectionTitle('Pricing & Details'),
                          const SizedBox(height: 12),

                          // Item Type (Sale/Rent/Exchange/Donate)
                          _buildDropdownField(
                            value: _model.editedItem.category ??
                                _model.categories[0],
                            labelText: 'Category',
                            items: _model.categories,
                            onChanged: (value) {
                              setState(() {
                                _controller.updateCategory(value);
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          if (_model.editedItem.category == 'Sale' ||
                              _model.editedItem.category == 'Rent')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Price Input Field
                                    Expanded(
                                      child: _buildFormField(
                                        initialValue:
                                            _model.editedItem.price.toString(),
                                        labelText: 'Price',
                                        keyboardType: TextInputType.number,
                                        prefixIcon: Icon(Icons.currency_lira,
                                            color: textLight),
                                        validator: (value) {
                                          if (value?.isEmpty ?? true)
                                            return 'Price is required';
                                          if (double.tryParse(value!) == null)
                                            return 'Invalid price';
                                          return null;
                                        },
                                        onChanged: (value) => setState(() =>
                                            _model.editedItem.price =
                                                double.tryParse(value) ??
                                                    _model.editedItem.price),
                                      ),
                                    ),

                                    // Show payment plan dropdown if category is Rent
                                    if (_model.editedItem.category == 'Rent')
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Row(
                                          children: [
                                            Text("/",
                                                style: GoogleFonts.nunito(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: textDark)),
                                            DropdownButton<String>(
                                              value: _model.selectedPaymentPlan,
                                              items: _model.paymentPlan
                                                  .map((String duration) {
                                                return DropdownMenuItem<String>(
                                                  value: duration,
                                                  child: Text(duration,
                                                      style: GoogleFonts.nunito(
                                                          color: textDark)),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  _controller
                                                      .updatePaymentPlan(value);
                                                });
                                              },
                                              dropdownColor: Colors.white,
                                              icon: Icon(Icons.arrow_drop_down,
                                                  color: primaryYellow),
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
                                if (value != null)
                                  _model.editedItem.condition = value;
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
                                if (value != null)
                                  _model.editedItem.itemType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          // Departments Section
                          _buildSectionTitle('Relevant Departments'),
                          const SizedBox(height: 12),
                          _buildDepartmentsSelector(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _controller.isLoading ? null : _saveItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryYellow,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _controller.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Save Changes',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
          content: Text(
            'Item updated successfully',
            style: GoogleFonts.nunito(color: textDark),
          ),
          backgroundColor: lightYellow,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: primaryYellow, size: 20),
              SizedBox(width: 8),
              Text(
                'Add at least one photo of your item',
                style: GoogleFonts.nunito(
                  color: textLight,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  onDelete: () => setState(() =>
                      _controller.deletePhoto(_model.photoUrls.length + i)),
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
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryYellow.withOpacity(0.5),
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 32,
                        color: primaryYellow,
                      ),
                      const SizedBox(height: 8),
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
              ),
            ],
          ),
          if (_model.photoUrls.isEmpty && _model.newPhotos.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red[400], size: 16),
                  SizedBox(width: 8),
                  Text(
                    'At least one photo is required',
                    style: GoogleFonts.nunito(
                      color: Colors.red[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(primaryYellow),
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: backgroundColor,
                      child: Icon(
                        Icons.broken_image,
                        color: textLight,
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
        labelStyle: GoogleFonts.nunito(color: textLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryYellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red[400]!, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: prefixIcon,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.nunito(color: textDark),
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
        labelStyle: GoogleFonts.nunito(color: textLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryYellow, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: GoogleFonts.nunito(color: textDark)),
        );
      }).toList(),
      onChanged: onChanged,
      icon: Icon(Icons.arrow_drop_down, color: primaryYellow),
      style: GoogleFonts.nunito(color: textDark),
      dropdownColor: Colors.white,
    );
  }

  Widget _buildDepartmentsSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: primaryYellow, size: 20),
              SizedBox(width: 8),
              Text(
                'Select departments relevant to this item:',
                style: GoogleFonts.nunito(
                  color: textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _model.departments.map((department) {
              final isSelected =
                  _model.selectedDepartments.contains(department);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.toggleDepartment(department);
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryYellow : backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? primaryYellow : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    department,
                    style: GoogleFonts.nunito(
                      color: isSelected ? Colors.white : textDark,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
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
