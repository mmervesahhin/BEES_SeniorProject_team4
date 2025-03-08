import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth_user;
import 'package:bees/models/chat_room_model.dart'; // ChatRoom modelini import et
import 'package:bees/models/item_model.dart'; // Item model import
import 'package:bees/models/request_model.dart'; // Request model import
import 'message_screen.dart'; // MessageScreen import

class MessageListScreen extends StatelessWidget {
  final auth_user.User currentUser = auth_user.FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcının içinde bulunduğu chat odalarını getir
  Stream<List<ChatRoom>> _getChatRooms() {
    return _firestore.collection('chatRooms').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).where((chatRoom) {
        return chatRoom.userIds.contains(currentUser.uid);
      }).toList();
    });
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

    // Kullanıcı bilgilerini al
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

          return ListTile(
            onTap: () {
            print('Navigating to MessageScreen:');
            print('ChatRoomId: $chatRoomId');
            print('ReceiverId: $otherUserId');
            print('SenderId: ${currentUser.uid}');
            print('Entity: $entity');
            print('EntityType: $entityType');

            if (entityType == "Item") {
              String itemId = entity['itemId'];
              Item itemEntity = Item.fromJson(entity, itemId);
              _navigateToMessageScreen(chatRoomId,itemEntity, entityType, context);
            } else if (entityType == "Request") {
              String reqId = entity['requestID'];
              Request reqEntity = Request.fromJson2(entity);
              _navigateToMessageScreen(chatRoomId,reqEntity, entityType, context);
            }
          },
            leading: CircleAvatar(
              backgroundImage: NetworkImage(userProfilePic.isEmpty ? 'default_image_url' : userProfilePic), // Varsayılan profil resmi
            ),
            title: Text(userName),
            subtitle: Text(lastMessage.isNotEmpty ? lastMessage : "Yeni mesaj yok"),
            trailing: Text(
              '${lastMessageTimestamp.toDate().toLocal().toString()}',
            ),
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
        title: Text("Mesajlar"),
        backgroundColor: const Color.fromARGB(255, 59, 137, 62),
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _getChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Henüz mesajlaşma başlatılmadı"));
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

  print("📩 Navigating to MessageScreen:");
  print("🔹 ChatRoomId: $chatRoomId");
  print("🔹 SenderId (ChatRoom'daki diğer kullanıcı): $senderId");
  print("🔹 ReceiverId (Şu anki kullanıcı): $receiverId");

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
