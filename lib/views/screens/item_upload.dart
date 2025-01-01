import 'package:flutter/material.dart';
import '/views/screens/item_upload_success.dart';

void main() {
  runApp(const UploadItemApp());
}

class UploadItemApp extends StatelessWidget {
  const UploadItemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upload Item',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.green,
      ),
      home: const UploadItemPage(),
    );
  }
}

class UploadItemPage extends StatefulWidget {
  const UploadItemPage({super.key});

  @override
  State<UploadItemPage> createState() => _UploadItemPageState();
}

class _UploadItemPageState extends State<UploadItemPage> {
  // Variables for dropdowns
  String category = 'Sale';
  String itemType = 'Other';
  String department = 'All Departments';
  String condition = 'New';

  // Controllers for text fields
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  // Placeholder for uploaded image
  Widget uploadImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.green[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.add_a_photo, size: 40, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Item'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Upload Section
              Row(
                children: [
                  uploadImagePlaceholder(),
                  const SizedBox(width: 16),
                  uploadImagePlaceholder(),
                ],
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              const Text('Category'),
              DropdownButton<String>(
                value: category,
                isExpanded: true,
                items: ['Sale', 'Rent', 'Gift']
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    category = newValue!;
                  });
                },
              ),
              const SizedBox(height: 10),

              // Title TextField
              const Text('Title'),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter title',
                ),
              ),
              const SizedBox(height: 10),

              // Description
              const Text('Description'),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter description',
                ),
              ),
              const SizedBox(height: 10),

              // Dropdowns: Item Type & Department
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Item Type'),
                        DropdownButton<String>(
                          value: itemType,
                          isExpanded: true,
                          items: ['Other', 'Electronics','Stationary']
                              .map((value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ))
                              .toList(),
                          onChanged: (newValue) {
                            setState(() {
                              itemType = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Department'),
                        DropdownButton<String>(
                          value: department,
                          isExpanded: true,
                          items: ['All Departments', 'CTIS', 'CS', 'COMD', 'CHEM','MBG','PHYS','ARCH','IAED','IR','POLS','PSYC', 'ME','MAN','IE','EEE','AMER','ELIT','GRA','PHIL','THM','MUS','FA','TRIN','PREP']
                              .map((value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ))
                              .toList(),
                          onChanged: (newValue) {
                            setState(() {
                              department = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Condition Dropdown
              const Text('Condition'),
              DropdownButton<String>(
                value: condition,
                isExpanded: true,
                items: ['New', 'Used', 'Refurbished']
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    condition = newValue!;
                  });
                },
              ),
              const SizedBox(height: 10),

              // Price Field
              const Text('Price (₺ per hour)'),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixText: '₺ ',
                ),
              ),
              const SizedBox(height: 20),

              // Upload Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: () {
                  // Upload işlemi tamamlandığında yönlendirme
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UploadSuccessPage()),
                  );
                },
                  child: const Text('Upload Item', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}