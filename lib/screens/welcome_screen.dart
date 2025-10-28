import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool isArabic = true; // ✅ اللغة الافتراضية
  @override
  Widget build(BuildContext context) {
    // النصوص بالعربي والإنجليزي
    final title = isArabic ? 'خطط لرحلتك' : 'Plan Your Trip';
    final subtitle = isArabic
        ? 'أضف الوجهات إلى رحلتك بسهولة وسافر حيثما تريد'
        : 'Add destinations to your trip easily and travel wherever you like';
    final slogan = isArabic
        ? 'اكتشف عُمان بطريقة جديدة ✨'
        : 'Discover Oman in a new way ✨';
    final tourismDesc = isArabic
        ? 'من القلاع والأسواق التقليدية إلى الجبال والشواطئ الساحرة'
        : 'From historic forts and traditional souqs to majestic mountains and stunning beaches';
    final signIn = isArabic ? 'تسجيل الدخول' : 'Sign In';
    final signUp = isArabic ? 'إنشاء حساب جديد' : 'Create Account';
    final guest = isArabic ? 'المتابعة كزائر' : 'Continue as Guest';
    final langBtn = isArabic ? 'English' : 'العربية';
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isArabic = !isArabic;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Text("🌎"),
                label: Text(langBtn),
              ),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ✅ الخلفية
            Image.asset(
              'assets/images/oman_background.jpg', // تأكدي الاسم نفسه بالضبط
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withOpacity(0.35)),
            // ✅ المحتوى
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: Column(
                  children: [
                    const Spacer(),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 34,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      slogan,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tourismDesc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // ✅ الأزرار
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(signIn),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(signUp),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/guest'),
                      child: Text(
                        guest,
                        style: const TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
