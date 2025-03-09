import 'package:flutter/material.dart';

class UserReportsScreen extends StatelessWidget {
  const UserReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Reports'),
      ),
      body: Center(
        child: Text('User Reports Screen'),
      ),
    );
  }
}