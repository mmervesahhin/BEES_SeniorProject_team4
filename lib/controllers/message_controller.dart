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
Map<String, dynamic> entityMap = entity is Map<String, dynamic> ? entity : entity.toMap();
    final String currentUserID = _firebaseAuth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(senderId: currentUserID, receiverId: receiverId, content: content, timestamp: timestamp, status: 'sending',);

    List<String> ids = [currentUserID, receiverId];
    ids.sort();
    String chatRoomId = "${itemReqId}_${ids.join("_")}";
    DocumentReference chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);

    if (receiverId != currentUserID) {
      await FirebaseFirestore.instance.collection('notifications').add({
        //'recipientId': receiverId,
        'receiverId': receiverId,
        'senderId': currentUserID,
        'itemId': itemReqId,
        'entityType': entityType,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'message',
        'message': 'You have a new message', // ✅ bu satır eksik

      });
    }

    try {
    DocumentSnapshot chatRoomSnapshot = await chatRoomRef.get();

    if (!chatRoomSnapshot.exists) {
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
      await chatRoomRef.update({
        'lastMessage': content,
        'lastMessageTimestamp': timestamp,
        'removedUserIds': ids,
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

Stream<QuerySnapshot> getMessagesWithStatus(
    String itemReqId, String userId, String otherUserId, String status) {
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<String> ids = [userId, otherUserId];
  ids.sort();
  String chatRoomId = "${itemReqId}_${ids.join("_")}";

  return _firestore
      .collection('chatRooms')
      .doc(chatRoomId)
      .collection('messages')
      .where('status', isEqualTo: status)
      .where('senderId', isNotEqualTo: currentUserId) // userId dışında olanlar
      .orderBy('senderId') // isNotEqualTo için zorunlu
      .orderBy('timestamp', descending: false)
      .snapshots()
    ..listen((snapshot) {
      for (var doc in snapshot.docs) {
        print("📩 Mesaj (status:$status, not from $userId): ${doc.data()}");
      }
    });
}

Stream<QuerySnapshot> getMessagesWithStatuswithChatRoom(String chatRoomId, String status) {
  String chatRoomId2 = chatRoomId;

  return _firestore
    .collection('chatRooms')
    .doc(chatRoomId2)
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

Stream<int> getSentMessagesCount(String chatRoomId, String currentUserId, String receiverId) {
  return _firestore
      .collection('chatRooms')
      .doc(chatRoomId)
      .collection('messages')
      .where('status', isEqualTo: 'sent')
      .where('receiverId', isEqualTo: currentUserId)
      .where('senderId', isEqualTo: receiverId)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}

Stream<int> getTotalUnreadMessagesCount(String currentUserId) {
  return FirebaseFirestore.instance
      .collection('chatRooms')
      .where('userIds', arrayContains: currentUserId)
      .snapshots()
      .asyncMap((snapshot) async {
    int totalUnreadCount = 0;

    for (var doc in snapshot.docs) {
      var chatRoom = ChatRoom.fromFirestore(doc);
      String otherUserId = chatRoom.userIds.firstWhere((id) => id != currentUserId, orElse: () => '');

      // Entity durumunu kontrol et (doğrudan Firestore'dan)
      String entityStatus = await _getEntityStatus(chatRoom.entityType, chatRoom.entity);
      
      // Sadece aktif entity'ler için say
      if (entityStatus == 'active') {
        int unreadCount = await getSentMessagesCount(chatRoom.chatRoomId, currentUserId, otherUserId).first;
        totalUnreadCount += unreadCount;
      }
    }

    return totalUnreadCount;
  });
}

Future<String> _getEntityStatus(String entityType, dynamic entity) async {
  try {
    if (entityType == "Item") {
      String itemId = entity['itemId'];
      DocumentSnapshot itemDoc = await FirebaseFirestore.instance.collection('items').doc(itemId).get();
      if (!itemDoc.exists) return 'inactive';
      var itemData = itemDoc.data() as Map<String, dynamic>;
      return itemData['itemStatus'] ?? 'inactive';
    } else if (entityType == "Request") {
      String requestId = entity['requestID'];
      DocumentSnapshot requestDoc = await FirebaseFirestore.instance.collection('requests').doc(requestId).get();
      if (!requestDoc.exists) return 'inactive';
      var requestData = requestDoc.data() as Map<String, dynamic>;
      return requestData['requestStatus'] ?? 'inactive';
    }
    return 'inactive';
  } catch (e) {
    print('Error checking entity status: $e');
    return 'inactive'; // Hata durumunda inactive kabul et
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