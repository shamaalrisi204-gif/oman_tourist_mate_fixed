import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us / من نحن')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            "Oman Tourist Mate helps travelers plan trips in Oman using AI, "
            "maps and personalized preferences.\n\n"
            "تطبيق Oman Tourist Mate يساعد المسافرين على تخطيط رحلاتهم في عُمان "
            "باستخدام الذكاء الاصطناعي والخرائط والتفضيلات الشخصية.\n\n"
            "Version: 1.0.0",
          ),
        ),
      ),
    );
  }
}
