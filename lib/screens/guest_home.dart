import 'package:flutter/material.dart';

class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guest Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('مرحباً بالضيف 👋', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/map'),
            icon: const Icon(Icons.map_outlined),
            label: const Text('خريطة عُمان'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/assistant'),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('المساعد السياحي'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            icon: const Icon(Icons.login),
            label: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
}
