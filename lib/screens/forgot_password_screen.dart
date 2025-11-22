import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailCtrl = TextEditingController();

  bool _busy = false;

  bool _isArabic = true;

  String _tr(String ar, String en) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();

    final sys = WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    _isArabic = (sys == 'ar');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();

    super.dispose();
  }

  void _snack(String ar, String en) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_tr(ar, en))),
    );
  }

  Future<void> _sendResetEmail() async {
    if (_busy) return;

    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _snack('رجاءً أدخلي البريد الإلكتروني', 'Please enter your email');

      return;
    }

    if (!email.contains('@')) {
      _snack('البريد الإلكتروني غير صحيح', 'Invalid email address');

      return;
    }

    setState(() => _busy = true);

    FocusScope.of(context).unfocus();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      _snack(
        'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني ✅',
        'Password reset link has been sent to your email ✅',
      );

      // نرجع لصفحة تسجيل الدخول بعد ثواني (اختياري)

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    } on FirebaseAuthException catch (e) {
      debugPrint('🔥 RESET ERROR: ${e.code} – ${e.message}');

      String ar = 'تعذّر إرسال الرابط، حاولي مرة أخرى.';

      String en = 'Could not send reset link, please try again.';

      switch (e.code) {
        case 'invalid-email':
          ar = 'صيغة البريد الإلكتروني غير صحيحة';

          en = 'Invalid email address format';

          break;

        case 'user-not-found':
          ar = 'لا يوجد مستخدم مسجّل بهذا البريد الإلكتروني';

          en = 'No user found for this email';

          break;
      }

      _snack(ar, en);
    } catch (e, s) {
      debugPrint('🔥 UNEXPECTED RESET ERROR: $e');

      debugPrint('STACK: $s');

      _snack(
        'حدث خطأ غير متوقَّع، حاولي مرة أخرى.',
        'Unexpected error, please try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            _tr('نسيت كلمة المرور', 'Forgot Password'),
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
            // الخلفية

            Image.asset(
              'assets/images/oman_background.jpg',
              fit: BoxFit.cover,
            ),

            Container(color: Colors.black.withOpacity(0.45)),

            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 120, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _tr('إعادة تعيين كلمة المرور 🔐', 'Reset your password 🔐'),
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _tr(
                      'أدخلي البريد الإلكتروني المسجّل وسنرسل لك رابط لإعادة تعيين كلمة المرور.',
                      'Enter your registered email and we will send you a reset link.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // حقل الإيميل

                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: _tr('البريد الإلكتروني', 'Email'),
                      prefixIcon: const Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _sendResetEmail,
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
                              _tr(
                                'إرسال رابط إعادة التعيين',
                                'Send reset link',
                              ),
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      _tr('الرجوع لتسجيل الدخول', 'Back to Sign In'),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                      ),
                    ),
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
