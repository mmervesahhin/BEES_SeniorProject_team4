import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bees/models/message_model.dart';  // User model import

class MessageController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mesaj Gönderme
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? imageUrl,
  }) async {
    final messageRef = _firestore.collection('messages').doc();

    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sending',  // İlk başta 'sending' olarak belirliyoruz
      'imageUrl': imageUrl ?? '',  // Resim gönderilmediğinde boş string
    };

    try {
      await messageRef.set(messageData);
      await messageRef.update({'status': 'sent'});
      print("Message sent!");
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // Mesajları Getirme
  Stream<List<Message>> getMessages(String userId, String otherUserId) {
    return _firestore
        .collection('messages')
        .where('senderId', isEqualTo: userId)
        .where('receiverId', isEqualTo: otherUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((querySnapshot) {
          return querySnapshot.docs.map((doc) {
            return Message.fromFirestore(doc);
          }).toList();
        });
  }

  // Mesaj Durumunu Güncelleme
  Future<void> updateMessageStatus(String messageId, String status) async {
    final messageRef = _firestore.collection('messages').doc(messageId);

    try {
      await messageRef.update({
        'status': status,  // Mesajın durumunu güncelle
      });
      print("Message status updated to: $status");
    } catch (e) {
      print("Error updating message status: $e");
    }
  }
}
