import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bees/models/message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bees/models/chat_room_model.dart';

class MessageController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mesaj Gönderme
  Future<void> sendMessage({
    required String itemReqId,
    required String receiverId,
    required String content,
    required String entityType,
    required dynamic entity,
    //String? imageUrl,
  }) async {
    Map<String, dynamic> entityMap = entity.toMap();
    final String currentUserID = _firebaseAuth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(senderId: currentUserID, receiverId: receiverId, content: content, timestamp: timestamp);

    List<String> ids = [currentUserID, receiverId];
    ids.sort();
    String chatRoomId = "${itemReqId}_${ids.join("_")}";
    
    DocumentReference chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
    DocumentSnapshot chatRoomSnapshot = await chatRoomRef.get();

    if (!chatRoomSnapshot.exists) {
      // 🔸 Yeni ChatRoom oluştur
      ChatRoom newChatRoom = ChatRoom(
        chatRoomId: chatRoomId,
        itemReqId: itemReqId,
        userIds: ids,
        lastMessage: content,
        lastMessageTimestamp: timestamp,
        entityType: entityType,
        entity: entityMap,
      );
      
      await chatRoomRef.set(newChatRoom.toMap());


    } else {
      // 🔸 Var olan ChatRoom'un son mesajını güncelle
      await chatRoomRef.update({
        'lastMessage': content,
        'lastMessageTimestamp': timestamp,
      });
      await chatRoomRef.collection('messages').add(newMessage.toMap());

        if (receiverId != currentUserID) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'recipientId': receiverId,
            'message': 'You have received a new message.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
      }
    }

  }

  // Mesajları Getirme
  Stream<QuerySnapshot> getMessages(String itemReqId,String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = "${itemReqId}_${ids.join("_")}";
    print("🟢 Mesajlar getiriliyor: ChatRoomId = $chatRoomId");
    return _firestore
      .collection('chatRooms')
      .doc(chatRoomId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots()
      ..listen((snapshot) {
        for (var doc in snapshot.docs) {
          print("📩 Mesaj: ${doc.data()}");
        }
      });
  }

  // Stream<QuerySnapshot> getMessages2(String? chatRoomId) {
  //   print("🟢 Mesajlar getiriliyor: ChatRoomId = $chatRoomId");
  //   return _firestore.collection('chatRooms').doc(chatRoomId).collection('messages').orderBy('timestamp', descending: false).snapshots();
  // }


  // Mesaj Durumunu Güncelleme
  /*Future<void> updateMessageStatus(String messageId, String status) async {
    final messageRef = _firestore.collection('messages').doc(messageId);

    try {
      await messageRef.update({
        'status': status,  // Mesajın durumunu güncelle
      });
      print("Message status updated to: $status");
    } catch (e) {
      print("Error updating message status: $e");
    }
  }*/
}
