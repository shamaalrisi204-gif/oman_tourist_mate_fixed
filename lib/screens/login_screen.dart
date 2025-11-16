import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../core/prefs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();

  final _passwordCtrl = TextEditingController();

  bool _busy = false;

  bool _isArabic = true;

  bool _obscure = true;

  String _tr(String ar, String en) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();

    final sys = WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    _isArabic = (sys == 'ar');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();

    _passwordCtrl.dispose();

    super.dispose();
  }

  void _snack(String ar, String en) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_tr(ar, en))),
    );
  }

  /// 🔐 تسجيل الدخول بـ Username + Password

  Future<void> _doLogin() async {
    if (_busy) return;

    final uname = _usernameCtrl.text.trim();

    final pass = _passwordCtrl.text;

    if (uname.isEmpty) {
      _snack('رجاءً أدخلي اسم المستخدم', 'Please enter username');

      return;
    }

    if (pass.length < 6) {
      _snack(
        'كلمة المرور ٦ أحرف على الأقل',
        'Password must be at least 6 characters',
      );

      return;
    }

    setState(() => _busy = true);

    FocusScope.of(context).unfocus();

    try {
      // 1) نجيب الإيميل من Firestore حسب الـ usernameLower

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('usernameLower', isEqualTo: uname.toLowerCase())
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        _snack('اسم المستخدم غير موجود', 'Username not found');

        return;
      }

      final data = snap.docs.first.data();

      final email = (data['email'] ?? '') as String;

      if (email.isEmpty) {
        _snack(
          'حدث خطأ في بيانات الحساب، حاولي لاحقاً',
          'Profile data is invalid, please try later',
        );

        return;
      }

      // 2) تسجيل الدخول على FirebaseAuth

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      // 3) حفظ حالة الدخول

      await Prefs.setLoggedIn(true);

      await Prefs.setOnboardingDone(true);

      _snack('تم تسجيل الدخول بنجاح ✅', 'Logged in successfully ✅');

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/preferences');
    } on FirebaseAuthException catch (e) {
      String ar = 'فشل تسجيل الدخول';

      String en = 'Login failed';

      switch (e.code) {
        case 'wrong-password':
          ar = 'كلمة المرور غير صحيحة';

          en = 'Incorrect password';

          break;

        case 'user-disabled':
          ar = 'هذا الحساب غير مفعَّل';

          en = 'This account has been disabled';

          break;

        case 'too-many-requests':
          ar = 'محاولات كثيرة فاشلة، حاولي بعد قليل';

          en = 'Too many attempts, please try again later';

          break;

        case 'user-not-found':
          ar = 'لم يتم العثور على حساب بهذا الإيميل';

          en = 'No user found for this email';

          break;

        default:
          ar = 'تعذّر تسجيل الدخول، تحققي من البيانات';

          en = 'Could not sign in, please check your data';
      }

      _snack(ar, en);
    } on FirebaseException catch (e) {
      // 🔍 أخطاء Firestore نفسها (rules / network / ..)

      debugPrint('🔥 FIRESTORE LOGIN ERROR: ${e.code} – ${e.message}');

      if (e.code == 'permission-denied') {
        _snack(
          'لا يوجد إذن للوصول لبيانات المستخدم (تحققي من قواعد Firestore).',
          'Permission denied for reading user data (check Firestore rules).',
        );
      } else {
        _snack(
          'مشكلة في الاتصال بقاعدة البيانات: ${e.code}',
          'Error while reading user data: ${e.code}',
        );
      }
    } catch (e, s) {
      // أي خطأ عام آخر

      debugPrint('🔥 UNEXPECTED LOGIN ERROR: $e');

      debugPrint('STACK: $s');

      _snack(
        'حدث خطأ غير متوقَّع، حاولي مرة أخرى',
        'Unexpected error, please try again',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// الدخول كـ زائر

  Future<void> _continueAsGuest() async {
    await Prefs.setLoggedIn(true);

    await Prefs.setOnboardingDone(true);

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/preferences');
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isAr ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // ممكن ترجعي لصفحة الترحيب

                // Navigator.pushReplacementNamed(context, '/welcome');
              }
            },
          ),
          title: Text(
            _tr('تسجيل الدخول', 'Sign In'),
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8, left: 8, top: 4),
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isArabic = !_isArabic),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.85),
                  foregroundColor: Colors.black87,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.language, size: 18),
                label: Text(
                  isAr ? 'English' : 'العربية',
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // خلفية

            Image.asset(
              'assets/images/oman_background.jpg',
              fit: BoxFit.cover,
            ),

            Container(color: Colors.black.withOpacity(0.45)),

            // المحتوى

            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 120, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _tr('مرحباً بعودتك 👋', 'Welcome back 👋'),
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _tr(
                      'سجّل دخولك لمتابعة عالم السياحة العُمانية ✨',
                      'Sign in to continue your Oman trip ✨',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Username

                  TextField(
                    controller: _usernameCtrl,
                    decoration: InputDecoration(
                      labelText: _tr('اسم المستخدم', 'Username'),
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Password

                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: _tr('كلمة المرور', 'Password'),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // زر تسجيل الدخول

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _doLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _busy
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              _tr('تسجيل الدخول', 'Sign In'),
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // متابعة كزائر

                  TextButton(
                    onPressed: _continueAsGuest,
                    child: Text(
                      _tr('المتابعة كزائر', 'Continue as Guest'),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // رابط إنشاء حساب

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _tr('ليس لديك حساب؟', "Don't have an account?"),
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white70,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signup'),
                        child: Text(
                          _tr('إنشاء حساب جديد', 'Create Account'),
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }
}
