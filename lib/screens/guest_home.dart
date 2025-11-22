// lib/screens/guest_home_screen.dart

import 'package:flutter/material.dart';

import 'user_home.dart'; // 👈 عشان نفتح الصفحة الرئيسية بمود ضيف

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  bool _isArabic = true;

  void _toggleLang() {
    setState(() => _isArabic = !_isArabic);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isArabic ? 'مرحباً بالضيف 👋' : 'Welcome, Guest 👋';

    final introTitle = _isArabic
        ? 'مرحباً بك في Oman Tourist Mate'
        : 'Welcome to Oman Tourist Mate';

    final introBody = _isArabic
        ? 'كضيف تقدر تشوف خريطة عُمان وبعض المعلومات العامة.\nإذا حاب تسوي خطة أو حفظ أماكن أو حجز لازم تنشئ حساب أولاً.'
        : 'As a guest you can view Oman map and general info.\nTo make plans or save places, you need an account.';

    final exploreTitle = _isArabic ? 'استكشف كضيف' : 'Explore as guest';

    final mapBtn = _isArabic
        ? 'ادخل كتجربة ضيف (عرض الخريطة والأماكن فقط)'
        : 'Enter as guest (view map & places only)';

    final accountTitle =
        _isArabic ? 'أنشئ حسابك واستفد من كل المزايا' : 'Create your account';

    final signupBtn = _isArabic
        ? 'Create account / إنشاء حساب جديد'
        : 'Create account / إنشاء حساب جديد';

    final langBtn = _isArabic ? 'English' : 'العربية';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // الخلفية

          Image.asset(
            'assets/images/oman_background.jpg',
            fit: BoxFit.cover,
          ),

          // طبقة شفافة

          Container(
            color: Colors.black.withOpacity(0.35),
          ),

          SafeArea(
            child: Stack(
              children: [
                // محتوى الصفحة

                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 50), // مساحة تحت زر الرجوع

                      // الترحيب

                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // بطاقة الترحيب

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              introTitle,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              introBody,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      Text(
                        exploreTitle,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // زر الدخول كضيف → يفتح UserHome بمود ضيف

                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UserHome(
                                isGuest: true, // 👈 مهم جداً
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map_outlined),
                        label: Text(
                          mapBtn,
                          style: const TextStyle(fontFamily: 'Tajawal'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      Text(
                        accountTitle,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // زر إنشاء حساب

                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signup'),
                        icon: const Icon(Icons.person_add_alt),
                        label: Text(
                          signupBtn,
                          style: const TextStyle(fontFamily: 'Tajawal'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // 🔙 زر الرجوع العلوي

                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),

                // 🌐 زر اللغة أعلى اليمين

                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: TextButton(
                        onPressed: _toggleLang,
                        child: Text(
                          langBtn,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
