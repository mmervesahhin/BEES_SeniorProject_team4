import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bees/models/message_model.dart';  // Message model import
import 'message_screen.dart';  // MessageScreen import

class MessageListScreen extends StatelessWidget {
  final String userId;

  const MessageListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        backgroundColor: const Color.fromARGB(255, 59, 137, 62),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('senderId', isEqualTo: userId)  // Use the userId to fetch messages sent by the user
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No messages yet"));
          }

          final messages = snapshot.data!.docs.map((doc) {
            return Message.fromFirestore(doc);
          }).toList();

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return ListTile(
                title: Text(message.content),
                subtitle: Text("To: ${message.receiverId}"),
                trailing: Text(message.timestamp.toString()),
                onTap: () {
                  // Navigate to MessageScreen for detailed view of a specific message
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessageScreen(
                        entity: message,  // Send the message as the entity to MessageScreen
                        entityType: "Message",
                        senderId: message.senderId,
                        receiverId: message.receiverId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
