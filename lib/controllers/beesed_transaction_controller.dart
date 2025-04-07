// lib/controllers/beesed_transaction_handler.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bees/models/chat_room_model.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/user_model.dart' as app_user;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:bees/controllers/notification_controller.dart'; // Import notification controller
import 'package:bees/views/screens/user_profile_screen.dart';

class BeesedTransactionHandler {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationController _notificationController = NotificationController();
  
  // Define colors to match login screen
  final Color primaryColor = Color(0xFF3B893E); // Green color from message_list_screen
  final Color accentColor = Colors.amber;
  final Color textColor = Color(0xFF333333);
  final Color lightTextColor = Color(0xFF757575);
  final Color backgroundColor = Colors.white;

  // Get all users who have messaged about a specific item
  Future<List<Map<String, dynamic>>> getUsersWithMessages(String? itemId) async {
    if (itemId == null) {
      print('Error: itemId is null');
      return [];
    }
    
    try {
      print('DEBUG: Searching for chat rooms with itemId: $itemId');
      String currentUserId = _auth.currentUser!.uid;
      print('DEBUG: Current user ID: $currentUserId');
      
      // APPROACH 1: Try to find messages directly related to this item
      print('DEBUG: APPROACH 1 - Searching messages collection');
      QuerySnapshot messagesSnapshot = await _firestore
          .collection('messages')
          .where('itemId', isEqualTo: itemId)
          .limit(20)
          .get();
      
      print('DEBUG: Found ${messagesSnapshot.docs.length} messages directly related to item');
      
      // If we found messages, extract the chat room IDs and user IDs
      Set<String> chatRoomIds = {};
      Set<String> userIds = {};
      
      for (var doc in messagesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('DEBUG: Message data: $data');
        
        if (data.containsKey('chatRoomId')) {
          chatRoomIds.add(data['chatRoomId']);
        }
        
        if (data.containsKey('senderId') && data['senderId'] != currentUserId) {
          userIds.add(data['senderId']);
        }
        
        if (data.containsKey('receiverId') && data['receiverId'] != currentUserId) {
          userIds.add(data['receiverId']);
        }
      }
      
      print('DEBUG: Extracted chat room IDs: $chatRoomIds');
      print('DEBUG: Extracted user IDs: $userIds');
      
      // APPROACH 2: Get all chat rooms for the current user
      print('DEBUG: APPROACH 2 - Getting all chat rooms for current user');
      QuerySnapshot chatRoomsSnapshot = await _firestore
          .collection('chatRooms')
          .where('userIds', arrayContains: currentUserId)
          .get();
      
      print('DEBUG: Found ${chatRoomsSnapshot.docs.length} chat rooms for current user');
      
      // Print details of each chat room for debugging
      for (var doc in chatRoomsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('DEBUG: Chat room ID: ${doc.id}');
        print('DEBUG: Chat room data: $data');
        
        // Check if this chat room is related to our item
        if (data.containsKey('itemReqId')) {
          print('DEBUG: itemReqId: ${data['itemReqId']}');
          if (data['itemReqId'] == itemId) {
            print('DEBUG: ✅ MATCH FOUND - itemReqId matches itemId');
          }
        }
        
        if (data.containsKey('entity') && data['entity'] is Map) {
          Map<String, dynamic> entity = data['entity'];
          print('DEBUG: entity: $entity');
          if (entity.containsKey('itemId')) {
            print('DEBUG: entity.itemId: ${entity['itemId']}');
            if (entity['itemId'] == itemId) {
              print('DEBUG: ✅ MATCH FOUND - entity.itemId matches itemId');
            }
          }
        }
      }
      
      // Combine both approaches to find all relevant users
      List<Map<String, dynamic>> usersList = [];
      
      // APPROACH 3: Direct query to find users who have messaged about this item
      print('DEBUG: APPROACH 3 - Direct query for users who have messaged about this item');
      
      // First, try to get users from chat rooms
      for (var doc in chatRoomsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        bool isRelatedToItem = false;
        
        // Check if this chat room is related to our item
        if (data.containsKey('itemReqId') && data['itemReqId'] == itemId) {
          isRelatedToItem = true;
        } else if (data.containsKey('entity') && data['entity'] is Map) {
          Map<String, dynamic> entity = data['entity'];
          if (entity.containsKey('itemId') && entity['itemId'] == itemId) {
            isRelatedToItem = true;
          }
        }
        
        // If chat room ID is in our extracted list, consider it related
        if (chatRoomIds.contains(doc.id)) {
          isRelatedToItem = true;
          print('DEBUG: ✅ MATCH FOUND - chat room ID matches extracted ID');
        }
        
        if (!isRelatedToItem) continue;
        
        print('DEBUG: Found chat room related to item: ${doc.id}');
        
        ChatRoom chatRoom = ChatRoom.fromFirestore(doc);
        
        // Find the other user in the chat (not the current user)
        String otherUserId = '';
        for (String userId in chatRoom.userIds) {
          if (userId != currentUserId) {
            otherUserId = userId;
            break;
          }
        }
        
        if (otherUserId.isEmpty) continue;
        
        // Get user details
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(otherUserId).get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          usersList.add({
            'userId': otherUserId,
            'firstName': userData['firstName'] ?? 'Unknown',
            'lastName': userData['lastName'] ?? 'User',
            'profilePicture': userData['profilePicture'] ?? '',
            'chatRoomId': chatRoom.chatRoomId,
            'lastMessageTimestamp': chatRoom.lastMessageTimestamp,
          });
          
          print('DEBUG: ✅ Added user to list: ${userData['firstName']} ${userData['lastName']}');
        }
      }
      
      // Then, add any users from our extracted user IDs list
      for (String userId in userIds) {
        // Skip if we already added this user
        if (usersList.any((user) => user['userId'] == userId)) continue;
        
        // Get user details
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          usersList.add({
            'userId': userId,
            'firstName': userData['firstName'] ?? 'Unknown',
            'lastName': userData['lastName'] ?? 'User',
            'profilePicture': userData['profilePicture'] ?? '',
            'chatRoomId': '', // We don't have a specific chat room ID here
            'lastMessageTimestamp': Timestamp.now(), // Use current time as fallback
          });
          
          print('DEBUG: ✅ Added user from messages to list: ${userData['firstName']} ${userData['lastName']}');
        }
      }
      
