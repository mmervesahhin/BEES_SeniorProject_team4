import 'package:flutter/material.dart';
import 'detailed_item_screen.dart';
import 'detailed_request_screen.dart';
import 'package:bees/models/user_model.dart';  // User model import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bees/controllers/message_controller.dart';
import 'package:bees/models/message_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth_user;

class MessageScreen extends StatelessWidget {
  //final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final String? chatRoomId;
  final dynamic entity;
  final String entityType;
  final String senderId;
  final String receiverId;

  const MessageScreen({super.key, this.chatRoomId,
    required this.entity, required this.entityType,required this.senderId,
    required this.receiverId,});


  String truncateText(String text, int maxLength) {
    return (text.length > maxLength) ? '${text.substring(0, maxLength)}...' : text;
  }

  Future<User?> _getUserDetails(String userID) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')  // Assuming you store users in a 'users' collection
          .doc(userID)
          .get();
      if (snapshot.exists) {
        return User.fromMap(snapshot.data()!);
      }
      return null;
    } catch (e) {
      print("Error fetching user details: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth_user.User currentUser = auth_user.FirebaseAuth.instance.currentUser!;
    String id = "";
    String name = "";
    String userID = "";

    if(entityType == "Item"){
      id = entity.itemId;
      name = truncateText(entity.title, 30); // Maksimum 30 karakter
      userID = entity.itemOwnerId;
    }else if(entityType == "Request"){
      print(entity);
      id = entity.requestID;
      name = truncateText(entity.requestContent, 30);
      userID = entity.requestOwnerID;
    }

    TextEditingController _messageController = TextEditingController();

   void sendMessage() async {
  if (_messageController.text.isNotEmpty) {
    String currentUserId = auth_user.FirebaseAuth.instance.currentUser!.uid;

    // Eğer currentUserId, senderId ile aynıysa receiverId ve senderId yer değiştirsin
    String finalSenderId = (currentUserId == senderId) ? receiverId : currentUserId;
    String finalReceiverId = (currentUserId == senderId) ? currentUserId : senderId;

    print("📩 Mesaj gönderiliyor...");
    print("🔹 Gönderen (SenderId): $finalSenderId");
    print("🔹 Alıcı (ReceiverId): $finalReceiverId");
    print("🔹 Mesaj İçeriği: ${_messageController.text}");

    await MessageController().sendMessage(
      itemReqId: id,
      receiverId: finalReceiverId,
      content: _messageController.text,
      entityType: entityType,
      entity: entity,
    );

    _messageController.clear();
  }
}


    

    // Widget _buildMessageItem(DocumentSnapshot document){
    //   Map<String, dynamic>? data = document.data() as Map<String, dynamic>?; // Null olursa hata vermez
    //   if (data == null) return SizedBox.shrink(); // Boş bir widget döndür

    //   auth_user.User firebaseUser = auth_user.FirebaseAuth.instance.currentUser!;
    //   var alignment = (data['senderId'] == firebaseUser.uid) ? Alignment.centerRight : Alignment.centerLeft;

    //   return Container(
    //     alignment: alignment,
    //     child: Column(
    //       children: [
    //         Text(data['senderId']),
    //         Text(data['content'])
    //       ],
    //     )
    //   );
    // }
    Widget _buildMessageItem(DocumentSnapshot document) {
  Map<String, dynamic>? data = document.data() as Map<String, dynamic>?; // Null olursa hata vermez
  if (data == null) return SizedBox.shrink(); // Boş bir widget döndür

  auth_user.User firebaseUser = auth_user.FirebaseAuth.instance.currentUser!;
  var alignment = (data['senderId'] == firebaseUser.uid) ? Alignment.centerRight : Alignment.centerLeft;

  return FutureBuilder<User?>(
    future: _getUserDetails(data['senderId']),  // Gönderenin bilgilerini getir
    builder: (context, snapshot) {
      String senderName = "Unknown";  // Varsayılan isim
      if (snapshot.connectionState == ConnectionState.waiting) {
        senderName = "Loading...";  // Yükleniyor göster
      } else if (snapshot.hasData && snapshot.data != null) {
        senderName = "${snapshot.data!.firstName} ${snapshot.data!.lastName}";
      }

      return Container(
        alignment: alignment,
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          crossAxisAlignment: alignment == Alignment.centerRight 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            Text(senderName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: alignment == Alignment.centerRight ? Colors.green[100] : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(data['content'], style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    },
  );
}


    Widget _buildMessageList(){
      auth_user.User firebaseUser = auth_user.FirebaseAuth.instance.currentUser!;
      
      return StreamBuilder(stream: MessageController().getMessages(
        id, senderId, receiverId), builder: (context, snapshot){
          if(snapshot.hasError){
            return Text('Error${snapshot.error}');
          }

          if(snapshot.connectionState == ConnectionState.waiting){
            return const Text('Loading...');
          }

          return ListView(
            children: snapshot.data!.docs.map((document) => _buildMessageItem(document)).toList(),
          );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Message - $entityType"),
        backgroundColor: const Color.fromARGB(255, 59, 137, 62),
        actions: [
          FutureBuilder<User?>(
            future: _getUserDetails(userID),  // Fetch user details based on creator's userID
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),  // Loading indicator while fetching user
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Unknown User"),  // Fallback text if no user found
                );
              }

              User user = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.0), // Border space
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green, // Border color
                          width: 2.0, // Border width
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(user.profilePicture), // Display user's profile picture
                        backgroundColor: Colors.transparent,
                        onBackgroundImageError: (exception, stackTrace) {
                          print("Image loading failed: $exception");
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${user.firstName} ${user.lastName}", // Display the user who created the entity
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Message regarding:",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                // Conditional navigation based on entityType
                if (entityType == "Item") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailedItemScreen(
                        itemId: id,  // itemId'yi DetailedItemScreen'e gönderiyoruz
                      ),
                    ),
                  );
                } else if (entityType == "Request") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailedRequestScreen(
                       request: entity,  // requestId'yi DetailedRequestScreen'e gönderiyoruz
                      ),
                    ),
                  );
                }
              },
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: _buildMessageList(),
//                 child: StreamBuilder<List<Message>>(
//                   stream: FirebaseFirestore.instance
//                     .collection('messages')
//                     .where('senderId', isEqualTo: senderId)
//                     .where('receiverId', isEqualTo: receiverId)
//                     //.orderBy('timestamp', descending: true) // Timestamp sıralaması
//                     .snapshots()
//                     .map((querySnapshot) {
//                       return querySnapshot.docs.map((doc) {
//                         return Message.fromFirestore(doc);
//                       }).toList();
//                   }),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
// //|| snapshot.data!.isEmpty
//                     if (!snapshot.hasData ) {
//                       return const Center(child: Text("No messages yet"));
//                     }

//                     final messages = snapshot.data!;
//                     return ListView.builder(
//                       reverse: true, // Mesajları tersten gösterme
//                       itemCount: messages.length,
//                       itemBuilder: (context, index) {
//                         final message = messages[index];
//                         return ListTile(
//                           title: Text(message.content),
//                           subtitle: Text(message.senderId),
//                           trailing: Text(message.timestamp.toString()),
//                         );
//                       },
//                     );
//                   },
//                 )
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    obscureText: false,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color.fromARGB(255, 59, 137, 62)),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
