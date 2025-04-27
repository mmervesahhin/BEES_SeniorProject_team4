import 'package:flutter/material.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/detailed_item_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class UploadSuccessPage extends StatefulWidget {
  final String itemId;

  const UploadSuccessPage({Key? key, required this.itemId}) : super(key: key);

  @override
  State<UploadSuccessPage> createState() => _UploadSuccessPageState();
}

class _UploadSuccessPageState extends State<UploadSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showContent = false;

  // Color scheme
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );

    // Start animation after a short delay
    Timer(Duration(milliseconds: 300), () {
      _animationController.forward();
    });

    // Show content with a slight delay after animation starts
    Timer(Duration(milliseconds: 800), () {
      setState(() {
        _showContent = true;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  backgroundColor,
                ],
              ),
            ),
          ),
          
          // Success content
          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/app_icon.png', // Replace with your app logo
                        height: 40,
                        
                      ),
                      
                      
                    ],
                  ),
                ),
                
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _showContent ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 500),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Container(
                            height: 200,
                            width: 200,
                            child: Lottie.asset(
                              'assets/success_animation.json', // animation koymayı dene
                              controller: _animationController,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => 
                                _buildFallbackAnimation(),
                            ),
                          ),
                          ),
                          
                          // Success animation
                          
                          
                          // Success message
                          Text(
                            'Item Successfully Uploaded!',
                            style: GoogleFonts.nunito(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          
                          // Success description
                          Text(
                            'Your item is now live and visible to all users. You can view it or return to the home screen.',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: textLight,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 40),
                          
                          // Action buttons
                          Row(
                            children: [
                              // View Item button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailedItemScreen(itemId: widget.itemId),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.visibility),
                                  label: Text('View Item'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryYellow,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              
                              // Home button
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                                      (route) => false,
                                    );
                                  },
                                  icon: Icon(Icons.home),
                                  label: Text('Home'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textDark,
                                    side: BorderSide(color: textLight.withOpacity(0.3)),
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Bottom info section
                AnimatedOpacity(
                  opacity: _showContent ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 500),
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'What happens next?',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildNextStep(
                          icon: Icons.visibility,
                          title: 'Users can now see your item',
                          description: 'Your item is visible in search results and browsing',
                        ),
                        SizedBox(height: 12),
                        _buildNextStep(
                          icon: Icons.notifications,
                          title: 'You\'ll get notified',
                          description: 'When someone is interested in your item',
                        ),
                        SizedBox(height: 12),
                        _buildNextStep(
                          icon: Icons.edit,
                          title: 'You can edit anytime',
                          description: 'Update details from your profile page',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(seconds: 1),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryYellow.withOpacity(0.2),
          ),
          child: Center(
            child: Icon(
              Icons.check_circle,
              color: primaryYellow,
              size: 100 * value,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNextStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: lightYellow,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: primaryYellow),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
