 import 'package:flutter/material.dart';

class RequestReportsScreen extends StatelessWidget {
  const RequestReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Reports'),
      ),
      body: Center(
        child: Text('Request Reports Screen'),
      ),
    );
  }
}