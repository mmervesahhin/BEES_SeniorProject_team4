import 'package:bees/models/item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bees/models/request_model.dart';

class AdminController {
  Future<List<Map<String, dynamic>>> fetchItemReports() async {
  try {
    // reported_items koleksiyonundaki raporları al
    QuerySnapshot<Map<String, dynamic>> reportsSnapshot =
        await FirebaseFirestore.instance.collection('reported_items').get();

    List<Map<String, dynamic>> reports = [];

    for (var doc in reportsSnapshot.docs) {
      Map<String, dynamic> reportData = doc.data();

      // Item ID'sini al
      String itemId = reportData['itemId'];

      // Items koleksiyonunda item'ı sorgula
      DocumentSnapshot<Map<String, dynamic>> itemDoc =
          await FirebaseFirestore.instance.collection('items').doc(itemId).get();

      // Eğer itemStatus "active" ise raporu ekle
      if (itemDoc.exists && itemDoc.data()?['itemStatus'] == 'active') {
        // Item sahibi kullanıcının hesabını kontrol et
        String? itemOwnerId = itemDoc.data()?['itemOwnerId'];
        if (itemOwnerId != null) {
          DocumentSnapshot<Map<String, dynamic>> ownerDoc =
              await FirebaseFirestore.instance.collection('users').doc(itemOwnerId).get();

          if (!ownerDoc.exists || ownerDoc.data()?['isBanned'] == true) {
            continue; // Eğer kullanıcı banlıysa bu raporu geç
          }
        }

        // Report eden kullanıcıyı al
        String? userId = reportData['reportedBy'];
        String reporterName = "Unknown User";

        if (userId != null) {
          DocumentSnapshot<Map<String, dynamic>> userDoc =
              await FirebaseFirestore.instance.collection('users').doc(userId).get();
          if (userDoc.exists) {
            var userData = userDoc.data();
            reporterName = "${userData?['firstName']} ${userData?['lastName']}";
          }
        }

        // Reporter'ı rapor verisine ekle
        reportData['reporterName'] = reporterName;
        reports.add(reportData);
      }
    }

    return reports;
  } catch (e) {
    print("Error fetching reports: $e");
    return [];
  }
}

Future<Map<String, dynamic>> getItemDetails(String itemId) async {
  try {
    // Firestore'dan itemId'ye göre item verilerini alıyoruz
    var itemSnapshot = await FirebaseFirestore.instance.collection('items').doc(itemId).get();
    
    if (itemSnapshot.exists) {
      return itemSnapshot.data()!;
    } else {
      return {}; // Eğer item bulunmazsa boş bir map döndür
    }
  } catch (e) {
    print("Error fetching item details: $e");
    return {}; // Hata durumunda boş bir map döndür
  }
}

