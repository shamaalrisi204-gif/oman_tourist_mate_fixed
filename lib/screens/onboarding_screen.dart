import 'dart:async';

import 'package:flutter/material.dart';

import '../core/prefs.dart';

import 'welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool showPlan = false; // false = Welcome to Oman → true = Plan your trip

  @override
  void initState() {
    super.initState();

    // بعد 3 ثواني — يظهر النص الثاني

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showPlan = true;
        });
      }
    });

    // بعد 5 ثواني — يروح لصفحة Welcome

    Timer(const Duration(seconds: 5), () async {
      await Prefs.setOnboardingDone(true);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// 🌸 الخلفية

          Image.asset(
            'assets/images/rose_bg.jpg',
            fit: BoxFit.cover,
          ),

          /// تغميق خلفية بسيط

          Container(
            color: Colors.black.withOpacity(0.25),
          ),

          /// المحتوى بالنص

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// 🟨 الشعار

              Image.asset(
                'assets/images/logo2.png',
                width: 130,
                height: 130,
              ),

              const SizedBox(height: 30),

              /// ✨ النص المتغيّر

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 700),
                child: Text(
                  showPlan ? "Plan your trip" : "Welcome to Oman",
                  key: ValueKey(showPlan),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,

                    color: Colors.white,

                    fontFamily: 'AlexBrush', // ← اسم الخط الجديد

                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
