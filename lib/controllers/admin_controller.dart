import 'package:bees/models/item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bees/models/request_model.dart';

class AdminController {
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
}