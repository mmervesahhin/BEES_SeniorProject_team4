  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart' as auth_user;
  import 'package:bees/models/chat_room_model.dart'; // ChatRoom modelini import et
  import 'package:bees/models/item_model.dart'; // Item model import
  import 'package:bees/models/request_model.dart'; // Request model import
  import 'message_screen.dart'; // MessageScreen import
  import 'package:intl/intl.dart';
import 'package:bees/controllers/message_controller.dart';

  class MessageListScreen extends StatelessWidget {
    static final auth_user.User currentUser = auth_user.FirebaseAuth.instance.currentUser!;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//     static Stream<int> getUnreadMessagesCount() {
//   return FirebaseFirestore.instance
//       .collection('chatRooms')
//       .where('userIds', arrayContains: currentUser.uid)
//       .snapshots()
//       .map((snapshot) {
//     int totalUnreadCount = 0;

//     // Her chat room için unread mesaj sayısını al
//     for (var doc in snapshot.docs) {
//       var chatRoom = ChatRoom.fromFirestore(doc);
//       MessageController().getMessagesWithStatuswithChatRoom(chatRoom.chatRoomId, 'sent').forEach((messageSnapshot) {
//         for (var msgDoc in messageSnapshot.docs) {
//           var messageData = msgDoc.data() as Map<String, dynamic>;
//           if (messageData['receiverId'] == currentUser.uid) {
//             totalUnreadCount++; // Okunmamış mesajları say
//           }
//         }
//       });
//     }

//     return totalUnreadCount;
//   });
// }

    // Kullanıcının içinde bulunduğu chat odalarını getir
    Stream<List<ChatRoom>> _getChatRooms() {
  String currentUserId = auth_user.FirebaseAuth.instance.currentUser?.uid ?? '';
  
  return _firestore.collection('chatRooms').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).where((chatRoom) {
      return chatRoom.removedUserIds.contains(currentUserId);
    }).toList();
  });
}
    Future<void> removeUserFromChatRoom(String chatRoomId) async {
      DocumentReference chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
      DocumentSnapshot doc = await chatRoomRef.get();
      if (doc.exists) {
        List<String> removedUserIds = List.from(doc['removedUserIds']);
        removedUserIds.remove(currentUser.uid);
        await chatRoomRef.update({
          'removedUserIds': removedUserIds,
        });
      }
    }
