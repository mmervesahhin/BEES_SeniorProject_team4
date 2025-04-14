import 'package:flutter/material.dart';
import 'package:bees/models/request_model.dart';
import 'package:bees/controllers/request_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  _CreateRequestScreenState createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final RequestController _requestController = RequestController();
  bool _isSubmitting = false;
  
  // App colors
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);
  
  final FocusNode _descriptionFocusNode = FocusNode();
  bool _isDescriptionFocused = false;

  @override
  void initState() {
    super.initState();
    _descriptionFocusNode.addListener(() {
      setState(() {
        _isDescriptionFocused = _descriptionFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      
      try {
        final newRequest = Request(
          requestID: "", // Firestore will generate the ID
          requestOwnerID: "", 
          requestContent: _descriptionController.text.trim(),
          requestStatus: "active",
          creationDate: DateTime.now(),
        );

        await _requestController.createRequest(newRequest);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    "Request created successfully!",
                    style: GoogleFonts.nunito(),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: primaryYellow,
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Failed to create request: ${e.toString()}",
                      style: GoogleFonts.nunito(),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.red[700],
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Create Request",
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textDark, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightYellow.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: primaryYellow,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Create a request to ask for items or services from the BEES community.",
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: textDark,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description label
                  Text(
                    "Request Description",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Description text field
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDescriptionFocused ? primaryYellow : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      boxShadow: _isDescriptionFocused
                          ? [
                              BoxShadow(
                                color: primaryYellow.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: TextFormField(
                      controller: _descriptionController,
                      focusNode: _descriptionFocusNode,
                      maxLines: 6,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: textDark,
                      ),
                      decoration: InputDecoration(
                        hintText: "Describe what you're looking for...",
                        hintStyle: GoogleFonts.nunito(
                          color: textLight,
                          fontSize: 15,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter a description";
                        }
                        if (value.trim().length < 10) {
                          return "Description should be at least 10 characters";
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Character count
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${_descriptionController.text.length} characters",
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: textLight,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primaryYellow.withOpacity(0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Submit Request",
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: lightYellow.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryYellow, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: textLight,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
