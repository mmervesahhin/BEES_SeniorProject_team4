import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bees/models/request_model.dart';

class AdminController {
  void showRemoveOptions(BuildContext context, Request request) {
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
                _showConfirmationDialog(context, request.requestID, "Inappropriate for BEES");
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel, color: Colors.red),
              title: const Text("Illegal request"),
              onTap: () {
                Navigator.pop(context);
                _showConfirmationDialog(context, request.requestID, "Illegal request");
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

  void _showConfirmationDialog(BuildContext context, String requestID, String reason) {
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
}
