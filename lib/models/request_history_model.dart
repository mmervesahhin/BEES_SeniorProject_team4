import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bees/models/request_model.dart';

class RequestHistoryModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Colors for the UI
  final Color primaryAccent = Color(0xFFFFC857); // Yellow accent color
  final Color lightAccent = Color(0xFFFFF8E8); // Very light yellow for subtle accents
  final Color backgroundColor = Colors.white;
  final Color cardColor = Colors.white;
  final Color surfaceColor = Color(0xFFF9FAFB); // Very light gray for inputs
  final Color textDark = Color(0xFF333333);
  final Color textMedium = Color(0xFF6B7280);
  final Color textLight = Color(0xFF9CA3AF);
  final Color dividerColor = Color(0xFFE5E7EB);
  final Color solvedColor = Color(0xFFFFC857); // Yellow for solved requests
  final Color removedColor = Color(0xFFF97316); // Orange for removed requests
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Get solved requests stream
  Stream<QuerySnapshot> getSolvedRequestsStream(String userId) {
    return _firestore
        .collection('requests')
        .where('requestOwnerID', isEqualTo: userId)
        .where('requestStatus', isEqualTo: 'solved')
        .orderBy('lastModifiedDate', descending: true)
        .snapshots();
  }
  
  // Get removed requests stream
  Stream<QuerySnapshot> getRemovedRequestsStream(String userId) {
    return _firestore
        .collection('requests')
        .where('requestOwnerID', isEqualTo: userId)
        .where('requestStatus', isEqualTo: 'removed')
        .orderBy('lastModifiedDate', descending: true)
        .snapshots();
  }
  
  // Delete a single request (mark as deleted)
  Future<bool> deleteRequest(String requestId) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'requestStatus': 'deleted',
        'lastModifiedDate': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error deleting request: $e');
      return false;
    }
  }
  
  // Restore a deleted request
  Future<bool> restoreRequest(String requestId, String previousStatus) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'requestStatus': previousStatus, // 'solved' or 'removed'
        'lastModifiedDate': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error restoring request: $e');
      return false;
    }
  }
  
  // Delete all requests of a specific status
  Future<bool> deleteAllRequests(String status) async {
    final User? user = currentUser;
    if (user == null) return false;
    
    try {
      // Get all requests with the current status
      final QuerySnapshot querySnapshot = await _firestore
          .collection('requests')
          .where('requestOwnerID', isEqualTo: user.uid)
          .where('requestStatus', isEqualTo: status)
          .get();
      
      // Update all requests to 'deleted' status
      final batch = _firestore.batch();
      
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'requestStatus': 'deleted',
          'lastModifiedDate': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Error deleting all requests: $e');
      return false;
    }
  }
  
  // Parse requests from query snapshot
  List<Request> parseRequests(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return Request.fromJson(
        Map<String, dynamic>.from(doc.data() as Map<String, dynamic>)
          ..['requestID'] = doc.id
      );
    }).toList();
  }
}
