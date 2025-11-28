import 'package:flutter/material.dart';

import '../core/prefs.dart';

class OmanSplashScreen extends StatefulWidget {
  const OmanSplashScreen({super.key});

  @override
  State<OmanSplashScreen> createState() => _OmanSplashScreenState();
}

class _OmanSplashScreenState extends State<OmanSplashScreen> {
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();

    _startAnimation();
  }

  void _startAnimation() async {
    // أول شي نعرض Plan your trip

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _showWelcome = true); // نغيّر النص
    }

    // بعدين ننتقل إلى صفحة welcome

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      await Prefs.setOnboardingDone(true); // نحفظ انه دخلها

      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // الخلفية (صورة الورد)

          Image.asset(
            'assets/images/rose_bg.jpg', // غيري المسار حسب صورتك

            fit: BoxFit.cover,
          ),

          // تدرج خفيف لتوضيح النص

          Container(
            color: Colors.black.withOpacity(0.3),
          ),

          // المحتوى

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الشعار

              Image.asset(
                'assets/images/logo.png', // الشعار

                width: 130,

                height: 130,
              ),

              const SizedBox(height: 25),

              // النص المتغير

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: Text(
                  _showWelcome ? 'Welcome to Oman' : 'Plan your trip',
                  key: ValueKey(_showWelcome),
                  style: const TextStyle(
                    fontSize: 28,

                    fontFamily: 'ElMessiri', // أو أي خط جميل عندك

                    color: Colors.white,

                    fontWeight: FontWeight.bold,

                    shadows: [
                      Shadow(
                        blurRadius: 5,
                        color: Colors.black54,
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
