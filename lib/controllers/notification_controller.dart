import 'package:bees/views/screens/rating_dialog_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return {
                'id': doc.id,
                ...doc.data(),
              };
            }).toList());
  }

  Future<dynamic> fetchEntity(String itemId, String entityType) async {
  final doc = await FirebaseFirestore.instance
      .collection(entityType == "Item" ? "items" : "requests")
      .doc(itemId)
      .get();
  return doc.data();
}


  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print("❌ Failed to mark notification as read: $e");
      rethrow;
    }
  }

  Future<void> submitRating({
    required String sellerId,
    required double rating,
    required String notificationId,
    required String itemId,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(sellerId);
      
      // Add the rating to the seller's ratings subcollection
      await _firestore
          .collection('users')
          .doc(sellerId)
          .collection('ratings')
          .add({
        'rating': rating,
        'itemId': itemId,
        'buyerId': FirebaseAuth.instance.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update the seller's average rating
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        
        // Check if the user document has the rating fields
        double currentRating = 0.0;
        int ratingCount = 0;
        
        if (snapshot.exists) {
          if (snapshot.data()!.containsKey('userRating')) {
            currentRating = (snapshot.data()!['userRating'] as num).toDouble();
          }
          if (snapshot.data()!.containsKey('ratingCount')) {
            ratingCount = (snapshot.data()!['ratingCount'] as num).toInt();
          }
        }
        
        final newCount = ratingCount + 1;
        final newRating = ((currentRating * ratingCount) + rating) / newCount;

        transaction.update(userRef, {
          'userRating': newRating,
          'ratingCount': newCount,
        });
      });

      // Update the notification as read and rated
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'rated': true,
      });
      
      // Update the item to remove the pending rating flag
      await _firestore.collection('items').doc(itemId).update({
        'pendingSellerRating': false,
      });
      
      // Also update in beesed_items collection if it exists
      final beesedItemDoc = await _firestore.collection('beesed_items').doc(itemId).get();
      if (beesedItemDoc.exists) {
        await _firestore.collection('beesed_items').doc(itemId).update({
          'pendingSellerRating': false,
        });
      }

      print("⭐ Rating submitted for seller $sellerId");
    } catch (e) {
      print("❌ Failed to submit rating: $e");
      rethrow;
    }
  }
  
  // Show rating dialog when a notification is tapped
  void showRatingDialog(
    BuildContext context, {
    required String sellerId,
    required String itemId,
    required String itemTitle,
    required String notificationId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return RatingDialog(
          sellerId: sellerId,
          itemId: itemId,
          itemTitle: itemTitle,
          notificationId: notificationId,
          primaryColor: const Color(0xFF3B893E),
        );
      },
    );
  }
}
