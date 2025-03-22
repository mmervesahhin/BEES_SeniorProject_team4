import 'dart:io';

import 'package:flutter/material.dart';
import 'detailed_item_screen.dart';
import 'detailed_request_screen.dart';
import 'package:bees/models/user_model.dart';  // User model import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bees/controllers/message_controller.dart';
import 'package:bees/models/message_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth_user;
import 'package:bees/controllers/blocked_user_controller.dart';
import 'package:bees/views/screens/others_user_profile_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:video_player/video_player.dart';
class MessageScreen extends StatelessWidget {
  //final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final String? chatRoomId;
  final dynamic entity;
  final String entityType;
  final String senderId;
  final String receiverId;


  MessageScreen({super.key, this.chatRoomId,
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
  

   void _navigateToProfile(String userId, BuildContext context) {  //kullanıcı isminden ya da profilinden o kişinin profiline yönlendirmeyi burda yapıyorum.
    if (userId == auth_user.FirebaseAuth.instance.currentUser!.uid) {
    // Eğer kullanıcı kendi profiline bakıyorsa
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserProfileScreen()),
    );
  } else {
    // Eğer başka birinin profiline bakıyorsa
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OthersUserProfileScreen(userId: userId)),
    );
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

    Future<void> _addUserToRemovedUserIds(String senderId, String receiverId) async {
  // Chat room'u al ve güncelle
  final chatRoomRef = FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId);
  final chatRoomSnapshot = await chatRoomRef.get();

  if (chatRoomSnapshot.exists) {
    final chatRoomData = chatRoomSnapshot.data()!;
    List<String> removedUserIds = List<String>.from(chatRoomData['removedUserIds'] ?? []);
    
    // Her iki kullanıcıyı da `removedUserIds` listesine ekle
    if (!removedUserIds.contains(senderId)) removedUserIds.add(senderId);
    if (!removedUserIds.contains(receiverId)) removedUserIds.add(receiverId);
    
    // Güncellenmiş `removedUserIds` listesi ile chat room'u güncelle
    await chatRoomRef.update({
      'removedUserIds': removedUserIds,
    });

    print("🔹 Kullanıcılar removedUserIds'ye eklendi: $senderId, $receiverId");
  } else {
    print("Hata: Chat room bulunamadı.");
  }
}

    TextEditingController _messageController = TextEditingController();

  void sendMessage() async {
    final BlockedUserController _blockedUserController = BlockedUserController();
    if (_messageController.text.isNotEmpty) {
    String currentUserId = auth_user.FirebaseAuth.instance.currentUser!.uid;

    // Eğer currentUserId, senderId ile aynıysa receiverId ve senderId yer değiştirsin
    String finalSenderId = (currentUserId == senderId) ? receiverId : currentUserId;
    String finalReceiverId = (currentUserId == senderId) ? currentUserId : senderId;

    // Engellenme durumlarını kontrol et
    bool isBlockedByReceiver = await _blockedUserController.isUserBlocked(finalReceiverId);
    bool isCurrentUserBlocked = await _blockedUserController.isUserBlocked(finalSenderId);

    if (isCurrentUserBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot send a message to this user.')),
      );
      return;
    }

    if (isBlockedByReceiver) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have blocked this user. Unblock to send messages.')),
      );
      return;
    }

    await MessageController().sendMessage(
      itemReqId: id,
      receiverId: finalReceiverId,
      content: _messageController.text,
      entityType: entityType,
      entity: entity,
    );

    await _addUserToRemovedUserIds(finalSenderId, finalReceiverId);

    _messageController.clear();
  }else{
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message cannot be empty')),
    );
  }
}

Widget messageStatusIcon(String status) {
  if (status == 'sent') {
    return Icon(
      Icons.check_circle, // Tek onay işareti
      color: Colors.green,
    );
  } else if (status == 'delivered') {
    return Icon(
      Icons.check_rounded, // Çift onay işareti
      color: Colors.blue,
    );
  } else if (status == 'failed') {
    return Icon(
      Icons.warning_amber_outlined, // Kırmızı uyarı işareti
      color: Colors.red,
    );
  } else if (status == 'sending') {
    return Icon(
      Icons.access_time, // Saat simgesi
      color: Colors.orange,
    );
  } else if (status == 'read') {
    return Icon(
      Icons.check_circle_outline, // Çift onay işareti okundu
      color: Colors.green, // Okunduysa farklı renkli
    );
  } else {
    return Container(); // Durum bilinmiyorsa boş bir container
  }
}

Future<void> _sendImageMessage(XFile image) async {
  try {
    // Resmi Firebase Storage'a yükle
    String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg'; // Benzersiz bir dosya adı
    Reference storageRef = FirebaseStorage.instance.ref().child('chat_images/$fileName');
    UploadTask uploadTask = storageRef.putFile(File(image.path));
    String currentUserId = auth_user.FirebaseAuth.instance.currentUser!.uid;
    // Yükleme tamamlandığında, resmin URL'sini al
    TaskSnapshot snapshot = await uploadTask;
    String imageUrl = await snapshot.ref.getDownloadURL();
    //String finalSenderId = (currentUserId == senderId) ? receiverId : currentUserId;
    String finalReceiverId = (currentUserId == senderId) ? currentUserId : senderId;
    // Resmi mesaj olarak gönder
    await MessageController().sendMessage(
      itemReqId: id,
      receiverId: finalReceiverId,
      content: imageUrl,
      entityType: entityType,
      entity: entity,
    );
  } catch (e) {
    print("Error sending image: $e");
  }
}

