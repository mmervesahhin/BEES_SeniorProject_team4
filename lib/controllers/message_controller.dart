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

    Message newMessage = Message(senderId: currentUserID, receiverId: receiverId, content: content, timestamp: timestamp, status: 'sending',);

    List<String> ids = [currentUserID, receiverId];
    ids.sort();
    String chatRoomId = "${itemReqId}_${ids.join("_")}";
    
    DocumentReference chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);

    try {
    DocumentSnapshot chatRoomSnapshot = await chatRoomRef.get();

    if (!chatRoomSnapshot.exists) {
      // 🔸 Yeni ChatRoom oluştur
      ChatRoom newChatRoom = ChatRoom(
        chatRoomId: chatRoomId,
        itemReqId: itemReqId,
        userIds: ids,
        removedUserIds: ids,
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
    }
   
    
    if (receiverId != currentUserID) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': receiverId,
        'message': 'You have recieved a new message',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }

    DocumentReference newMessageRef = await chatRoomRef.collection('messages').add(newMessage.toMap());
    String newMessageId = newMessageRef.id;
    print("Mesaj ID'si: $newMessageId");
    await updateMessageStatus(chatRoomId, newMessageId, 'sent');

     } catch (e) {
    print("Mesaj gönderme başarısız oldu! Hata: $e");
  }
  }

  Future<void> updateMessageStatus(String chatRoomId, String messageId, String status) async {
  final messageRef = _firestore.collection('chatRooms').doc(chatRoomId).collection('messages')
      .doc(messageId);

  try {
    await messageRef.update({
      'status': status,  // Mesajın durumunu güncelle
    });
    print("Message status updated to: $status");
  } catch (e) {
    print("Error updating message status: $e");
  }
}
  Stream<QuerySnapshot> getMessages(String itemReqId, String userId, String otherUserId) {
  List<String> ids = [userId, otherUserId];
  ids.sort();
  String chatRoomId = "${itemReqId}_${ids.join("_")}";

  return _firestore
    .collection('chatRooms')
    .doc(chatRoomId)
    .collection('messages')
    .orderBy('timestamp', descending: false)
    .snapshots()
    ..listen((snapshot) async {
      for (var doc in snapshot.docs) {
        print("📩 Mesaj: ${doc.data()}");
      }
    });
}

Stream<QuerySnapshot> getMessagesWithStatus(String itemReqId, String userId, String otherUserId, String status) {
  List<String> ids = [userId, otherUserId];
  ids.sort();
  String chatRoomId = "${itemReqId}_${ids.join("_")}";

  return _firestore
    .collection('chatRooms')
    .doc(chatRoomId)
    .collection('messages')
    .where('status', isEqualTo: status)  // Filter messages by status
    .orderBy('timestamp', descending: false)
    .snapshots()
    ..listen((snapshot) async {
      for (var doc in snapshot.docs) {
        print("📩 Mesaj: ${doc.data()}");
      }
    });
}

Future<int> getSentMessagesCount(String chatRoomId, String currentUserId, String receiverId) async {
  try {
    // 'status' = 'sent' olan ve currentUserId ile receiverId'yi eşleştiren mesajları filtrele
    QuerySnapshot snapshot = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('status', isEqualTo: 'sent')
        .where('receiverId', isEqualTo: currentUserId)
        .get();

    // Mesaj sayısını döndür
    int messageCount = snapshot.docs.length;
    print("Sent message count: $messageCount");

    return messageCount;
  } catch (e) {
    print("Mesaj sayısını alırken hata oluştu: $e");
    return 0; // Hata durumunda 0 döndürüyoruz
  }
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
