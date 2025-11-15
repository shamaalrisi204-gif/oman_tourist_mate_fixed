import 'package:flutter/material.dart';

class OmanSplashScreen extends StatefulWidget {
  const OmanSplashScreen({super.key});

  @override
  State<OmanSplashScreen> createState() => _OmanSplashScreenState();
}

class _OmanSplashScreenState extends State<OmanSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  late final Animation<double> _scale;

  late final Animation<double> _fadeLogo;

  late final Animation<double> _fadeTexts;

  @override
  void initState() {
    super.initState();

    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scale = Tween(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _ac, curve: Curves.easeOutBack),
    );

    _fadeLogo = CurvedAnimation(
      parent: _ac,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _fadeTexts = CurvedAnimation(
      parent: _ac,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();

    super.dispose();
  }

  void _goNext() {
    Navigator.of(context).pushReplacementNamed('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    const omaniGreen = Color(0xFF006C35);

    const omaniRed = Color(0xFFCF1020);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _goNext,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/omansplash.jpg',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black38,
                    Colors.black87,
                  ],
                ),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: _scale,
                child: FadeTransition(
                  opacity: _fadeLogo,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // كلمة Oman

                      const Text(
                        "Oman",
                        style: TextStyle(
                          fontFamily: "ElMessiri",
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // OTM

                      const Text(
                        "OTM",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 18),

                      FadeTransition(
                        opacity: _fadeTexts,
                        child: Column(
                          children: [
                            // عربي

                            const Text(
                              "مخطِّط رحلتك في عُمان",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "ElMessiri",
                                fontSize: 26,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // English

                            const Text(
                              "Plan your tourism in Oman",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "Montserrat",
                                fontSize: 16,
                                color: Colors.white70,
                                letterSpacing: 1.0,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // شريط ألوان (أحمر + أخضر)

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    width: 60, height: 4, color: omaniRed),
                                const SizedBox(width: 8),
                                Container(
                                    width: 60, height: 4, color: omaniGreen),
                              ],
                            ),

                            const SizedBox(height: 26),

                            // اضغط للمتابعة

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.touch_app_rounded,
                                    color: Colors.white70, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  "اضغط للمتابعة • Tap to continue",
                                  style: TextStyle(
                                    fontFamily: "Tajawal",
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
