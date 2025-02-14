import 'package:bees/views/screens/favorites_screen.dart';
import 'package:bees/views/screens/item_upload_screen.dart';
import 'package:bees/views/screens/requests_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/controllers/home_controller.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> departmentList = [
      'All Departments', 'AMER', 'ARCH', 'CHEM', 'COMD', 'CS', 'CTIS', 'ECON', 'EDU', 'EEE', 'ELIT', 'FA', 'GRA',
      'HART', 'IAED', 'IE', 'IR', 'LAUD', 'LAW', 'MAN', 'MATH', 'MBG', 'ME', 'MSC', 'PHIL', 'PHYS', 'POLS', 'PREP',
      'PSYC', 'THM', 'THR', 'TRIN'
    ];

    List<String> selectedDepartments = [];
                  
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  final HomeController _controller = HomeController();
  final TextEditingController _searchController = TextEditingController();
  Map<String, bool> _favorites = {};
  String _searchQuery = '';
  Map<String, dynamic> _filters = {
    'priceRange': RangeValues(0, 1000),
    'condition': 'All',
    'category': 'All',
    'itemType': 'All',
    'departments' : [],
  };

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color.fromARGB(255, 59, 137, 62),
      automaticallyImplyLeading: false, // Geri butonunu kaldırır
      title: Text(
        'BEES',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.yellow,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.message),
          onPressed: () {},
          color: Colors.black,
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () {
                  _showFiltersDialog();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _controller.getItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('An error occurred: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No items found.'));
              }

              final items = snapshot.data!.docs.where((doc) {
                var title = (doc['title'] ?? '').toString().toLowerCase();
                var price = doc['price'] ?? 0;
                var condition = doc['condition'] ?? 'Unknown';
                var category = doc['category'] ?? 'Unknown';
                var itemType = doc['itemType'] ?? 'Unknown';
                var departments = doc['departments'] ?? [];

                bool matchesSearch = title.contains(_searchQuery);
                bool matchesFilters = _controller.applyFilters(price, condition, category, itemType, departments, _filters);

                return matchesSearch && matchesFilters;
              }).toList();

              items.sort((a, b) {
                var titleA = (a['title'] ?? '').toString().toLowerCase();
                var titleB = (b['title'] ?? '').toString().toLowerCase();
                return titleA.indexOf(_searchQuery).compareTo(titleB.indexOf(_searchQuery));
              });

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.7,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  var item = items[index].data() as Map<String, dynamic>;
                  String itemId = items[index].id;

                  bool isFavorited = _favorites[itemId] ?? false;

                  String imageUrl = _controller.getImageUrl(item['photo']);
                  String category = _controller.getCategory(item['category']);
                  List<String> departments = _controller.getDepartments(item['departments']);
                  String condition = item['condition'] ?? 'Unknown';

                  bool hidePrice = category.toLowerCase() == 'donate' || category.toLowerCase() == 'exchange';

                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            if (imageUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Image.network(
                                  imageUrl,
                                  height: 120,
                                  width: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'],
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    SizedBox(height: 5),
                                    if (!hidePrice)
                                      Row(
                                        children: [
                                          Text('₺${item['price']}'),
                                          SizedBox(width: 5),
                                          if (item['paymentPlan'] != null)
                                          Text(
                                            item['paymentPlan'],
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 59, 137, 62), // Green container for category
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 240, 217, 11), // Yellow for condition
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      condition,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            // Orange container for departments
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        departments[0],
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    // Additional orange box if there are more than one department
                                    if (departments.length > 1) ...[
                                      SizedBox(width: 4),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold, // This makes the text bold
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFavorited ? Icons.favorite : Icons.favorite_border,
                                color: isFavorited ? Colors.red : Colors.grey,
                              ),
                              onPressed: () async {
                                setState(() {
                                  _favorites[itemId] = !isFavorited;
                                });

                                _controller.updateFavoriteCount(itemId, !isFavorited, userId!);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadItemPage()),
                );
      },
      backgroundColor: Color.fromARGB(255, 59, 137, 62),
      child: Icon(Icons.add, color: Colors.white),
    ),
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 59, 137, 62),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.shop),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
            
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => HomeScreen(),
              ));
              break;
            case 1:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => RequestsScreen(),
              ));
              break;
            case 2:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => FavoritesScreen(),
              ));
              break;
            case 3:
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => UserProfileScreen(),
              ));
              break;
          }
        },
      ),
    ),
  );
}

