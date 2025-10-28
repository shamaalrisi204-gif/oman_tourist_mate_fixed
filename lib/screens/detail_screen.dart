import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final String title;
  const DetailScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: Text(
          'Welcome to $title Page 🎉',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
