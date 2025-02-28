import 'package:flutter/material.dart';
import 'package:bees/models/request_model.dart';


class MessageScreen extends StatelessWidget {
  final Request request;

  const MessageScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Message"),
        backgroundColor: const Color.fromARGB(255, 59, 137, 62),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Request from:",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                // Bağlantıya tıklandığında yapılacak işlem (örn. detay sayfasına gitme)
              },
              child: Text(
                request.requestContent,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: const Center(child: Text("Chat messages go here...")),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color.fromARGB(255, 59, 137, 62)),
                  onPressed: () {
                    // Mesaj gönderme işlemi buraya eklenecek
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