void _showFiltersDialog() {
  // Create controllers only once for the dialog
  TextEditingController minPriceController =
      TextEditingController(text: _filters['minPrice']?.toString() ?? '');
  TextEditingController maxPriceController =
      TextEditingController(text: _filters['maxPrice']?.toString() ?? '');
  String errorMessage = ''; // Variable to hold the error message

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: Center(
              child: Text(
                'Filter Items',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 59, 137, 62)),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price Range Section
                  Text(
                    'Price Range',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Min Price',
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              _filters['minPrice'] = value.isEmpty ? null : double.tryParse(value);
                            });
                          },
                          enabled: _filters['category'] != 'Donation' && _filters['category'] != 'Exchange',
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Max Price',
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              _filters['maxPrice'] = value.isEmpty ? null : double.tryParse(value);
                            });
                          },
                          enabled: _filters['category'] != 'Donation' && _filters['category'] != 'Exchange',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (errorMessage.isNotEmpty) 
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  SizedBox(height: 16),
                  // Departments Section
                  Text(
                    'Departments',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  MultiSelectDialogField(
                    items: departmentList.map((e) => MultiSelectItem(e, e)).toList(),
                    initialValue: selectedDepartments.where((dept) => dept != 'All Departments').toList(),
                    onConfirm: (values) {
                      setDialogState(() {
                        selectedDepartments = values;

                        // If 'All Departments' is selected, select all departments and remove 'All Departments' from the list
                        if (selectedDepartments.contains('All Departments')) {
                          selectedDepartments = List.from(departmentList);
                          // selectedDepartments.remove('All Departments');
                        }

                        // If no departments are selected, add 'All Departments' to the list
                        if (selectedDepartments.isEmpty) {
                          selectedDepartments.add('All Departments');
                        }

                        // Update the _filters['departments'] with the selected departments
                        _filters['departments'] = selectedDepartments;
                      });
                    },
                    onSelectionChanged: (selectedList) {
                      setDialogState(() {
                        if (selectedList.contains('All Departments') && selectedList.length == departmentList.length) {
                          // Keep 'All Departments' selected if all are selected
                          selectedDepartments = List.from(departmentList);
                        } else if (!selectedList.contains('All Departments')) {
                          // Uncheck 'All Departments' if not all are selected
                          selectedDepartments = selectedList;
                        }

                        // Update _filters['departments'] whenever selection changes
                        _filters['departments'] = selectedDepartments;
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Condition Section
                  Text(
                    'Condition',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: _filters['condition'],
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        _filters['condition'] = newValue!;
                      });
                    },
                    items: <String>[
                      'All',
                      'New',
                      'Lightly Used',
                      'Moderately Used',
                      'Heavily Used'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),

                  // Item Type Section
                  Text(
                    'Item Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: _filters['itemType'],
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        _filters['itemType'] = newValue!;
                      });
                    },
                    items: <String>[
                      'All',
                      'Notes',
                      'Books',
                      'Electronics',
                      'Stationery',
                      'Other'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),

                  // Category Section
                  Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: _filters['category'],
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        _filters['category'] = newValue!;
                      });
                    },
                    items: <String>[
                      'All',
                      'Sale',
                      'Rent',
                      'Exchange',
                      'Donation'
                      
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        _filters = {
                          'minPrice': null,
                          'maxPrice': null,
                          'condition': 'All',
                          'itemType': 'All',
                          'category': 'All',
                          'selectedDepartments': [],
                        };
                        minPriceController.clear();
                        maxPriceController.clear();
                        errorMessage = ''; // Clear error when filters are cleared

                        // Reset selected departments to none (unselect everything)
                        selectedDepartments = [];
                      });
                    },
                    child: Text(
                      'Clear Filters',
                      style: TextStyle(color: Color.fromARGB(255, 59, 137, 62)),
                    ),
                  ),
                  SizedBox(width: 16),
                   TextButton(
                    onPressed: () {
                      // Check if min price or max price is negative
                      if ((_filters['minPrice'] != null && _filters['minPrice'] < 0) ||
                          (_filters['maxPrice'] != null && _filters['maxPrice'] < 0)) {
                        setDialogState(() {
                          errorMessage = 'Price values cannot be negative!';
                        });
                      } 
                      // Check if min price is greater than max price
                      else if (_filters['minPrice'] != null &&
                          _filters['maxPrice'] != null &&
                          _filters['minPrice'] > _filters['maxPrice']) {
                        setDialogState(() {
                          errorMessage =
                              'Min price value cannot be smaller than the max price value!';
                        });
                      } else {
                        setState(() {}); // Apply filters globally
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      'Apply Filters',
                      style: TextStyle(color: Color.fromARGB(255, 59, 137, 62)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}
}