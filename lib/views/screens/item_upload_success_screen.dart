import 'package:flutter/material.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/detailed_item_screen.dart'; // Import the detailed item screen

class UploadSuccessPage extends StatelessWidget {
  final String itemId; // Add itemId

  const UploadSuccessPage({Key? key, required this.itemId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Item'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: Container(), // Removes the back button
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'images/bee_pattern.jpg',
              repeat: ImageRepeat.repeat,
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.check, size: 80, color: Colors.black),
                      SizedBox(height: 10),
                      Text(
                        'Upload Successful!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                          (route) => false, // Clear navigation stack
                        );
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Go to Main Page'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        //print("Navigating to DetailedItemScreen with itemId: $itemId");
                        // Navigate to DetailedItemScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailedItemScreen(itemId: itemId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.remove_red_eye),
                      label: const Text('View the Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
