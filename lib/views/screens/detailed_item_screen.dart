import 'package:bees/controllers/reported_item_controller.dart';
import 'package:bees/models/reported_item_model.dart';
import 'package:bees/views/screens/favorites_screen.dart';
import 'package:bees/views/screens/message_screen.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/requests_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String? selectedReportReason = "Inappropriate for BEES"; // Başlangıçta bir değer
  TextEditingController complaintController = TextEditingController();

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
    print("Fetching details for itemId: ${widget.itemId}");

    Map<String, dynamic>? details = await _controller.fetchItemDetails(widget.itemId);

    if (details == null) {
      print("Item not found in Firestore!");
    } else {
      print("Fetched details: $details");
    }

    if (mounted) { // Ensure widget is still active
      setState(() {
        itemDetails = details;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchFavoriteStatus() async {
    bool status = await _homeController.fetchFavoriteStatus(widget.itemId);
    setState(() {
      isFavorited = status;
    });
  }

  // Report Dialog fonksiyonu
  Future<void> _showReportDialog(BuildContext context) async {
    String? dialogSelectedReason = selectedReportReason; // Dialog için geçici bir değişken

    final userId = 'userID'; // Firestore'dan almanız gereken gerçek kullanıcı ID'si
    final userIDD = FirebaseAuth.instance.currentUser?.uid ?? "defaultUserId"; 


    // Report işlemi öncesinde kontrol et
    bool hasReported = await ReportedItemController().hasUserReportedItem(widget.itemId, userIDD);

    if (hasReported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You have already reported this item.")),
      );
      return; // Kullanıcıya rapor işlemini yapma fırsatı vermiyoruz
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(
                "Report Item",
                style: TextStyle(color: Color.fromARGB(255, 17, 39, 18)), // Başlık için yeşil
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Please select a reason:",
                    style: TextStyle(color: Color.fromARGB(255, 29, 31, 29)), // Yazı rengi için yeşil
                  ),
                  RadioListTile<String>(
                    title: Text(
                      "Inappropriate for BEES",
                      style: TextStyle(color: Color.fromARGB(255, 18, 73, 20)), // Yazı rengi yeşil
                    ),
                    value: "Inappropriate for BEES",
                    groupValue: dialogSelectedReason,
                    onChanged: (value) {
                      setDialogState(() {
                        dialogSelectedReason = value;
                      });
                      print("Selected reason: $dialogSelectedReason");
                    },
                    activeColor: Color.fromARGB(255, 18, 73, 20), // Seçili olan radio buton halkası rengi
                  ),
                  RadioListTile<String>(
                    title: Text(
                      "Illegal item",
                      style: TextStyle(color: Color.fromARGB(255, 18, 73, 20)), // Yazı rengi yeşil
                    ),
                    value: "Illegal item",
                    groupValue: dialogSelectedReason,
                    onChanged: (value) {
                      setDialogState(() {
                        dialogSelectedReason = value;
                      });
                      print("Selected reason: $dialogSelectedReason");
                    },
                    activeColor: Color.fromARGB(255, 18, 73, 20), // Seçili olan radio buton halkası rengi
                  ),
                  RadioListTile<String>(
                    title: Text(
                      "Duplicate item",
                      style: TextStyle(color: Color.fromARGB(255, 18, 73, 20)), // Yazı rengi yeşil
                    ),
                    value: "Duplicate item",
                    groupValue: dialogSelectedReason,
                    onChanged: (value) {
                      setDialogState(() {
                        dialogSelectedReason = value;
                      });
                      print("Selected reason: $dialogSelectedReason");
                    },
                    activeColor: Color.fromARGB(255, 18, 73, 20), // Seçili olan radio buton halkası rengi
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Explain your report (optional):",
                    style: TextStyle(color: Color.fromARGB(255, 18, 73, 20)), // Yazı rengi yeşil
                  ),
                  TextField(
                    controller: complaintController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Enter your explanation here...",
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color.fromARGB(255, 18, 73, 20)), // Focused border rengi
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dialog'u kapatma
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Color.fromARGB(255, 18, 73, 20)), // Buton rengi yeşil
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    // Yeni seçilen değeri global'e aktaralım
                    setState(() {
                      selectedReportReason = dialogSelectedReason;
                    });

                    if (selectedReportReason != null) {
                      await _sendReport(
                        selectedReportReason!,
                        complaintController.text,
                        context,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please select a report reason")),
                      );
                    }
                    Navigator.of(context).pop(); // Dialog'u kapatma
                  },
                  child: Text(
                    "Send the Report",
                    style: TextStyle(color: Color.fromARGB(255, 18, 73, 20)), // Buton rengi yeşil
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Report işlemini Firestore'a kaydetme fonksiyonu
  Future<void> _sendReport(String reportReason, String complaintDetails, BuildContext context) async {
  ReportedItemController controller = ReportedItemController();
  final userIDD = FirebaseAuth.instance.currentUser?.uid ?? "defaultUserId"; 

  // Dinamik userId ve itemId'yi alıyoruz
  final itemId = widget.itemId; // Sayfadan veya widget'tan gelen item ID'si

  bool alreadyReported = await controller.checkIfAlreadyReported(userIDD, itemId);
  if (alreadyReported) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You have already reported this item.")),
    );
    return; // Aynı item için rapor yapılmaz
  }

  ReportedItem reportedItem = ReportedItem(
    complaintID: DateTime.now().millisecondsSinceEpoch, // Benzersiz bir ID oluşturuluyor
    complaintDetails: complaintDetails,
    reportReason: reportReason,
    reportedObjectType: "item", // Bu raporun bir item'a ait olduğunu belirtiyoruz
    reportedBy: userIDD, // Dinamik kullanıcı ID'si
    itemId: itemId, // Dinamik item ID'si
  );

  try {
    await controller.reportItem(reportedItem); // ReportItem'ı Firestore'a kaydediyoruz
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Item has been reported successfully!")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error reporting item: $e")),
    );
  }

  
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
                                    _homeController.updateFavoriteCount(widget.itemId, isFavorited, FirebaseAuth.instance.currentUser!.uid);
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
                                    onPressed: () {
                                      _navigateToMessageScreen(itemDetails, "Item");
                                    },
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
                            onPressed: () {
                              _showReportDialog(context); // Report butonuna basıldığında pop-up gösterilir
                            },
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
        selectedItemColor: const Color.fromARGB(255, 59, 137, 62),
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.shop), label: 'Items'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }
  
  void _navigateToMessageScreen(dynamic entity, String entityType) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => MessageScreen(entity: entity, entityType: entityType),
    ),
  );
}


  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => RequestsScreen()),
        );
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => FavoritesScreen()),
        );
        break;
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => UserProfileScreen()),
        );
        break;
    }
  }
}