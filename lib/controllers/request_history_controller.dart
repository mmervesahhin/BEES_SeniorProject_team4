import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bees/models/request_history_model.dart';
import 'package:bees/models/request_model.dart';
import 'package:intl/intl.dart';

class RequestHistoryController {
  final RequestHistoryModel model = RequestHistoryModel();
  
  // State variables
  int selectedSegment = 0;
  bool isHeaderVisible = true;
  double lastScrollPosition = 0;
  
  // Get current user
  get currentUser => model.currentUser;
  
  // Get color properties from model
  Color get primaryAccent => model.primaryAccent;
  Color get lightAccent => model.lightAccent;
  Color get backgroundColor => model.backgroundColor;
  Color get cardColor => model.cardColor;
  Color get surfaceColor => model.surfaceColor;
  Color get textDark => model.textDark;
  Color get textMedium => model.textMedium;
  Color get textLight => model.textLight;
  Color get dividerColor => model.dividerColor;
  Color get solvedColor => model.solvedColor;
  Color get removedColor => model.removedColor;
  
  // Get solved requests stream
  Stream<QuerySnapshot> getSolvedRequestsStream(String userId) {
    return model.getSolvedRequestsStream(userId);
  }
  
  // Get removed requests stream
  Stream<QuerySnapshot> getRemovedRequestsStream(String userId) {
    return model.getRemovedRequestsStream(userId);
  }
  
  // Delete a single request
  Future<bool> deleteRequest(String requestId) async {
    return await model.deleteRequest(requestId);
  }
  
  // Restore a deleted request
  Future<bool> restoreRequest(String requestId, String previousStatus) async {
    return await model.restoreRequest(requestId, previousStatus);
  }
  
  // Delete all requests of a specific status
  Future<bool> deleteAllRequests() async {
    return await model.deleteAllRequests(selectedSegment == 0 ? 'solved' : 'removed');
  }
  
  // Parse requests from query snapshot
  List<Request> parseRequests(QuerySnapshot snapshot) {
    return model.parseRequests(snapshot);
  }
  
  // Format date for display
  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Date not available';
    }
    
    final DateTime date = timestamp.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
  
  // Handle scroll events
  void handleScroll(ScrollController scrollController, Function setState) {
    // Get current position
    final currentPosition = scrollController.position.pixels;
    
    // Determine scroll direction by comparing current position with last position
    if (currentPosition > lastScrollPosition + 10) {
      // Scrolling down
      if (isHeaderVisible) {
        setState(() {
          isHeaderVisible = false;
        });
      }
    } else if (currentPosition < lastScrollPosition - 10) {
      // Scrolling up
      if (!isHeaderVisible) {
        setState(() {
          isHeaderVisible = true;
        });
      }
    }
    
    // Update last position
    lastScrollPosition = currentPosition;
  }
  
  // Handle scroll notifications
  bool handleScrollNotification(ScrollNotification scrollNotification, Function setState) {
    if (scrollNotification is ScrollUpdateNotification) {
      if (scrollNotification.scrollDelta != null && scrollNotification.scrollDelta! > 0) {
        // Scrolling down
        if (isHeaderVisible) {
          setState(() {
            isHeaderVisible = false;
          });
        }
      } else if (scrollNotification.scrollDelta != null && scrollNotification.scrollDelta! < 0) {
        // Scrolling up
        if (!isHeaderVisible && scrollNotification.metrics.pixels < 100) {
          setState(() {
            isHeaderVisible = true;
          });
        }
      }
    }
    return false;
  }
}
