import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String chatRoomId;
  final String itemReqId;
  final List<String> userIds;
  final List<String> removedUserIds;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;
  final String entityType;
  final dynamic entity;

  ChatRoom({
    required this.chatRoomId,
    required this.itemReqId,
    required this.userIds,
    required this.removedUserIds,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    required this.entityType,
    required this.entity,
  });

  // Firestore'dan veri almak için
  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatRoom(
      chatRoomId: doc.id,
      itemReqId: data['itemReqId'],
      userIds: List<String>.from(data['userIds']),
      removedUserIds: List<String>.from(data['removedUserIds']),
      lastMessage: data['lastMessage'] ?? "",
      lastMessageTimestamp: data['lastMessageTimestamp'] ?? Timestamp.now(),
      entityType: data['entityType'] ?? 'item',
      entity: data['entity'] ?? '',
    );
  }

  // Firestore'a veri göndermek için
  Map<String, dynamic> toMap() {
    return {
      'itemReqId': itemReqId,
      'userIds': userIds,
      'removedUserIds': removedUserIds,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
      'entityType': entityType,
      'entity': entity,
    };
  }
}
