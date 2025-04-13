import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bees/controllers/notification_controller.dart';

class RatingDialog extends StatefulWidget {
  final String sellerId;
  final String itemId;
  final String itemTitle;
  final String notificationId;
  final Color primaryColor;
  final Function? onRatingSubmitted;

  const RatingDialog({
    Key? key,
    required this.sellerId,
    required this.itemId,
    required this.itemTitle,
    required this.notificationId,
    this.primaryColor = const Color(0xFF3B893E),
    this.onRatingSubmitted,
  }) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final NotificationController _controller = NotificationController();
  double _rating = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Rate Your Experience',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.primaryColor,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'How was your experience with the seller for "${widget.itemTitle}"?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          RatingBar.builder(
            initialRating: _rating,
            minRating: 0,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _rating = rating;
                _errorMessage = null;
              });
            },
          ),
          const SizedBox(height: 10),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _isSubmitting || _rating == 0
                    ? null
                    : () async {
                        if (_rating == 0) {
                          setState(() {
                            _errorMessage = 'Please select a rating';
                          });
                          return;
                        }

                        setState(() {
                          _isSubmitting = true;
                          _errorMessage = null;
                        });

                        try {
                          await _controller.submitRating(
                            sellerId: widget.sellerId,
                            rating: _rating,
                            notificationId: widget.notificationId,
                            itemId: widget.itemId,
                          );
                          
                          if (widget.onRatingSubmitted != null) {
                            widget.onRatingSubmitted!();
                          }
                          
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Thank you for your rating!',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: widget.primaryColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setState(() {
                              _isSubmitting = false;
                              _errorMessage = 'Failed to submit rating. Please try again.';
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

