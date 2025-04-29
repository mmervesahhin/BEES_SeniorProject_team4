import 'package:bees/models/item_model.dart';
import 'package:bees/views/screens/edit_item_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';

class DetailedItemController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> fetchItemDetails(String itemId) async {
    try {
      // Item bilgilerini Firestore'dan çek
      DocumentSnapshot<Map<String, dynamic>> itemSnapshot =
          await _firestore.collection('items').doc(itemId).get();

      if (!itemSnapshot.exists) {
        return null; // Eğer item yoksa null döndür
      }

      Map<String, dynamic> itemData = itemSnapshot.data()!;

      // Price, departments ve paymentPlan için kontrol ekleyelim
      itemData['price'] = itemData.containsKey('price') ? itemData['price'] : 0;
      itemData['departments'] =
          itemData.containsKey('departments') ? itemData['departments'] : [];
      itemData['paymentPlan'] =
          itemData.containsKey('paymentPlan') ? itemData['paymentPlan'] : null;

      // Item sahibinin bilgilerini çek
      String ownerId = itemData['itemOwnerId'];
      DocumentSnapshot<Map<String, dynamic>> ownerSnapshot =
          await _firestore.collection('users').doc(ownerId).get();

      if (ownerSnapshot.exists) {
        itemData['ownerFullName'] =
            "${ownerSnapshot.data()!['firstName']} ${ownerSnapshot.data()!['lastName']}";
        itemData['ownerProfilePicture'] =
            ownerSnapshot.data()!['profilePicture'];
      } else {
        itemData['ownerFullName'] = "Unknown Seller";
        itemData['ownerProfilePicture'] = "";
      }

      return itemData;
    } catch (e) {
      print("Error fetching item details: $e");
      return null;
    }
  }

  void navigateToEditItemScreen(BuildContext context, Item item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditItemScreen(item: item),
      ),
    );
  }
}
