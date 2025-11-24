import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool isArabic = true;

  // ⭐ ألوان

  static const Color kPrimaryBeige = Color(0xFFB68B5E);

  static const Color kNeonCyan = Color(0xFF00F6FF); // لون اكتشف

  @override
  Widget build(BuildContext context) {
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
                onPressed: () => setState(() => isArabic = !isArabic),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.85),
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
            // 🔹 الخلفية الأصلية

            Image.asset(
              'assets/images/oman_background.jpg',
              fit: BoxFit.cover,
            ),

            // 🔹 طبقة سوداء شفافة فوق الصورة بالكامل

            Container(
              color: Colors.black.withOpacity(0.38), // ← هنا التعتيم الأسود
            ),

            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: Column(
                  children: [
                    const Spacer(),

                    // ⭐ العنوان (أبيض واضح)

                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 34,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ⭐ جملة 1 (أبيض)

                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white, // ← أبيض

                        fontSize: 18,

                        height: 1.5,

                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ⭐ "اكتشف" ← يبقى فسفوري

                    Text(
                      slogan,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kNeonCyan, // ← بدون تغيير

                        fontSize: 20,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ⭐ جملة 3 (أبيض)

                    Text(
                      tourismDesc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white, // ← أبيض

                        fontSize: 17,

                        height: 1.4,

                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ⭐ زر تسجيل الدخول

                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBeige,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        signIn,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ⭐ زر إنشاء حساب

                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        signUp,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ⭐ زائر أسود

                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/guest'),
                      child: const Text(
                        'المتابعة كزائر',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
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
