import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
  return _firestore
      .collection('notifications')
      .where(Filter.and(
        Filter("recipientId", isEqualTo: userId),
        Filter("sellerId", isEqualTo: userId),
      ))
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data(),
            };
          }).toList());
}

Future<void> markAsRead(String notificationId) async {
  try {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  } catch (e) {
    print("❌ Failed to mark notification as read: $e");
    rethrow;
  }
}


  Future<void> submitRating({
    required String sellerId,
    required double rating,
    required String notificationId,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(sellerId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final currentRating = snapshot.get('rating') ?? 0.0;
        final ratingCount = snapshot.get('ratingCount') ?? 0;
        
        final newCount = ratingCount + 1;
        final newRating = ((currentRating * ratingCount) + rating) / newCount;

        transaction.update(userRef, {
          'rating': newRating,
          'ratingCount': newCount,
        });
      });

      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'rated': true,
      });

      print("⭐ Rating submitted for seller $sellerId");
    } catch (e) {
      print("❌ Failed to submit rating: $e");
      rethrow;
    }
  }
}

class NotificationScreen extends StatefulWidget {
  final String userId;
  NotificationScreen({required this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationController _controller = NotificationController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _controller.getUserNotifications(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No notifications found"));
          }

          var notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index];
              return ListTile(
                title: Text(notification['message'] ?? "Notification"),
                subtitle: Text(notification['timestamp'] != null
                    ? _formatTimestamp(notification['timestamp'])
                    : ""),
                trailing: notification['isRead']
                    ? Icon(Icons.check, color: Colors.green)
                    : Icon(Icons.notifications, color: Colors.red),
                onTap: () async {
                  if (!notification['isRead']) {
                    await _controller.markAsRead(notification['id']);
                  }
                  if (notification['type'] == 'item_beesed' && !(notification['rated'] ?? false)) {
                    _showRatingDialog(
                      context,
                      sellerId: notification['senderId'],
                      itemTitle: notification['itemTitle'] ?? "the item",
                      notificationId: notification['id'],
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showRatingDialog(
    BuildContext context, {
    required String sellerId,
    required String itemTitle,
    required String notificationId,
  }) async {
    double rating = 0;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Rate Your Experience"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("How would you rate your transaction for '$itemTitle'?")
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: rating > 0
                ? () async {
                    Navigator.pop(context);
                    await _controller.submitRating(
                      sellerId: sellerId,
                      rating: rating,
                      notificationId: notificationId,
                    );
                  }
                : null,
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "\${date.day}/\${date.month}/\${date.year} \${date.hour}:\${date.minute.toString().padLeft(2, '0')}";
  }
}