Future<void> _sendVideoMessage(XFile video) async {
  try {
    String fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    Reference storageRef = FirebaseStorage.instance.ref().child('chat_videos/$fileName');
    UploadTask uploadTask = storageRef.putFile(File(video.path));
    String currentUserId = auth_user.FirebaseAuth.instance.currentUser!.uid;

    TaskSnapshot snapshot = await uploadTask;
    String videoUrl = await snapshot.ref.getDownloadURL();

    String finalReceiverId = (currentUserId == senderId) ? currentUserId : senderId;

    await MessageController().sendMessage(
      itemReqId: id,
      receiverId: finalReceiverId,
      content: videoUrl,
      entityType: entityType,
      entity: entity,
    );
  } catch (e) {
    print("Error sending video: $e");
  }
}
// VideoPlayer widget'ı ile video oynatma işlemi
// Widget buildVideoPlayer(String url) {

//   return FutureBuilder(
//     future: controller.initialize(),
//     builder: (context, snapshot) {
//       if (snapshot.connectionState == ConnectionState.done) {
//         return AspectRatio(
//           aspectRatio: controller.value.aspectRatio,
//           child: VideoPlayer(controller),
//         );
//       } else {
//         return Center(child: CircularProgressIndicator());
//       }
//     },
//   );
// }

Widget _buildVideoPlayer(String videoUrl) {
  VideoPlayerController controller = VideoPlayerController.network(videoUrl);

  return FutureBuilder<void>(
    future: controller.initialize(),  // VideoController'ı initialize ediyoruz
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        if (controller.value.hasError) {
          return Center(child: Text('Video yüklenirken bir hata oluştu: ${controller.value.errorDescription}'));
        }
        return AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        );
      } else if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else {
        return Center(child: Text('Video yüklenemedi'));
      }
    },
  );
}
Widget _buildMessageItem(DocumentSnapshot document) {
  Map<String, dynamic>? data = document.data() as Map<String, dynamic>?; // Null olursa hata vermez
  if (data == null) return SizedBox.shrink(); // Boş bir widget döndür

  auth_user.User firebaseUser = auth_user.FirebaseAuth.instance.currentUser!;
  var alignment = (data['senderId'] == firebaseUser.uid) ? Alignment.centerRight : Alignment.centerLeft;
  String status = data['status'];

  return FutureBuilder<User?>(
    future: _getUserDetails(data['senderId']),  // Gönderenin bilgilerini getir
    builder: (context, snapshot) {
      String senderName = "Unknown";  // Varsayılan isim
      if (snapshot.connectionState == ConnectionState.waiting) {
        senderName = "Loading...";  // Yükleniyor göster
      } else if (snapshot.hasData && snapshot.data != null) {
        senderName = "${snapshot.data!.firstName} ${snapshot.data!.lastName}";
      }

      Widget messageContent;
      if (data['content'].startsWith('http')) {
        // Eğer içerik bir URL ise ve video ise
        if (data['content'].endsWith('.mp4')) {
          // Video URL'si olduğunda VideoPlayer widget'ını kullan
          //print("video test"+data['content']);
          messageContent = _buildVideoPlayer(data['content']);
        } else {
          // Resim URL'si olduğunda Image widget'ını kullan
          messageContent = Image.network(data['content'], width: 200, height: 200, fit: BoxFit.cover);
        }
      } else {
        // Mesaj metni
        messageContent = Text(data['content'], style: TextStyle(fontSize: 16));
      }

      Widget statusIcon = messageStatusIcon(status);

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min, // Yatayda minimum alanı kaplamasına izin verir
                    children: [
                      messageContent, // Mesaj içeriği
                      SizedBox(width: 8), // Mesaj ile ikon arasında boşluk
                      statusIcon, // Duruma göre ikon
                    ],
                  ),
                ],
              ),
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
                child: GestureDetector(
                  onTap: () => _navigateToProfile(user.userID, context),
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
                )
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
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Color.fromARGB(255, 59, 137, 62)),
                  onPressed: () {
                      showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(000.0, 580.0, 100.0, 100.0), // Menüyü konumlandır
                        items: [
                          PopupMenuItem(
                            child: Row(
                              children: const [
                                Icon(Icons.photo, color: Colors.blue),
                                SizedBox(width: 8),
                                Text("Send a Photo"),
                              ],
                            ),
                            onTap: () async {
                              final ImagePicker _picker = ImagePicker();
                              final List<XFile>? images = await _picker.pickMultiImage();
                              if (images != null && images.isNotEmpty) {
                                for (var image in images) {
                                  _sendImageMessage(image);
                                }
                              }
                            },
                          ),
                          PopupMenuItem(
                            child: Row(
                              children: const [
                                Icon(Icons.video_collection, color: Colors.blue),
                                SizedBox(width: 8),
                                Text("Send a Video"),
                              ],
                            ),
                            onTap: () async {
                              final ImagePicker _picker = ImagePicker();
                              final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                              if (video != null) {
                                _sendVideoMessage(video);
                              }
                            },
                          ),
                        ],
                      );
                    },
                ),
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