      print('DEBUG: Final users list size: ${usersList.length}');
      return usersList;
    } catch (e) {
      print('ERROR getting users with messages: $e');
      print('ERROR stack trace: ${StackTrace.current}');
      return [];
    }
  }

  Future<bool> completeTransaction(String? itemId, String buyerId) async {
    if (itemId == null) {
      print('❌ itemId is null');
      return false;
    }

    final itemSnapshot = await _firestore.collection('items').doc(itemId).get();
    if (!itemSnapshot.exists) {
      print('❌ Item does not exist in Firestore.');
      return false;
    }

    final itemData = itemSnapshot.data()!;
    String itemTitle = itemData['title'] ?? "Item";
    String sellerId = _auth.currentUser!.uid;

    print("✅ Başlıyoruz: itemId=$itemId, title=$itemTitle");

    try {
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data() as Map<String, dynamic>;
        final favs = userData['favoriteItems'] ?? [];
        final containsItem = favs.map((e) => e.toString()).contains(itemId.toString());


        print("🟡 $userId kullanıcısının favorileri: $favs");

      
        print("🔍 $userId için eşleşme sonucu: $containsItem");

        if (containsItem) {
          print("✅ BEESED bildirimi ekleniyor → $userId");

          await _firestore.collection('notifications').add({
            'receiverId': userId,
            'itemId': itemId,
            'itemTitle': itemTitle,
            'type': 'item_beesed',
            'message': 'A favorite item "$itemTitle" has been marked as BEESED.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    } catch (e) {
      print("❌ Bildirim eklerken hata: $e");
    }

    // Diğer işlemler (güncelleme ve rate_seller bildirimi)
    try {
      await _firestore.collection('items').doc(itemId).update({
        'itemStatus': 'beesed',
        'buyerId': buyerId,
        'transactionCompletedAt': FieldValue.serverTimestamp(),
        'pendingSellerRating': true,
      });

      await _firestore.collection('beesed_items').doc(itemId).set({
        'additionalPhotos': itemData['additionalPhotos'] ?? [],
        'beesedDate': FieldValue.serverTimestamp(),
        'category': itemData['category'] ?? '',
        'condition': itemData['condition'] ?? '',
        'departments': itemData['departments'] ?? [],
        'description': itemData['description'] ?? '',
        'favoriteCount': itemData['favoriteCount'] ?? 0,
        'itemId': itemId,
        'itemOwnerId': sellerId,
        'itemStatus': 'beesed',
        'itemType': itemData['itemType'] ?? '',
        'lastModifiedDate': FieldValue.serverTimestamp(),
        'paymentPlan': itemData['paymentPlan'],
        'photo': itemData['photo'] ?? itemData['images']?.first ?? '',
        'price': itemData['price'] ?? 0,
        'title': itemTitle,
      });

      await _firestore.collection('notifications').add({
        'receiverId': buyerId,
        'sellerId': sellerId,
        'itemId': itemId,
        'itemTitle': itemTitle,
        'type': 'rate_seller',
        'message': 'Please rate your experience with the seller for the item "$itemTitle".',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      print("✅ Transaction tamamlandı.");
      return true;
    } catch (e) {
      print("❌ Transaction işleminde hata: $e");
      return false;
    }
  }



  // Update user's average rating
  Future<void> _updateUserRating(String userId) async {
    try {
      // Get all ratings for this user
      QuerySnapshot ratingsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      // Calculate average rating
      double totalRating = 0;
      for (var doc in ratingsSnapshot.docs) {
        totalRating += (doc.data() as Map<String, dynamic>)['rating'] as double;
      }
      
      double averageRating = totalRating / ratingsSnapshot.docs.length;
      
      // Update user's average rating
      await _firestore.collection('users').doc(userId).update({
        'userRating': averageRating,
      });
    } catch (e) {
      print('Error updating user rating: $e');
    }
  }

  // Show the BEESED dialog with user selection and rating
  Future<void> showBeesedDialog(BuildContext context, Item item) async {
    if (item.itemId == null) {
      // Show error dialog if itemId is null
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Error',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: Text(
              'Cannot process this item. Item ID is missing.',
              style: GoogleFonts.poppins(),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }
    
    // Create a unique key for the loading dialog
    GlobalKey<State> loadingKey = GlobalKey<State>();
      // 1. Mesajlaşmış kullanıcıları al
      List<Map<String, dynamic>> users = [];
      try {
        users = await getUsersWithMessages(item.itemId); // Bu sana ait fonksiyon
      } catch (e) {
        print('❌ Hata oluştu: $e');
      }
      if (!context.mounted) return;

      // 2. Hiç kullanıcı yoksa bilgi göster
      if (users.isEmpty) {
        _showNoUsersDialog(context);
        return;
      }

    // 3. Kullanıcıyı seçtir
  final selectedUser = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Select Buyer'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user['firstName'] ?? 'Unnamed'),
                subtitle: Text(user['userId']),
                onTap: () => Navigator.pop(context, user),
              );
            },
          ),
        ),
      );
    },
  );


    if (selectedUser == null) {
    print("❌ Kullanıcı seçilmedi");
    return;
  }

  print("👤 Seçilen kullanıcı: ${selectedUser['userId']}");
    
    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            key: loadingKey,
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          );
        },
      );
    }

      bool success = await completeTransaction(item.itemId, selectedUser['userId']);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Item marked as BEESED!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("BEESED işlemi başarısız oldu"), backgroundColor: Colors.red),
        );
      }
      
    await completeTransaction(item.itemId, FirebaseAuth.instance.currentUser!.uid);


    
    try {
      users = await getUsersWithMessages(item.itemId);
    } catch (e) {
      print('Error getting users with messages: $e');
    } finally {
      // Make sure to close loading indicator even if there's an error
      if (context.mounted) {
        // Use rootNavigator to ensure we're popping from the root context
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
    
    // Check if context is still valid before proceeding
    if (!context.mounted) return;
    
    if (users.isEmpty) {
      _showNoUsersDialog(context);
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BeesedUserSelectionDialog(
          item: item,
          users: users,
          primaryColor: primaryColor,
          textColor: textColor,
          lightTextColor: lightTextColor,
          backgroundColor: backgroundColor,
          onUserSelected: (selectedUser) {
            Navigator.pop(context);
            _showConfirmationDialog(context, item, selectedUser);
          },
        );
      },
    );
  }

  // Show dialog when no users have messaged about the item
  void _showNoUsersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'No Messages Found',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          content: Text(
            'No users have messaged you about this item. You need to have a conversation with the buyer before marking the item as BEESED.',
            style: GoogleFonts.poppins(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },

      
    );
    
  }

  // Show confirmation dialog after user selection
 void _showConfirmationDialog(BuildContext context, Item item, Map<String, dynamic> selectedUser) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Confirm Transaction',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to mark this item as BEESED and confirm that ${selectedUser['firstName']} ${selectedUser['lastName']} is the buyer?',
                style: GoogleFonts.poppins(),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                'The buyer will be notified to rate you as a seller.',
                style: GoogleFonts.poppins(
                  fontStyle: FontStyle.italic,
                  color: lightTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close confirmation dialog
              Navigator.pop(context);
              
              if (!context.mounted) return;

              bool success = false;
              try {
                success = await completeTransaction(item.itemId, selectedUser['userId'])
                    .timeout(
                      Duration(seconds: 10),
                      onTimeout: () => false,
                    );
              } catch (e) {
                print("Transaction error: $e");
              }
              
              // Always show the "buyer notified" message on success
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'The buyer will be notified to rate you as a seller.',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: EdgeInsets.all(16),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
              // Show error message only if failed
              else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error completing transaction. Please try again.',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: EdgeInsets.all(16),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      );
    },
  );
}}

// Dialog to select a user from the list
class BeesedUserSelectionDialog extends StatelessWidget {
  final Item item;
  final List<Map<String, dynamic>> users;
  final Function(Map<String, dynamic>) onUserSelected;
  final Color primaryColor;
  final Color textColor;
  final Color lightTextColor;
  final Color backgroundColor;

  const BeesedUserSelectionDialog({
    Key? key,
    required this.item,
    required this.users,
    required this.onUserSelected,
    required this.primaryColor,
    required this.textColor,
    required this.lightTextColor,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: backgroundColor,
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9, // Prevent width overflow
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Buyer',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Select the user who purchased "${item.title}"',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: lightTextColor,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['profilePicture'] != null && user['profilePicture'].isNotEmpty
                            ? NetworkImage(user['profilePicture'])
                            : AssetImage('images/anon_avatar.jpg') as ImageProvider,
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                      ),
                      title: Text(
                        '${user['firstName']} ${user['lastName']}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        'Last message: ${_formatTimestamp(user['lastMessageTimestamp'])}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: lightTextColor,
                        ),
                      ),
                      onTap: () => onUserSelected(user),
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: Colors.grey.shade50,
                    ),
                  );
                },
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: lightTextColor,
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}