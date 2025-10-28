import 'package:flutter/material.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us / تواصل معنا')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Email: support@omantouristmate.com"),
            const SizedBox(height: 8),
            const Text("Phone: +968 9000 0000"),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message sent (demo).')),
              ),
              icon: const Icon(Icons.send),
              label: const Text('Send Message (Demo)'),
            )
          ],
        ),
      ),
    );
  }
}
