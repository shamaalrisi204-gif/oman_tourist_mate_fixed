import 'package:flutter/material.dart';

class YourTripScreen extends StatelessWidget {
  const YourTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'رحلتي / My Trip',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'هنا بتظهر خطة الرحلة اللي تم إنشاؤها ✨',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
    );
  }
}
