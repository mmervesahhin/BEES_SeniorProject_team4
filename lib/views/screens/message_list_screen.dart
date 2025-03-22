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
    final auth_user.User currentUser = auth_user.FirebaseAuth.instance.currentUser!;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Kullanıcının içinde bulunduğu chat odalarını getir
    Stream<List<ChatRoom>> _getChatRooms() {
      return _firestore.collection('chatRooms').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).where((chatRoom) {
          return chatRoom.removedUserIds.contains(currentUser.uid);
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

    // Chat Room kartını oluşturma
    Widget _buildChatRoomItem(ChatRoom chatRoom) {
  String chatRoomId = chatRoom.chatRoomId;
  List<String> userIds = chatRoom.userIds;
  String lastMessage = chatRoom.lastMessage;
  String entityType = chatRoom.entityType;
  dynamic entity = chatRoom.entity;
  Timestamp lastMessageTimestamp = chatRoom.lastMessageTimestamp;

  // Karşıdaki kullanıcıyı belirle
  String otherUserId = userIds.firstWhere((id) => id != currentUser.uid, orElse: () => '');

  return FutureBuilder<DocumentSnapshot>(
    future: _firestore.collection('users').doc(otherUserId).get(), // Kullanıcı verisini alıyoruz
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return ListTile(title: Text("Yükleniyor..."));
      }

      if (snapshot.hasData && snapshot.data != null) {
        // Firestore'dan gelen veri null kontrolü
        var userData = snapshot.data!.data() as Map<String, dynamic>?;

        if (userData == null) {
          return ListTile(title: Text("Veri bulunamadı"));
        }

        String firstName = userData['firstName'] ?? 'Bilinmeyen';
        String lastName = userData['lastName'] ?? 'Kullanıcı';
        String userName = '$firstName $lastName';
        String userProfilePic = userData['profilePicture'] ?? ''; // Kullanıcı profil fotoğrafı

        String displayMessage = lastMessage.contains('http')
            ? 'Visual is sent!'  // Burada istediğiniz metni yazabilirsiniz
            : lastMessage;

        return FutureBuilder<int>(
          future: MessageController().getSentMessagesCount(chatRoomId, currentUser.uid, otherUserId), // Get the message count
          builder: (context, messageCountSnapshot) {
            if (messageCountSnapshot.connectionState == ConnectionState.waiting) {
              return ListTile(
                title: Text(userName),
                subtitle: Text(displayMessage),
                trailing: CircularProgressIndicator(),
              );
            }

            if (messageCountSnapshot.hasData) {
              int messageCount = messageCountSnapshot.data ?? 0;

              return ListTile(
                onTap: () {
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
                },
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(userProfilePic.isEmpty ? 'default_image_url' : userProfilePic), // Varsayılan profil resmi
                ),
                title: Text(userName),
                subtitle: Text(displayMessage),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Unread Messages: ${messageCount > 10 ? '10+' : messageCount}',  // Display message count or '10+' if greater than 10
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(lastMessageTimestamp.toDate().toLocal()),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      DateFormat('HH:mm').format(lastMessageTimestamp.toDate().toLocal()),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            } else {
              return ListTile(title: Text("Mesaj sayısı alınamadı"));
            }
          },
        );
      } else {
        return ListTile(title: Text("Veri bulunamadı"));
      }
    },
  );
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
