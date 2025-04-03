import 'package:bees/controllers/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationController _controller = NotificationController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

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
        title: const Text("Rate Your Experience"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("How would you rate your transaction for '$itemTitle'?")
,                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() => rating = index + 1.0);
                      },
                    );
                  }),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Thank you for your rating!")),
                    );
                  }
                : null,
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color.fromARGB(255, 59, 137, 62),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where('receiverId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications found"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String type = (data['type'] ?? 'unknown') as String;
              final String message = (data['message'] ?? 'No message') as String;
              final String? senderId = data['senderId'] as String?;
              final String? itemTitle = data['itemTitle'] as String?;
              final bool isRead = (data['isRead'] ?? false) as bool;
              final bool rated = (data['rated'] ?? false) as bool;
              final Timestamp? timestamp = data['timestamp'] as Timestamp?;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => doc.reference.delete(),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  color: isRead ? Colors.grey[100] : Colors.white,
                  child: ListTile(
                    leading: Icon(
                      _getNotificationIcon(type),
                      color: isRead ? Colors.grey : _getNotificationColor(type),
                    ),
                    title: Text(
                      message,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (itemTitle != null)
                          Text("Item: $itemTitle", style: const TextStyle(fontSize: 12)),
                        Text(
                          timestamp != null ? _formatTimestamp(timestamp) : "No timestamp",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    onTap: () async {
                      if (!isRead) {
                        await _controller.markAsRead(doc.id);
                      }
                      if (type == 'item_beesed' && !rated) {
                        _showRatingDialog(
                          context,
                          sellerId: senderId ?? "Unknown Seller",
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
      case 'item_beesed':
        return Icons.thumb_up;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'item_beesed':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
