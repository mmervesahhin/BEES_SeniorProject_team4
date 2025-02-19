import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:bees/controllers/detailed_item_controller.dart';
import 'package:bees/controllers/home_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';

class DetailedItemScreen extends StatefulWidget {
  final String itemId;

  const DetailedItemScreen({Key? key, required this.itemId}) : super(key: key);

  @override
  _DetailedItemScreenState createState() => _DetailedItemScreenState();
}

class _DetailedItemScreenState extends State<DetailedItemScreen> {
  final DetailedItemController _controller = DetailedItemController();
  final HomeController _homeController = HomeController();

  Map<String, dynamic>? itemDetails;
  bool isLoading = true;
  bool isFavorited = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchFavoriteStatus();
  }

  Future<void> _fetchData() async {
    Map<String, dynamic>? details = await _controller.fetchItemDetails(widget.itemId);
    setState(() {
      itemDetails = details;
      isLoading = false;
    });
  }

  Future<void> _fetchFavoriteStatus() async {
    bool status = await _homeController.fetchFavoriteStatus(widget.itemId);
    setState(() {
      isFavorited = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Item Details", style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 59, 137, 62),
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
                                      isFavorited = !isFavorited;
                                    });
                                    _homeController.updateFavoriteCount(widget.itemId, isFavorited);
                                  },
                                ),
                              ),
                            ),
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
                        // Departments kısmı burada
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => UserProfileScreen()),
                                );
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
                                  Text(itemDetails!["ownerFullName"], style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(width: 10),
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(Icons.message, color: Color.fromARGB(255, 59, 137, 62), size: 30),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: Text("Report Item", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color.fromARGB(255, 59, 137, 62),
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
      ),
    );
  }
}
