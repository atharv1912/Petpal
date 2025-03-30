import 'package:flutter/material.dart';

class AlertScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alert Screen'),
      ),
      body: Center(
        child: Text(
          'This is the Alert Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
