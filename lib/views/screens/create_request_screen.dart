// create_request_screen.dart güncellenmiş versiyon
import 'package:flutter/material.dart';
//import 'package:uuid/uuid.dart';
import 'package:bees/models/request_model.dart';
import 'package:bees/controllers/request_controller.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  _CreateRequestScreenState createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final RequestController _requestController = RequestController();

 void _submitRequest() async {
  if (_formKey.currentState!.validate()) {
    final newRequest = Request(
      requestID: "", // Firestore’un ID’yi üretmesini sağlamak için boş bırakıyoruz
      requestOwnerID: "exampleUserID", 
      requestContent: _descriptionController.text,
      requestStatus: "Pending",
      creationDate: DateTime.now(),
    );

    await _requestController.createRequest(newRequest); // Controller ile isteği oluştur
    Navigator.pop(context);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Request"),
        backgroundColor: const Color.fromARGB(255, 59, 137, 62),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Request Description"),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Enter your request details",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter a description";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 59, 137, 62),
                ),
                child: const Text("Submit Request"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}