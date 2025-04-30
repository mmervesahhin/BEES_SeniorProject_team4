import 'dart:io';

import 'package:bees/views/screens/detailed_item_screen.dart';
import 'package:flutter/material.dart';

import 'detailed_request_screen.dart';
import 'package:bees/models/user_model.dart';
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
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MessageScreen extends StatefulWidget {
  final String? chatRoomId;
  final dynamic entity;
  final String entityType;
  final String senderId;
  final String receiverId;

  const MessageScreen({
    Key? key,
    this.chatRoomId,
    required this.entity,
    required this.entityType,
    required this.senderId,
    required this.receiverId,
  }) : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final BlockedUserController _blockedUserController = BlockedUserController();
  bool _isAttachmentMenuOpen = false;
  bool _isSending = false;
  VideoPlayerController? _videoPlayerController;

  // Color scheme
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);
  final Color backgroundColor = Color(0xFFF8F8F8);

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  String truncateText(String text, int maxLength) {
    return (text.length > maxLength)
        ? '${text.substring(0, maxLength)}...'
        : text;
  }

  Future<User?> _getUserDetails(String userID) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
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

  void _navigateToProfile(String userId, BuildContext context) {
    if (userId == auth_user.FirebaseAuth.instance.currentUser!.uid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => OthersUserProfileScreen(userId: userId)),
      );
    }
  }

  Future<void> _addUserToRemovedUserIds(
      String senderId, String receiverId) async {
    final chatRoomRef = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.chatRoomId);
    final chatRoomSnapshot = await chatRoomRef.get();

    if (chatRoomSnapshot.exists) {
      final chatRoomData = chatRoomSnapshot.data()!;
      List<String> removedUserIds =
          List<String>.from(chatRoomData['removedUserIds'] ?? []);

      if (!removedUserIds.contains(senderId)) removedUserIds.add(senderId);
      if (!removedUserIds.contains(receiverId)) removedUserIds.add(receiverId);

      await chatRoomRef.update({
        'removedUserIds': removedUserIds,
      });
    }
  }

  void sendMessage() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message cannot be empty',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    String currentUserId = auth_user.FirebaseAuth.instance.currentUser!.uid;
    String finalSenderId =
        (currentUserId == widget.senderId) ? widget.receiverId : currentUserId;
    String finalReceiverId =
        (currentUserId == widget.senderId) ? currentUserId : widget.senderId;

    // Check if user is blocked
    bool isBlockedByReceiver =
        await _blockedUserController.isUserBlocked(finalReceiverId);
    //bool isCurrentUserBlocked =
    //  await _blockedUserController.isUserBlocked(finalSenderId);
    bool isCurrentUserBlocked = await _blockedUserController.isBlockedByUser(
        currentUserId, finalReceiverId);

    if (isCurrentUserBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You cannot send a message to this user.',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSending = false;
      });
      return;
    }

    if (isBlockedByReceiver) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You have blocked this user. Unblock to send messages.',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSending = false;
      });
      return;
    }

    String id = "";
    if (widget.entityType == "Item") {
      id = widget.entity.itemId;
    } else if (widget.entityType == "Request") {
      id = widget.entity.requestID;
    }

    await MessageController().sendMessage(
      itemReqId: id,
      receiverId: finalReceiverId,
      content: _messageController.text,
      entityType: widget.entityType,
      entity: widget.entity,
    );

    await _addUserToRemovedUserIds(finalSenderId, finalReceiverId);

    _messageController.clear();
    setState(() {
      _isSending = false;
    });

    // Scroll to bottom after sending
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget messageStatusIcon(String status) {
    switch (status) {
      case 'sent':
        return Icon(Icons.check, color: Colors.grey, size: 16);
      case 'read':
        return Icon(Icons.done_all, color: Colors.blueGrey, size: 16);
      case 'failed':
        return Icon(Icons.error_outline, color: Colors.red, size: 16);
      case 'sending':
        return Icon(Icons.access_time, color: Colors.blueGrey, size: 16);
      default:
        return SizedBox.shrink();
    }
  }

  Future<void> _sendImageMessage(XFile image) async {
    setState(() {
      _isSending = true;
      _isAttachmentMenuOpen = false;
    });

    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef =
          FirebaseStorage.instance.ref().child('chat_images/$fileName');
      UploadTask uploadTask = storageRef.putFile(File(image.path));
      String currentUserId = auth_user.FirebaseAuth.instance.currentUser!.uid;

      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();
      String finalReceiverId =
          (currentUserId == widget.senderId) ? currentUserId : widget.senderId;

      String id = "";
      if (widget.entityType == "Item") {
        id = widget.entity.itemId;
      } else if (widget.entityType == "Request") {
        id = widget.entity.requestID;
      }

      await MessageController().sendMessage(
        itemReqId: id,
        receiverId: finalReceiverId,
        content: imageUrl,
        entityType: widget.entityType,
        entity: widget.entity,
      );
    } catch (e) {
      print("Error sending image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send image',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _sendVideoMessage(XFile video) async {
    setState(() {
      _isSending = true;
      _isAttachmentMenuOpen = false;
    });

    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      Reference storageRef =
          FirebaseStorage.instance.ref().child('chat_videos/$fileName');
      UploadTask uploadTask = storageRef.putFile(File(video.path));
      String currentUserId = auth_user.FirebaseAuth.instance.currentUser!.uid;

      TaskSnapshot snapshot = await uploadTask;
      String videoUrl = await snapshot.ref.getDownloadURL();
      String finalReceiverId =
          (currentUserId == widget.senderId) ? currentUserId : widget.senderId;

      String id = "";
      if (widget.entityType == "Item") {
        id = widget.entity.itemId;
      } else if (widget.entityType == "Request") {
        id = widget.entity.requestID;
      }

      await MessageController().sendMessage(
        itemReqId: id,
        receiverId: finalReceiverId,
        content: videoUrl,
        entityType: widget.entityType,
        entity: widget.entity,
      );
    } catch (e) {
      print("Error sending video: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send video',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Widget _buildVideoPlayer(String videoUrl) {
    _videoPlayerController = VideoPlayerController.network(videoUrl);

    return FutureBuilder<void>(
      future: _videoPlayerController!.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_videoPlayerController!.value.hasError) {
            return Center(
              child: Text(
                'Error loading video',
                style: GoogleFonts.nunito(color: Colors.red),
              ),
            );
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 200,
                  height: 150,
                  child: AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: VideoPlayer(_videoPlayerController!),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _videoPlayerController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    _videoPlayerController!.value.isPlaying
                        ? _videoPlayerController!.pause()
                        : _videoPlayerController!.play();
                  });
                },
              ),
            ],
          );
        } else {
          return Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;
    if (data == null) return SizedBox.shrink();

    auth_user.User firebaseUser = auth_user.FirebaseAuth.instance.currentUser!;
    bool isSentMessage = data['senderId'] == firebaseUser.uid;
    String status = data['status'] ?? '';
    Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
    String timeString = DateFormat('HH:mm').format(timestamp.toDate());

    return FutureBuilder<User?>(
      future: _getUserDetails(data['senderId']),
      builder: (context, snapshot) {
        String senderName = "Unknown";
        if (snapshot.connectionState == ConnectionState.waiting) {
          senderName = "Loading...";
        } else if (snapshot.hasData && snapshot.data != null) {
          senderName = "${snapshot.data!.firstName} ${snapshot.data!.lastName}";
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment:
                isSentMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar for received messages
              if (!isSentMessage)
                GestureDetector(
                  onTap: () => _navigateToProfile(data['senderId'], context),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: snapshot.hasData && snapshot.data != null
                        ? NetworkImage(snapshot.data!.profilePicture)
                        : null,
                    backgroundColor: lightYellow,
                    child: (!snapshot.hasData ||
                            snapshot.data == null ||
                            snapshot.data!.profilePicture.isEmpty)
                        ? Icon(Icons.person, color: primaryYellow, size: 16)
                        : null,
                  ),
                ),

              SizedBox(width: !isSentMessage ? 8 : 0),

              // Message content
              Flexible(
                child: Column(
                  crossAxisAlignment: isSentMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Sender name for received messages
                    if (!isSentMessage)
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
                        child: Text(
                          senderName,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textLight,
                          ),
                        ),
                      ),

                    // Message bubble
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSentMessage ? primaryYellow : Colors.white,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: isSentMessage
                              ? Radius.circular(0)
                              : Radius.circular(16),
                          bottomLeft: !isSentMessage
                              ? Radius.circular(0)
                              : Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Message content (text, image, or video)
                          if (data['content'].toString().startsWith('http') &&
                              data['content'].toString().endsWith('.mp4'))
                            _buildVideoPlayer(data['content'])
                          else if (data['content']
                              .toString()
                              .startsWith('http'))
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                data['content'],
                                width: 200,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 200,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                primaryYellow),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child:
                                          Icon(Icons.error, color: Colors.red),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Text(
                              data['content'],
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                color: isSentMessage ? Colors.white : textDark,
                              ),
                            ),

                          // Time and status
                          SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                timeString,
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  color: isSentMessage
                                      ? Colors.white.withOpacity(0.8)
                                      : textLight,
                                ),
                              ),
                              SizedBox(width: 4),
                              if (isSentMessage) messageStatusIcon(status),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: isSentMessage ? 8 : 0),

              // Avatar for sent messages
              if (isSentMessage)
                GestureDetector(
                  onTap: () => _navigateToProfile(data['senderId'], context),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: snapshot.hasData && snapshot.data != null
                        ? NetworkImage(snapshot.data!.profilePicture)
                        : null,
                    backgroundColor: lightYellow,
                    child: (!snapshot.hasData ||
                            snapshot.data == null ||
                            snapshot.data!.profilePicture.isEmpty)
                        ? Icon(Icons.person, color: primaryYellow, size: 16)
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageList() {
    String id = "";
    if (widget.entityType == "Item") {
      id = widget.entity.itemId;
    } else if (widget.entityType == "Request") {
      id = widget.entity.requestID;
    }

    return StreamBuilder(
      stream: MessageController()
          .getMessages(id, widget.senderId, widget.receiverId),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading messages',
              style: GoogleFonts.nunito(color: Colors.red),
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                    fontSize: 16,
                    color: textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start the conversation!',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: textLight,
                  ),
                ),
              ],
            ),
          );
        }

        // Scroll to bottom after loading messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return _buildMessageItem(snapshot.data!.docs[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String id = "";
    String name = "";
    //String userID = "";

    if (widget.entityType == "Item") {
      id = widget.entity.itemId;
      name = truncateText(widget.entity.title, 30);
      //userID = widget.entity.itemOwnerId;
    } else if (widget.entityType == "Request") {
      id = widget.entity.requestID;
      name = truncateText(widget.entity.requestContent, 30);
      //userID = widget.entity.requestOwnerID;
    }

    String currentUserId = auth_user.FirebaseAuth.instance.currentUser!.uid;

    // Alıcı ID'sini belirle (sendMessage fonksiyonundaki mantıkla aynı)
    String userID = (currentUserId == widget.senderId)
        ? widget.receiverId
        : widget.senderId;

    return GestureDetector(
      onTap: () {
        // Close attachment menu when tapping outside
        if (_isAttachmentMenuOpen) {
          setState(() {
            _isAttachmentMenuOpen = false;
          });
        }
        // Dismiss keyboard
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          title: FutureBuilder<User?>(
            future: _getUserDetails(userID),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text(
                  'Loading...',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return Text(
                  'Unknown User',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }

              User user = snapshot.data!;
              return GestureDetector(
                onTap: () => _navigateToProfile(user.userID, context),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: textLight,
                          width: 2.0,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(user.profilePicture),
                        backgroundColor: Colors.white,
                        onBackgroundImageError: (exception, stackTrace) {
                          print("Image loading failed: $exception");
                        },
                        child: user.profilePicture.isEmpty
                            ? Icon(Icons.person, color: primaryYellow, size: 16)
                            : null,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${user.firstName} ${user.lastName}",
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Tap to view profile",
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: textDark.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          iconTheme: IconThemeData(color: textDark),
        ),
        body: Column(
          children: [
            // Item/Request info card
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Conversation about:",
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: textLight,
                    ),
                  ),
                  SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      if (widget.entityType == "Item") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailedItemScreen(
                              itemId: id,
                            ),
                          ),
                        );
                      } else if (widget.entityType == "Request") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailedRequestScreen(
                              request: widget.entity,
                            ),
                          ),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          widget.entityType == "Item"
                              ? Icons.shopping_bag
                              : Icons.assignment,
                          color: primaryYellow,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryYellow,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: primaryYellow,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: _buildMessageList(),
            ),

            // Attachment menu
            if (_isAttachmentMenuOpen)
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.photo,
                      label: "Gallery",
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final List<XFile>? images =
                            await picker.pickMultiImage();
                        if (images != null && images.isNotEmpty) {
                          for (var image in images) {
                            await _sendImageMessage(image);
                          }
                        }
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.camera_alt,
                      label: "Camera",
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? photo =
                            await picker.pickImage(source: ImageSource.camera);
                        if (photo != null) {
                          await _sendImageMessage(photo);
                        }
                      },
                    ),
                  ],
                ),
              ),

            // Message input
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isAttachmentMenuOpen ? Icons.close : Icons.attach_file,
                      color: primaryYellow,
                    ),
                    onPressed: () {
                      setState(() {
                        _isAttachmentMenuOpen = !_isAttachmentMenuOpen;
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.nunito(
                        color: textDark,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: GoogleFonts.nunito(
                          color: textLight,
                          fontSize: 16,
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: primaryYellow),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  _isSending
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primaryYellow),
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.send, color: primaryYellow),
                          onPressed: sendMessage,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: primaryYellow, width: 1),
            ),
            child: Icon(icon, color: primaryYellow, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }
}