Widget _buildChatRoomItem(ChatRoom chatRoom) {
  String chatRoomId = chatRoom.chatRoomId;
  List<String> userIds = chatRoom.userIds;
  String lastMessage = chatRoom.lastMessage;
  String entityType = chatRoom.entityType;
  dynamic entity = chatRoom.entity;
  Timestamp lastMessageTimestamp = chatRoom.lastMessageTimestamp;
  String currentUserId = auth_user.FirebaseAuth.instance.currentUser?.uid ?? '';
  
  // Karşıdaki kullanıcıyı belirle
  String otherUserId = userIds.firstWhere((id) => id != currentUserId, orElse: () => '');

  return FutureBuilder<DocumentSnapshot>(
    future: _firestore.collection('users').doc(otherUserId).get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const ListTile(title: Text("Yükleniyor..."));
      }

      if (snapshot.hasData && snapshot.data != null) {
        var userData = snapshot.data!.data() as Map<String, dynamic>?;

        if (userData == null) {
          return const ListTile(title: Text("Veri bulunamadı"));
        }

        String firstName = userData['firstName'] ?? 'Bilinmeyen';
        String lastName = userData['lastName'] ?? 'Kullanıcı';
        String userName = '$firstName $lastName';
        String userProfilePic = userData['profilePicture'] ?? '';

        String displayMessage = lastMessage.contains('http')
            ? 'Visual is sent!'
            : lastMessage;

        return FutureBuilder<String>(
          future: _getEntityStatus(entityType, entity),
          builder: (context, statusSnapshot) {
            if (statusSnapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(title: Text("Yükleniyor..."));
            }

            final isActive = statusSnapshot.data == 'active';
            final statusMessage = entityType == "Item" 
                ? "This item has been beesed or removed" 
                : "This request has been solved or removed";

            return StreamBuilder<int>(
              stream: MessageController().getSentMessagesCount(chatRoomId, currentUser.uid, otherUserId),
              builder: (context, messageCountSnapshot) {
                if (messageCountSnapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    title: Text(userName),
                    subtitle: isActive ? Text(displayMessage) : Text(statusMessage),
                    trailing: const CircularProgressIndicator(),
                  );
                }

                if (messageCountSnapshot.hasData) {
                  int messageCount = messageCountSnapshot.data ?? 0;

                  return Dismissible(
                    key: Key(chatRoomId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Confirm Deletion"),
                            content: const Text("Are you sure you want to delete this chat?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text("Yes"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (_) async {
                      await removeUserFromChatRoom(chatRoomId);
                    },
                    child: ListTile(
                      onTap: isActive ? () {
                        if (entityType == "Item") {
                          String itemId = entity['itemId'];
                          Item itemEntity = Item.fromJson(entity, itemId);
                          _navigateToMessageScreen(chatRoomId, itemEntity, entityType, context);
                          Stream<QuerySnapshot> sentMessagesStream = MessageController().getMessagesWithStatus(itemId, currentUser.uid, otherUserId, 'sent');
                          sentMessagesStream.listen((snapshot) async {
                            for (var doc in snapshot.docs) {
                              var messageData = doc.data() as Map<String, dynamic>;
                              String receiverId = messageData['receiverId'];
                              String messageId = doc.id;
                              if (receiverId == currentUser.uid) {
                                await MessageController().updateMessageStatus(chatRoomId, messageId, 'read');
                              }
                            }
                          });
                        } else if (entityType == "Request") {
                          String reqId = entity['requestID'];
                          Request reqEntity = Request.fromJson2(entity);
                          _navigateToMessageScreen(chatRoomId, reqEntity, entityType, context);
                          Stream<QuerySnapshot> sentMessagesStream = MessageController().getMessagesWithStatus(reqId, currentUser.uid, otherUserId, 'sent');
                          sentMessagesStream.listen((snapshot) async {
                            for (var doc in snapshot.docs) {
                              var messageData = doc.data() as Map<String, dynamic>;
                              String receiverId = messageData['receiverId'];
                              String messageId = doc.id;
                              if (receiverId == currentUser.uid) {
                                await MessageController().updateMessageStatus(chatRoomId, messageId, 'read');
                              }
                            }
                          });
                        }
                      } : null,
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          userProfilePic.isEmpty ? 'https://via.placeholder.com/150' : userProfilePic,
                        ),
                      ),
                      title: Text(userName),
                      subtitle: isActive ? Text(displayMessage) : Text(statusMessage),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (messageCount > 0 && isActive)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    messageCount > 10 ? '10+' : messageCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(lastMessageTimestamp.toDate().toLocal()),
                                    style: TextStyle(
                                      fontSize: 14, 
                                      fontWeight: FontWeight.w500,
                                      color: isActive ? null : Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(lastMessageTimestamp.toDate().toLocal()),
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: isActive ? Colors.grey : Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return const ListTile(title: Text("Mesaj sayısı alınamadı"));
                }
              },
            );
          },
        );
      } else {
        return const ListTile(title: Text("Veri bulunamadı"));
      }
    },
  );
}

Future<String> _getEntityStatus(String entityType, dynamic entity) async {
  if (entityType == "Item") {
    String itemId = entity['itemId'];
    DocumentSnapshot itemDoc = await _firestore.collection('items').doc(itemId).get();
    var itemData = itemDoc.data() as Map<String, dynamic>;
    return itemData['itemStatus'] ?? 'inactive';
  } else if (entityType == "Request") {
    String requestId = entity['requestID'];
    DocumentSnapshot requestDoc = await _firestore.collection('requests').doc(requestId).get();
    var requestData = requestDoc.data() as Map<String, dynamic>;
    return requestData['requestStatus'] ?? 'inactive';
  }
  return 'inactive';
}
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Messages"),
          backgroundColor: const Color.fromARGB(255, 59, 137, 62),
        ),
        body: StreamBuilder<List<ChatRoom>>(
          stream: _getChatRooms(),
          builder: (context, snapshot) {
            print("Veri geldi: ${snapshot.data}");
            if (snapshot.hasError) {
              return Center(child: Text('Hata: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text("No messages found."));
            }
            List<ChatRoom> sortedChatRooms = snapshot.data!;
            sortedChatRooms.sort((a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp));

            return ListView(
              children: snapshot.data!.map((chatRoom) {
                return _buildChatRoomItem(chatRoom);
              }).toList(),
            );
          },
        ),
      );
    }

    void _navigateToMessageScreen(
      String chatRoomId, dynamic entity, String entityType, BuildContext context) {
    String currentUserId = currentUser.uid;

    // ChatRoom ID'yi "_" ile ayırıp user ID'lerini al
    List<String> parts = chatRoomId.split("_");

    // İlk parça itemId veya requestID olduğu için çıkar
    parts.removeAt(0);

    // Current user ID olmayanı sender yap
    String senderId = parts.firstWhere((id) => id != currentUserId, orElse: () => "");
    String receiverId = currentUserId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen(
          chatRoomId: chatRoomId,
          receiverId: receiverId,
          senderId: senderId,
          entity: entity,
          entityType: entityType,
        ),
      ),
    );
  }
  }
