import 'package:bees/controllers/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bees/views/screens/message_screen.dart';

import 'package:bees/models/item_model.dart';
import 'package:bees/models/request_model.dart';


class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationController _controller = NotificationController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? get userId => FirebaseAuth.instance.currentUser?.uid;
  
  // Color scheme
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);
  
  Future<Map<String, dynamic>?> fetchEntity(String itemId, String entityType) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(entityType == "Item" ? "items" : "requests")
          .doc(itemId)
          .get();

      return doc.data(); // Returns Map<String, dynamic>
    } catch (e) {
      print("❌ Entity fetch failed: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where('receiverId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
              )
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: textLight,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: textLight,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: textLight,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "We'll notify you when something happens",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: textLight,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String type = (data['type'] ?? 'unknown') as String;
              final String message = (data['message'] ?? 'No message') as String;
              final String? sellerId = data['sellerId'] as String?;
              final String? itemId = data['itemId'] as String?;
              final String? itemTitle = data['itemTitle'] as String?;
              final bool isRead = (data['isRead'] ?? false) as bool;
              final bool rated = (data['rated'] ?? false) as bool;
              final Timestamp? timestamp = data['timestamp'] as Timestamp?;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => doc.reference.delete(),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isRead ? backgroundColor : Colors.white,
                  elevation: isRead ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isRead ? Colors.grey.withOpacity(0.2) : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getNotificationColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getNotificationIcon(type),
                        color: _getNotificationColor(type),
                        size: 24,
                      ),
                    ),
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message,
                        style: GoogleFonts.nunito(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 16,
                          color: textDark,
                        ),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (itemTitle != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              "Item: $itemTitle",
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: textLight,
                              ),
                            ),
                          ),
                        Text(
                          timestamp != null ? _formatTimestamp(timestamp) : "No timestamp",
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: textLight,
                          ),
                        ),
                      ],
                    ),
                    trailing: type == 'rate_seller' && !rated
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primaryYellow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryYellow),
                            ),
                            child: Text(
                              'Rate Now',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : !isRead 
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: primaryYellow,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    onTap: () async {
                      // Mark as read first
                      if (!isRead) {
                        await _controller.markAsRead(doc.id);
                      }
                      
                      if (type == 'message') {
                        final rawEntity = await fetchEntity(data['itemId'], data['entityType']);

                        dynamic entity;
                        if (data['entityType'] == "Item") {
                          entity = Item.fromMap(rawEntity!);
                        } else {
                          entity = Request.fromMap(rawEntity!);
                        }                        
                        if (entity != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MessageScreen(
                                chatRoomId: null,
                                entity: entity,
                                entityType: data['entityType'],
                                senderId: data['senderId'],
                                receiverId: data['receiverId'],
                              ),
                            ),
                          );
                        }
                      }
                      
                      // Handle different notification types
                      if (type == 'rate_seller' && !rated && sellerId != null && itemId != null) {
                        _controller.showRatingDialog(
                          context,
                          sellerId: sellerId,
                          itemId: itemId,
                          itemTitle: itemTitle ?? "the item",
                          notificationId: doc.id,
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'rate_seller':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'message':
        return primaryYellow;
      case 'rate_seller':
        return primaryYellow;
      default:
        return primaryYellow;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
