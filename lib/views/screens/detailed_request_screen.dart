import 'package:bees/views/screens/others_user_profile_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:bees/models/request_model.dart';
import 'package:bees/models/user_model.dart' as bees;
import 'package:bees/controllers/request_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth_user;
import 'package:intl/intl.dart';

class DetailedRequestScreen extends StatelessWidget {
  final Request request;
  final RequestController _requestController = RequestController();

  final Color primaryYellow = const Color(0xFFFFC857);
  final Color textLight = Color(0xFF8A8A8A);
  final Color textDark = Color(0xFF333333);
  final Color backgroundColor = Color(0xFFFAFAFA);
  final Color cardColor = Colors.white;
  final Color accentColor = Color(0xFFFFC857);
  
  DetailedRequestScreen({Key? key, required this.request}) : super(key: key);

  void _navigateToUserProfile(String userId, BuildContext context) {
    if (userId == auth_user.FirebaseAuth.instance.currentUser!.uid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OthersUserProfileScreen(userId: userId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Request Details",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: textDark,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
      body: FutureBuilder<bees.User?>(
        future: _requestController.getUserByRequestID(request.requestID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                strokeWidth: 3,
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 48,
                    color: textLight,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "User not found",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textLight,
                    ),
                  ),
                ],
              ),
            );
          }

          bees.User user = snapshot.data!;
          
          return SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  color: cardColor,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStatusColor(request.requestStatus),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        _getStatusText(request.requestStatus),
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(request.requestStatus),
                        ),
                      ),
                      Spacer(),
                      
                    ],
                  ),
                ),
                
                SizedBox(height: 8),
                
                // User profile card
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 0),
                  padding: EdgeInsets.all(20),
                  color: cardColor,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToUserProfile(user.userID, context),
                        child: Hero(
                          tag: 'profile-${user.userID}',
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accentColor,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: user.profilePicture.isNotEmpty
                                  ? Image.network(
                                      user.profilePicture,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildProfileInitials(user);
                                      },
                                    )
                                  : _buildProfileInitials(user),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _navigateToUserProfile(user.userID, context),
                              child: Text(
                                "${user.firstName} ${user.lastName}",
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                _buildRatingStars(user.userRating),
                                SizedBox(width: 6),
                                Text(
                                  "${user.userRating.toStringAsFixed(1)}",
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                         
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Request content card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  color: cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Request Details",
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                          Spacer(),
                          Text(
                            _formatDateDetailed(request.creationDate),
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: textLight,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        
                        child: Text(
                          request.requestContent,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            height: 1.5,
                            color: textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 8),
                
                
                
               
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileInitials(bees.User user) {
    return Container(
      color: accentColor.withOpacity(0.2),
      child: Center(
        child: Text(
          "${user.firstName[0]}${user.lastName[0]}",
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, size: 14, color: accentColor);
        } else if (index < rating.ceil() && rating.floor() != rating.ceil()) {
          return Icon(Icons.star_half, size: 14, color: accentColor);
        } else {
          return Icon(Icons.star_border, size: 14, color: accentColor);
        }
      }),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _formatDateDetailed(DateTime date) {
    return DateFormat('MMM d, yyyy • HH:mm').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.blue[700]!;
      case 'completed':
        return Colors.green[700]!;
      case 'cancelled':
        return Colors.red[700]!;
      case 'pending':
        return Colors.orange[700]!;
      default:
        return Colors.blue[700]!;
    }
  }

  String _getStatusText(String status) {
    if (status.isEmpty) return "Active";
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }
}

class Math {
  static int min(int a, int b) => a < b ? a : b;
}