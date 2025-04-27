import 'package:bees/controllers/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth_user;
import 'package:bees/models/chat_room_model.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/request_model.dart';
import 'package:bees/views/screens/message_screen.dart';
import 'package:intl/intl.dart';
import 'package:bees/controllers/message_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({Key? key}) : super(key: key);

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  static final auth_user.User currentUser = auth_user.FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  
  // Color scheme
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  // Update the background color to white
  final backgroundColor = Colors.white;
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);

  // Get chat rooms where the current user is a participant
  Stream<List<ChatRoom>> _getChatRooms() {
    String currentUserId = auth_user.FirebaseAuth.instance.currentUser?.uid ?? '';
    
    return _firestore.collection('chatRooms').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).where((chatRoom) {
        return chatRoom.removedUserIds.contains(currentUserId);
      }).toList();
    });
  }

  // Remove user from chat room
  Future<void> removeUserFromChatRoom(String chatRoomId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      DocumentReference chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
      DocumentSnapshot doc = await chatRoomRef.get();
      if (doc.exists) {
        List<String> removedUserIds = List.from(doc['removedUserIds']);
        removedUserIds.remove(currentUser.uid);
        await chatRoomRef.update({
          'removedUserIds': removedUserIds,
        });
      }
    } catch (e) {
      print("Error removing user from chat room: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete conversation',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update the chat room item to use white background
Widget _buildChatRoomItem(ChatRoom chatRoom) {
  String chatRoomId = chatRoom.chatRoomId;
  List<String> userIds = chatRoom.userIds;
  String lastMessage = chatRoom.lastMessage;
  String entityType = chatRoom.entityType;
  dynamic entity = chatRoom.entity;
  Timestamp lastMessageTimestamp = chatRoom.lastMessageTimestamp;
  String currentUserId = auth_user.FirebaseAuth.instance.currentUser?.uid ?? '';

  // Add a local state to track if the message is read
  bool isRead = false;

  String otherUserId = userIds.firstWhere(
    (id) => id != currentUserId,
    orElse: () => '',
  );

  if (otherUserId.isEmpty) {
    return Dismissible(
      key: Key(chatRoomId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                "Delete Conversation",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              content: Text(
                "Are you sure you want to delete this conversation?",
                style: GoogleFonts.nunito(
                  color: textDark,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.nunito(
                      color: textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Delete",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        );
      },
      onDismissed: (direction) async {
        await FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId).delete();
      },
      child: _buildErrorChatItem("Invalid chat room: No other user found."),
    );
  }

  return FutureBuilder<DocumentSnapshot>(
    future: _firestore.collection('users').doc(otherUserId).get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildLoadingChatItem();
      }

      if (snapshot.hasData && snapshot.data != null) {
        var userData = snapshot.data!.data() as Map<String, dynamic>?;

        if (userData == null) {
          return _buildErrorChatItem("User data not found");
        }

        String firstName = userData['firstName'] ?? 'Unknown';
        String lastName = userData['lastName'] ?? 'User';
        String userName = '$firstName $lastName';
        String userProfilePic = userData['profilePicture'] ?? '';

        String displayMessage = lastMessage.contains('http')
            ? lastMessage.endsWith('.mp4') 
                ? '📹 Video '
                : '📷 Photo '
            : lastMessage;

        return FutureBuilder<String>(
          future: _getEntityStatus(entityType, entity),
          builder: (context, statusSnapshot) {
            if (statusSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingChatItem();
            }

            final isActive = statusSnapshot.data == 'active';
            final statusMessage = entityType == "Item" 
                ? "This item has been beesed or removed" 
                : "This request has been solved or removed";

            return StreamBuilder<int>(
              stream: MessageController().getSentMessagesCount(chatRoomId, currentUser.uid, otherUserId),
              builder: (context, messageCountSnapshot) {
                if (messageCountSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingChatItem();
                }

                int messageCount = messageCountSnapshot.data ?? 0;
                isRead = messageCount == 0; // Update isRead based on message count

                return Dismissible(
                  key: Key(chatRoomId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, color: Colors.white),
                        SizedBox(height: 4),
                        Text(
                          'Delete',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(
                            "Delete Conversation",
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          content: Text(
                            "Are you sure you want to delete this conversation?",
                            style: GoogleFonts.nunito(
                              color: textDark,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                "Cancel",
                                style: GoogleFonts.nunito(
                                  color: textLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Delete",
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        );
                      },
                    );
                  },
                  onDismissed: (direction) async {
                    await FirebaseFirestore.instance
                      .collection('chatRooms')
                      .doc(chatRoomId)
                      .delete();
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: isActive ? () async {
                        if (entityType == "Item") {
                          String itemId = entity['itemId'];
                          Item itemEntity = Item.fromJson(entity, itemId);
                          await _navigateToMessageScreen(chatRoomId, itemEntity, entityType, context);
                          setState(() {
                            isRead = true; // Mark as read when clicked
                          });
                        } else if (entityType == "Request") {
                          Request reqEntity = Request.fromJson2(entity);
                          await _navigateToMessageScreen(chatRoomId, reqEntity, entityType, context);
                          setState(() {
                            isRead = true; // Mark as read when clicked
                          });
                        }
                      } : null,
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          backgroundImage: userProfilePic.isNotEmpty
                              ? NetworkImage(userProfilePic)
                              : null,
                          child: userProfilePic.isEmpty
                              ? Icon(Icons.person, color: primaryYellow)
                              : null,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                userName,
                                style: GoogleFonts.nunito(
                                  fontWeight: !isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 16,
                                  color: isActive ? textDark : textLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(lastMessageTimestamp.toDate().toLocal()),
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: textLight,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.white : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isActive ? primaryYellow : Colors.grey.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    entityType == "Item" ? Icons.shopping_bag : Icons.assignment,
                                    size: 12,
                                    color: isActive ? primaryYellow : Colors.grey,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    isActive ? displayMessage : statusMessage,
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      color: isActive ? textDark : textLight,
                                      fontWeight: !isRead && isActive
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm').format(lastMessageTimestamp.toDate().toLocal()),
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: textLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: messageCount > 0 && isActive
                            ? Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryYellow,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  messageCount > 99 ? '99+' : messageCount.toString(),
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      } else {
        return _buildErrorChatItem("User data not found");
      }
    },
  );
}

  Widget _buildLoadingChatItem() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.withOpacity(0.2),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
            ),
          ),
        ),
        title: Container(
          height: 16,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: Container(
          height: 14,
          margin: EdgeInsets.only(top: 8),
          width: 200,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorChatItem(String errorMessage) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.withOpacity(0.2),
          child: Icon(Icons.error_outline, color: Colors.red),
        ),
        title: Text(
          "Error",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        subtitle: Text(
          errorMessage,
          style: GoogleFonts.nunito(
            color: textLight,
          ),
        ),
      ),
    );
  }

  Future<String> _getEntityStatus(String entityType, dynamic entity) async {
    try {
      if (entityType == "Item") {
        String itemId = entity['itemId'];
        DocumentSnapshot itemDoc = await _firestore.collection('items').doc(itemId).get();
        if (!itemDoc.exists) return 'inactive';
        var itemData = itemDoc.data() as Map<String, dynamic>;
        return itemData['itemStatus'] ?? 'inactive';
      } else if (entityType == "Request") {
        String requestId = entity['requestID'];
        DocumentSnapshot requestDoc = await _firestore.collection('requests').doc(requestId).get();
        if (!requestDoc.exists) return 'inactive';
        var requestData = requestDoc.data() as Map<String, dynamic>;
        return requestData['requestStatus'] ?? 'inactive';
      }
      return 'inactive';
    } catch (e) {
      print("Error getting entity status: $e");
      return 'inactive';
    }
  }

 Future<void> _navigateToMessageScreen(
  String chatRoomId, 
  dynamic entity, 
  String entityType, 
  BuildContext context
) async {
  String currentUserId = auth_user.FirebaseAuth.instance.currentUser!.uid;

  List<String> parts = chatRoomId.split("_");
  parts.removeAt(0);

  String senderId = parts.firstWhere((id) => id != currentUserId, orElse: () => '');
  String receiverId = currentUserId;

  if (senderId.isEmpty) {
    print('Invalid chat room.');
    return;
  }

  // Mark messages as read before navigating
  await MessageController().markMessagesAsRead(
    chatRoomId: chatRoomId,
    currentUserId: currentUserId,
    otherUserId: senderId,
  );

  // Mark notifications as read
  await NotificationController().markMessageNotificationsAsRead(
    chatRoomId: chatRoomId,
    currentUserId: currentUserId,
  );

  // Navigate to the chat screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MessageScreen(
        chatRoomId: chatRoomId,
        senderId: senderId,
        receiverId: receiverId,
        entity: entity,
        entityType: entityType,
      ),
    ),
  );
}



bool _showHeader = true;

  // Update the scaffold background to white
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: Text(
        "Messages",
        style: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
      ),
      backgroundColor: backgroundColor,
      elevation: 0,
    ),
    body: Column(
      children: [
  if (_showHeader)
    Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showHeader = false; // ❌ Close header when tapped
              });
            },
            child: Icon(Icons.close, color: primaryYellow),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Swipe left to delete conversations. Tap to view messages.",
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: textLight,
              ),
            ),
          ),
        ],
      ),
    ),


        
        // Chat list
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                  ),
                )
              : StreamBuilder<List<ChatRoom>>(
                  stream: _getChatRooms(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error loading messages',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please try again later',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                color: textLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: textLight.withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your conversations will appear here',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                color: textLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    List<ChatRoom> sortedChatRooms = snapshot.data!;
                    sortedChatRooms.sort((a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp));

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      itemCount: sortedChatRooms.length,
                      itemBuilder: (context, index) {
                        return _buildChatRoomItem(sortedChatRooms[index]);
                      },
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
}
