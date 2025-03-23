import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String receiverId;
  final String content;
  final Timestamp timestamp;
  final String status;

  Message({
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.status,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Message(
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      content: data['content'],
      timestamp: (data['timestamp'] as Timestamp),
      status: data['status'],
    );
  }

  // Firestore'a veri gönderirken
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp,
      'status': status, 
    };
  }
}
