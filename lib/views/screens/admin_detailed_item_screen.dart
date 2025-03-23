import 'package:bees/models/item_model.dart';
import 'package:bees/models/user_model.dart' show User;
import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_others_user_profile_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:bees/views/screens/message_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bees/controllers/detailed_item_controller.dart';
import 'package:bees/controllers/admin_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';

class AdminDetailedItemScreen extends StatefulWidget {
  final String itemId;

  const AdminDetailedItemScreen({Key? key, required this.itemId}) : super(key: key);

  @override
  _AdminDetailedItemScreenState createState() => _AdminDetailedItemScreenState();
}

class _AdminDetailedItemScreenState extends State<AdminDetailedItemScreen> {
  String? selectedReportReason = "Inappropriate for BEES"; // Başlangıçta bir değer
  TextEditingController complaintController = TextEditingController();

  final DetailedItemController _controller = DetailedItemController();
  final AdminController _controller1 = AdminController();

  Map<String, dynamic>? itemDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    Map<String, dynamic>? details = await _controller.fetchItemDetails(widget.itemId);
    setState(() {
      itemDetails = details;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Item Details", style: TextStyle(color: Colors.black)),
        backgroundColor: Color.fromARGB(255, 59, 137, 62),
        actions: [
          IconButton(
        icon: Icon(Icons.more_vert, color: Colors.black),
        onPressed: () async {
         _controller1.showItemRemoveOptions(context, Item.fromJson(itemDetails!, widget.itemId), onSuccess: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminHomeScreen()),
          );
        });
      },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : itemDetails == null
              ? Center(child: Text("Item not found"))
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            if (itemDetails!["additionalPhotos"] != null && (itemDetails!["additionalPhotos"] as List).isNotEmpty)
                              CarouselSlider(
                                options: CarouselOptions(height: 250.0, autoPlay: true),
                                items: [
                                  itemDetails!["photo"],
                                  ...?itemDetails!["additionalPhotos"]
                                ].map((photo) {
                                  return Builder(
                                    builder: (context) {
                                      return Container(
                                        width: MediaQuery.of(context).size.width,
                                        margin: EdgeInsets.symmetric(horizontal: 5.0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          image: DecorationImage(
                                            image: NetworkImage(photo),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              )
                            else if (itemDetails!["photo"] != null)
                              Image.network(itemDetails!["photo"], height: 250, width: double.infinity, fit: BoxFit.cover),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(itemDetails!["title"], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        if (itemDetails!["price"] != 0) ...[ 
                          Row(
                            children: [
                              Text(
                                '₺${itemDetails!["price"]}',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              if (itemDetails!["paymentPlan"] != null) ...[ 
                                SizedBox(width: 10),
                                Text(
                                  itemDetails!["paymentPlan"],
                                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 10),
                        ],
                        Text(itemDetails!["description"] ?? "No description available"),
                        SizedBox(height: 10),
                        if (itemDetails!["departments"] != null && (itemDetails!["departments"] as List).isNotEmpty)
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: List.generate(itemDetails!["departments"].length, (index) {
                              return Chip(label: Text(itemDetails!["departments"][index]));
                            }),
                          ),
                        Row(
                          children: [
                            Chip(label: Text(itemDetails!["category"])),
                            SizedBox(width: 8),
                            Chip(label: Text(itemDetails!["condition"])),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (itemDetails!["itemOwnerId"] != null) {
                                  // Kullanıcı ID'si ve item sahibi ID'si eşit mi kontrol et
                                  if (itemDetails!["itemOwnerId"] == FirebaseAuth.instance.currentUser!.uid) {
                                    // Eğer eşitse, kendi profil sayfasına yönlendir
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminProfileScreen(), // Kendi profil sayfası
                                      ),
                                    );
                                  } else {
                                    // Eğer eşit değilse, başkasının profil sayfasına yönlendir
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminOthersUserProfileScreen(userId: itemDetails!["itemOwnerId"]),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: itemDetails!["ownerProfilePicture"] != null &&
                                            itemDetails!["ownerProfilePicture"].isNotEmpty
                                        ? NetworkImage(itemDetails!["ownerProfilePicture"])
                                        : null,
                                    radius: 20,
                                    child: itemDetails!["ownerProfilePicture"] == null ||
                                            itemDetails!["ownerProfilePicture"].isEmpty
                                        ? Icon(Icons.person)
                                        : null,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    itemDetails!["ownerFullName"] != null && itemDetails!["ownerFullName"].isNotEmpty
                                        ? itemDetails!["ownerFullName"]
                                        : "No Name", // Varsayılan bir değer eklenebilir
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 10),
                                  // IconButton(
                                  //   onPressed: () {
                                  //     _navigateToMessageScreen(item, "Item");
                                  //   },
                                  //   icon: Icon(Icons.message, color: Color.fromARGB(255, 59, 137, 62), size: 30),
                                  //   ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 59, 137, 62),
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.shop), label: 'Items'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Complaints'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analysis'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AdminHomeScreen()),
        );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AdminRequestsScreen()),
        );
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AdminReportsScreen()),
        );
        break;
      case 3:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => AdminDataAnalysisScreen(),
        ));
        break;
      case 4:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => AdminProfileScreen(),
        ));
        break;
    }
  }
}
