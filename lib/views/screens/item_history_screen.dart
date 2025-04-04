import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/controllers/user_profile_controller.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ItemHistoryScreen extends StatefulWidget {
  const ItemHistoryScreen({Key? key}) : super(key: key);

  @override
  _ItemHistoryScreenState createState() => _ItemHistoryScreenState();
}

class _ItemHistoryScreenState extends State<ItemHistoryScreen> with SingleTickerProviderStateMixin {
  final UserProfileController _controller = UserProfileController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  
  // 0 = Inactive Items, 1 = Beesed Items
  int _selectedSegment = 0;
  bool _isLoading = false;
  bool _isHeaderVisible = true;
  
  // Animation controller
  late AnimationController _animationController;
  
  // Custom color palette - More professional white-based theme
  final Color primaryAccent = Color(0xFFFFC857);
  final Color lightAccent = Color(0xFFFFF8E8);
  final Color backgroundColor = Colors.white;
  final Color cardColor = Colors.white;
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);
  final Color dividerColor = Color(0xFFF0F0F0);
  
  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    
    // Add scroll listener for header visibility
    _scrollController.addListener(_handleScroll);
    
    // Start the animation
    _animationController.forward();
  }
  
  void _handleScroll() {
    // Show header when scrolling up, hide when scrolling down
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = false;
        });
      }
    } 
    
    if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = true;
        });
      }
    }
  }
  
  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _animationController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Item History',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: textDark,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Please sign in to view your item history',
            style: GoogleFonts.nunito(),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Item History',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: textDark,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        
      ),
      body: Column(
        children: [
          // Animated Header with segmented control
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _isHeaderVisible ? 70 : 0,
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: AnimatedOpacity(
              opacity: _isHeaderVisible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        _buildSegmentButton(0, 'Inactive Items'),
                        _buildSegmentButton(1, 'Beesed Items'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Status indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: backgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  _selectedSegment == 0 ? 'Inactive Items' : 'Beesed Items',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
          
          // Items List
          Expanded(
            child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                  ),
                )
              : _selectedSegment == 0
                ? _buildInactiveItemsList(user.uid)
                : _buildBeesedItemsList(user.uid),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSegmentButton(int index, String title) {
    final bool isSelected = _selectedSegment == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedSegment != index) {
            setState(() {
              _selectedSegment = index;
            });
          }
        },
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.nunito(
              color: isSelected ? Colors.white : textLight,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInactiveItemsList(String userId) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('items')
          .where('itemOwnerId', isEqualTo: userId)
          .where('itemStatus', isEqualTo: 'inactive')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
              strokeWidth: 3,
            ),
          );
        }

        if (snapshot.hasError) {
          print("Error fetching inactive items: ${snapshot.error}");
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                SizedBox(height: 16),
                Text(
                  "Error loading inactive items",
                  style: GoogleFonts.nunito(
                    color: Colors.red.shade300, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: GoogleFonts.nunito(
                    color: textLight, 
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inventory_2_outlined,
            message: "No inactive items found",
            description: "Items you delete will appear here"
          );
        }

        // Sort items by lastModifiedDate (most recent first)
        final sortedDocs = List<DocumentSnapshot>.from(snapshot.data!.docs);
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          
          final Timestamp? aTimestamp = aData['lastModifiedDate'] as Timestamp?;
          final Timestamp? bTimestamp = bData['lastModifiedDate'] as Timestamp?;
          
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          
          return bTimestamp.compareTo(aTimestamp); // Descending order (newest first)
        });

        final items = sortedDocs.map((doc) {
          try {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return {
              'item': Item.fromJson(data, doc.id),
              'timestamp': data['lastModifiedDate'] as Timestamp?,
            };
          } catch (e) {
            print("Error parsing item: $e");
            return null;
          }
        }).where((item) => item != null).toList();

        if (items.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inventory_2_outlined,
            message: "No inactive items found",
            description: "Items you delete will appear here"
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final itemData = items[index]!;
            return _buildItemCard(itemData['item'] as Item, itemData['timestamp'] as Timestamp?);
          },
        );
      },
    );
  }
  
  Widget _buildBeesedItemsList(String userId) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('beesed_items')
          .where('itemOwnerId', isEqualTo: userId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
              strokeWidth: 3,
            ),
          );
        }

        if (snapshot.hasError) {
          print("Error fetching beesed items: ${snapshot.error}");
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                SizedBox(height: 16),
                Text(
                  "Error loading beesed items",
                  style: GoogleFonts.nunito(
                    color: Colors.red.shade300, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: GoogleFonts.nunito(
                    color: textLight, 
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            message: "No beesed items found",
            description: "Items you mark as BEESED will appear here"
          );
        }

        // Sort items by beesedDate (most recent first)
        final sortedDocs = List<DocumentSnapshot>.from(snapshot.data!.docs);
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          
          final Timestamp? aTimestamp = aData['beesedDate'] as Timestamp?;
          final Timestamp? bTimestamp = bData['beesedDate'] as Timestamp?;
          
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          
          return bTimestamp.compareTo(aTimestamp); // Descending order (newest first)
        });

        final items = sortedDocs.map((doc) {
          try {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return {
              'item': Item.fromJson(data, doc.id),
              'timestamp': data['beesedDate'] as Timestamp?,
            };
          } catch (e) {
            print("Error parsing beesed item: $e");
            return null;
          }
        }).where((item) => item != null).toList();

        if (items.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            message: "No beesed items found",
            description: "Items you mark as BEESED will appear here"
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final itemData = items[index]!;
            return _buildItemCard(itemData['item'] as Item, itemData['timestamp'] as Timestamp?);
          },
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
                color: textDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: textLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(Timestamp? timestamp) {
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
  
  Widget _buildItemCard(Item item, Timestamp? timestamp) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
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
          // Item content
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: item.photoUrl != null && item.photoUrl!.isNotEmpty
                        ? Image.network(
                            item.photoUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[100],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print("Error loading image: $error");
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[100],
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[100],
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _selectedSegment == 0 
                                  ? Colors.orange.withOpacity(0.1) 
                                  : lightAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedSegment == 0 
                                      ? Icons.inventory_2_outlined 
                                      : Icons.check_circle_outline,
                                  color: _selectedSegment == 0 
                                      ? Colors.orange 
                                      : primaryAccent,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _selectedSegment == 0 ? 'Inactive' : 'Beesed',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedSegment == 0 
                                        ? Colors.orange 
                                        : primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatDate(timestamp),
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textLight,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Item title
                      Text(
                        item.title,
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      
                      // Item description
                      Text(
                        item.description ?? "",
                        style: GoogleFonts.nunito(
                          color: textLight,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 10),
                      
                      // Tags and price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Tags in a row with limited width
                          Expanded(
                            child: (item.category != null && item.category!.isNotEmpty) || 
                                  (item.condition != null && item.condition!.isNotEmpty) ||
                                  (item.itemType != null && item.itemType!.isNotEmpty)
                              ? Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    if (item.category != null && item.category!.isNotEmpty)
                                      _buildChip(item.category!),
                                    if (item.condition != null && item.condition!.isNotEmpty)
                                      _buildChip(item.condition!),
                                    if (item.itemType != null && item.itemType!.isNotEmpty)
                                      _buildChip(item.itemType!),
                                  ],
                                )
                              : SizedBox.shrink(),
                          ),
                          
                          SizedBox(width: 8),
                          
                          // Price
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '₺${item.price.toStringAsFixed(2)}',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Footer with favorite count if present
          if (item.favoriteCount > 0)
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Colors.red[300],
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${item.favoriteCount} ${item.favoriteCount == 1 ? 'person likes' : 'people like'} this item',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          color: textLight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.nunito(
            color: isError ? Colors.white : textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? Colors.red : Colors.grey[200],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
        elevation: 2,
      ),
    );
  }
}