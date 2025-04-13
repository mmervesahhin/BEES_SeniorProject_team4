import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bees/models/request_model.dart';
import 'package:bees/controllers/request_history_controller.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class RequestHistoryScreen extends StatefulWidget {
  const RequestHistoryScreen({Key? key}) : super(key: key);

  @override
  _RequestHistoryScreenState createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen> with SingleTickerProviderStateMixin {
  final RequestHistoryController _controller = RequestHistoryController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Add scroll listener for header visibility
    _scrollController.addListener(() {
      _controller.handleScroll(_scrollController, setState);
    });
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(() {
      _controller.handleScroll(_scrollController, setState);
    });
    _scrollController.dispose();
    super.dispose();
  }
  
  // Show delete confirmation dialog for a single request
  void _showDeleteRequestConfirmation(String requestId, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Request',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: _controller.textDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this request?',
                style: GoogleFonts.nunito(
                  color: _controller.textMedium,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  content,
                  style: GoogleFonts.nunito(
                    color: _controller.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.nunito(
                  color: _controller.textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRequest(requestId);
              },
              child: Text(
                'Delete',
                style: GoogleFonts.nunito(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          elevation: 5,
        );
      },
    );
  }
  
  // Show delete confirmation dialog for all requests
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete All Requests',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: _controller.textDark,
            ),
          ),
          content: Text(
            'Are you sure you want to delete all ${_controller.selectedSegment == 0 ? 'solved' : 'removed'} requests? This action cannot be undone.',
            style: GoogleFonts.nunito(
              color: _controller.textMedium,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.nunito(
                  color: _controller.textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAllRequests();
              },
              child: Text(
                'Delete',
                style: GoogleFonts.nunito(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          elevation: 5,
        );
      },
    );
  }
  
  // Delete a single request
  void _deleteRequest(String requestId) async {
    try {
      bool success = await _controller.deleteRequest(requestId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request deleted successfully',
              style: GoogleFonts.nunito(
                color: _controller.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.grey[100],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: _controller.primaryAccent,
              onPressed: () {
                // Restore the request
                _controller.restoreRequest(
                  requestId, 
                  _controller.selectedSegment == 0 ? 'solved' : 'removed'
                );
              },
            ),
          ),
        );
      } else {
        _showErrorSnackBar();
      }
    } catch (e) {
      print('Error deleting request: $e');
      _showErrorSnackBar();
    }
  }
  
  // Delete all requests
  void _deleteAllRequests() async {
    try {
      bool success = await _controller.deleteAllRequests();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All ${_controller.selectedSegment == 0 ? 'solved' : 'removed'} requests have been deleted',
              style: GoogleFonts.nunito(
                color: _controller.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.grey[100],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: _controller.primaryAccent,
              onPressed: () {},
            ),
          ),
        );
      } else {
        _showErrorSnackBar();
      }
    } catch (e) {
      print('Error deleting all requests: $e');
      _showErrorSnackBar();
    }
  }
  
  // Show error snackbar
  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to delete requests. Try again later.',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final User? user = _controller.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Request History',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: _controller.textDark,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: _controller.textDark),
        ),
        body: Center(
          child: Text(
            'Please sign in to view your request history',
            style: GoogleFonts.nunito(),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: _controller.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Request History',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: _controller.textDark,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: _controller.textDark),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: _controller.textDark),
            onPressed: _showDeleteConfirmation,
            tooltip: 'Delete all',
          ),
        ],
      ),
      body: Column(
        children: [
          // Segment control - hides when scrolling down
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: _controller.isHeaderVisible ? 70 : 0,
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: _controller.backgroundColor,
              boxShadow: _controller.isHeaderVisible ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ] : [],
            ),
            child: _controller.isHeaderVisible 
              ? Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _buildSegmentButton(0, 'Solved Requests'),
                          _buildSegmentButton(1, 'Removed Requests'),
                        ],
                      ),
                    ),
                  ),
                )
              : SizedBox.shrink(),
          ),
          
          // Status indicator - also hide when scrolling down
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: _controller.isHeaderVisible ? 36 : 0,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _controller.backgroundColor,
            child: _controller.isHeaderVisible 
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      _controller.selectedSegment == 0 ? 'Solved Requests' : 'Removed Requests',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _controller.textDark,
                      ),
                    ),
                  ],
                )
              : SizedBox.shrink(),
          ),
          
          // Requests List
          Expanded(
            child: _controller.selectedSegment == 0
              ? _buildSolvedRequestsList(user.uid)
              : _buildRemovedRequestsList(user.uid),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSegmentButton(int index, String title) {
    final bool isSelected = _controller.selectedSegment == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_controller.selectedSegment != index) {
            setState(() {
              _controller.selectedSegment = index;
            });
          }
        },
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? _controller.primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.nunito(
              color: isSelected ? Colors.white : _controller.textLight,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSolvedRequestsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.getSolvedRequestsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_controller.primaryAccent),
              strokeWidth: 3,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                SizedBox(height: 16),
                Text(
                  "Error loading solved requests",
                  style: GoogleFonts.nunito(
                    color: Colors.red.shade300, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            message: "No solved requests found",
            description: "Requests you mark as solved will appear here"
          );
        }

        List<Request> requests = _controller.parseRequests(snapshot.data!);

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            return _controller.handleScrollNotification(scrollNotification, setState);
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final Timestamp? timestamp = (snapshot.data!.docs[index].data() as Map<String, dynamic>)['lastModifiedDate'] as Timestamp?;
              return _buildRequestCard(request, timestamp, isSolved: true);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildRemovedRequestsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.getRemovedRequestsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_controller.primaryAccent),
              strokeWidth: 3,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                SizedBox(height: 16),
                Text(
                  "Error loading removed requests",
                  style: GoogleFonts.nunito(
                    color: Colors.red.shade300, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.delete_outline,
            message: "No removed requests found",
            description: "Requests you delete will appear here"
          );
        }

        List<Request> requests = _controller.parseRequests(snapshot.data!);

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            return _controller.handleScrollNotification(scrollNotification, setState);
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final Timestamp? timestamp = (snapshot.data!.docs[index].data() as Map<String, dynamic>)['lastModifiedDate'] as Timestamp?;
              return _buildRequestCard(request, timestamp, isSolved: false);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String description,
  }) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 28),
            Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _controller.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: _controller.textMedium,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRequestCard(Request request, Timestamp? timestamp, {required bool isSolved}) {
    final Color statusColor = isSolved ? _controller.primaryAccent : _controller.removedColor;
    final Color statusBgColor = isSolved ? _controller.lightAccent : Color(0xFFFFF7ED);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Request content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status, delete icon, and date row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBgColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSolved ? Icons.check_circle_outline : Icons.delete_outline,
                            color: statusColor,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            isSolved ? 'Solved' : 'Removed',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Date with delete icon
                    Row(
                      children: [
                        Text(
                          _controller.formatDate(timestamp),
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _controller.textLight,
                          ),
                        ),
                        SizedBox(width: 8),
                        // Delete button for individual request
                        InkWell(
                          onTap: () {
                            _showDeleteRequestConfirmation(request.requestID, request.requestContent);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: _controller.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Request content
                Text(
                  request.requestContent,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _controller.textDark,
                    height: 1.5,
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Creation date
                Text(
                  'Created: ${DateFormat('MMM d, yyyy').format(request.creationDate)}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: _controller.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