  void showRequestRemoveOptions(BuildContext context, Request request) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.orange),
              title: const Text("Inappropriate for BEES"),
              onTap: () {
                Navigator.pop(context);
                _showRequestConfirmationDialog(context, request.requestID, "Inappropriate for BEES");
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel, color: Colors.red),
              title: const Text("Illegal request"),
              onTap: () {
                Navigator.pop(context);
                _showRequestConfirmationDialog(context, request.requestID, "Illegal request");
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: const Text("Cancel"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

void showItemRemoveOptions(BuildContext context, Item item, {VoidCallback? onSuccess}) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.report_problem, color: Colors.orange),
            title: const Text("Inappropriate for BEES"),
            onTap: () {
              Navigator.pop(context);
              _showItemConfirmationDialog(context, item.itemId ?? '', "Inappropriate for BEES", onSuccess: onSuccess);
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel, color: Colors.red),
            title: const Text("Illegal item"),
            onTap: () {
              Navigator.pop(context);
              _showItemConfirmationDialog(context, item.itemId ?? '', "Illegal item", onSuccess: onSuccess);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy, color: Color.fromARGB(255, 141, 113, 10)),
            title: const Text("Duplicate item"),
            onTap: () {
              Navigator.pop(context);
              _showItemConfirmationDialog(context, item.itemId ?? '', "Duplicate item", onSuccess: onSuccess);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.grey),
            title: const Text("Cancel"),
            onTap: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}


  void _showRequestConfirmationDialog(BuildContext context, String requestID, String reason) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Removal"),
          content: const Text(
              "Are you sure you want to remove this request from BEES? This action is permanent and cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Kullanıcı iptal etti
              child: const Text("No", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dialog'u kapat
                removeRequest(requestID, reason); // İşlemi başlat
              },
              child: const Text("Yes", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showItemConfirmationDialog(
  BuildContext context, 
  String itemId, 
  String reason, 
  {VoidCallback? onSuccess} // Opsiyonel callback eklendi
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Confirm Removal"),
        content: const Text(
            "Are you sure you want to remove this item from BEES? This action is permanent and cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Kullanıcı iptal etti
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Dialog'u kapat
              bool success = await removeItem(itemId, reason);
              if (success) {
                // Eğer bir callback varsa çalıştır, yoksa hiçbir şey yapma
                onSuccess?.call();
              }
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}


  Future<bool> removeRequest(String requestID, String reason) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      User? admin = FirebaseAuth.instance.currentUser;

      if (admin == null) {
        print("Admin user not found.");
        return false;
      }

      await firestore.collection('requests').doc(requestID).update({
        'requestStatus': 'removed',
      });

      await firestore.collection('removed_requests').add({
        'adminID': admin.uid,
        'requestID': requestID,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print("Error removing request: $e");
      return false;
    }
  }

  Future<bool> removeItem(String itemId, String reason) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      User? admin = FirebaseAuth.instance.currentUser;

      if (admin == null) {
        print("Admin user not found.");
        return false;
      }

      await firestore.collection('items').doc(itemId).update({
        'itemStatus': 'removed',
      });

      await firestore.collection('removed_items').add({
        'adminID': admin.uid,
        'itemId': itemId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print("Error removing request: $e");
      return false;
    }
  }

  Stream<QuerySnapshot> getReportedUsers() {
    return FirebaseFirestore.instance
        .collection('reported_users') // Your collection name
        .where('isConsidered', isEqualTo: false) // Filter reports where isConsidered is false
        .snapshots();
  }

  Stream<QuerySnapshot> getBannedUsers() {
    return FirebaseFirestore.instance.collection('users').where('isBanned', isEqualTo: true).snapshots();
  }

  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc.data() as Map<String, dynamic>? : null;
  }

  Future<void> banUser({
  required String userId,
  required String banReason,
  required String explanation,
  required String banPeriod,
}) async {
  try {
    String adminId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_admin';
    String banOperationId = FirebaseFirestore.instance.collection('banned_users').doc().id;
    DateTime banDate = DateTime.now();
    DateTime? banEndDate;

    if (banPeriod != 'Permanent') {
      int days = int.tryParse(banPeriod.split(' ')[0]) ?? 0;
      banEndDate = banDate.add(Duration(days: days));
    }

    // Add user to banned_users collection
    await FirebaseFirestore.instance.collection('banned_users').doc(banOperationId).set({
      'banOperationId': banOperationId,
      'adminId': adminId,
      'userId': userId,
      'banReason': banReason,
      'explanation': explanation,
      'banDate': banDate,
      'banPeriod': banPeriod,
    });

    // Update user's ban status
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isBanned': true,
      'banEndDate': banEndDate,
    });

    // Update all reports where the reported user is the banned user
    QuerySnapshot reportedUsersSnapshot = await FirebaseFirestore.instance
        .collection('reported_users')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in reportedUsersSnapshot.docs) {
      await doc.reference.update({'isConsidered': true});
    }
  } catch (e) {
    print('Error banning user: $e');
    throw Exception('Failed to ban user');
  }
}

  Future<void> unbanUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isBanned': false,
      'banEndDate': null,
    });
  }

  Future<void> ignoreUserReport(String reportId) async {
    DocumentSnapshot reportedUserDoc = await FirebaseFirestore.instance
      .collection('reported_users')
      .doc(reportId)
      .get();

    if (reportedUserDoc.exists) {
      await reportedUserDoc.reference.update({'isConsidered': true});
    }
  }
}