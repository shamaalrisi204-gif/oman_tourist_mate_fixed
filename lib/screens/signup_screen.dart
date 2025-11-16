// lib/screens/signup_screen.dart

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../services/otp_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController first = TextEditingController();

  final TextEditingController last = TextEditingController();

  final TextEditingController username = TextEditingController();

  final TextEditingController email = TextEditingController();

  final TextEditingController phone = TextEditingController();

  final TextEditingController pass = TextEditingController();

  final TextEditingController pass2 = TextEditingController();

  bool busy = false;

  bool showPass = false;

  bool showPass2 = false;

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
    first.dispose();

    last.dispose();

    username.dispose();

    email.dispose();

    phone.dispose();

    pass.dispose();

    pass2.dispose();

    super.dispose();
  }

  bool _okEmail(String v) => v.contains('@') && v.contains('.');

  void _snack(String ar, String en) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr(ar, en))),
      );

  /// ✅ التحقق من أن الإيميل غير مستخدم في FirebaseAuth

  Future<bool> _emailAlreadyUsed(String email) async {
    final methods =
        await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

    return methods.isNotEmpty;
  }

  /// ✅ التحقق من أن اليوزر نيم غير مكرر في Firestore

  Future<bool> _usernameAlreadyUsed(String uname) async {
    final u = uname.trim().toLowerCase();

    if (u.isEmpty) return false;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('usernameLower', isEqualTo: u)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  Future<void> _send() async {
    final e = email.text.trim();

    final p = pass.text;

    final p2 = pass2.text;

    final uname = username.text.trim();

    if (uname.isEmpty) {
      return _snack(
        'رجاءً أدخلي اسم المستخدم',
        'Please enter a username',
      );
    }

    if (!_okEmail(e)) {
      return _snack(
        'البريد الإلكتروني غير صالح',
        'Invalid email address',
      );
    }

    if (p.length < 6) {
      return _snack(
        'كلمة المرور 6 أحرف على الأقل',
        'Password must be at least 6 characters',
      );
    }

    if (p != p2) {
      return _snack(
        'تأكيد كلمة المرور غير مطابق',
        'Password confirmation does not match',
      );
    }

    setState(() => busy = true);

    try {
      // ✅ 1) تأكيد أن الإيميل غير مستخدم

      if (await _emailAlreadyUsed(e)) {
        _snack(
          'هذا البريد مستخدم من قبل، جرّبي بريد آخر',
          'This email is already registered, please use another one',
        );

        setState(() => busy = false);

        return;
      }

      // ✅ 2) تأكيد أن اليوزر نيم غير مكرر

      if (await _usernameAlreadyUsed(uname)) {
        _snack(
          'اسم المستخدم مسجّل من قبل، اختاري اسمًا آخر',
          'This username is already taken, choose another one',
        );

        setState(() => busy = false);

        return;
      }

      // ✅ 3) إرسال كود التحقق عبر OtpService

      final sent = await OtpService.I.sendVerificationCode(e);

      if (!mounted) return;

      if (sent) {
        _snack(
          'تم إرسال كود التحقق إلى بريدك ✉️',
          'Verification code has been sent to your email ✉️',
        );

        Navigator.pushNamed(
          context,
          '/verify_otp',
          arguments: {
            'email': e,

            'username': uname, // 👈 مهم

            'firstName': first.text.trim(),

            'lastName': last.text.trim(),

            'phone': phone.text.trim(),

            'password': p,
          },
        );
      } else {
        _snack(
          'تعذر إرسال الكود، جرّبي لاحقاً',
          'Could not send the code, please try again later',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => busy = false);
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
          title: Text(_tr('إنشاء حساب جديد', 'Create a new account')),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0, left: 8.0),
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
            Image.asset(
              'assets/images/oman_background.jpg',
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withOpacity(0.45)),
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _tr('أهلاً بك 👋', 'Welcome 👋'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _tr(
                            'أنشئ حسابك للبدء في استكشاف سلطنة عُمان ✨',
                            'Create your account to start exploring Oman ✨',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        const SizedBox(height: 20),

                        // الاسم الأول

                        TextField(
                          controller: first,
                          decoration: InputDecoration(
                            labelText: _tr('الاسم الأول', 'First name'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 12),

                        // الاسم الأخير

                        TextField(
                          controller: last,
                          decoration: InputDecoration(
                            labelText: _tr('الاسم الأخير', 'Last name'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 12),

                        // اسم المستخدم

                        TextField(
                          controller: username,
                          decoration: InputDecoration(
                            labelText: _tr('اسم المستخدم', 'Username'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 12),

                        // الإيميل (L→R)

                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: _tr('البريد الإلكتروني', 'Email'),
                              suffixIcon: const Icon(Icons.public),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // الهاتف

                        TextField(
                          controller: phone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: _tr(
                              'رقم الهاتف (اختياري)',
                              'Phone number (optional)',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 12),

                        // كلمة المرور

                        TextField(
                          controller: pass,
                          obscureText: !showPass,
                          decoration: InputDecoration(
                            labelText: _tr('كلمة المرور', 'Password'),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => showPass = !showPass),
                              icon: Icon(
                                showPass
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 12),

                        // تأكيد كلمة المرور

                        TextField(
                          controller: pass2,
                          obscureText: !showPass2,
                          decoration: InputDecoration(
                            labelText: _tr(
                              'تأكيد كلمة المرور',
                              'Confirm password',
                            ),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => showPass2 = !showPass2),
                              icon: Icon(
                                showPass2
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // زر إرسال كود التحقق

                        ElevatedButton.icon(
                          onPressed: busy ? null : _send,
                          icon: busy
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            busy
                                ? _tr('جارٍ الإرسال...', 'Sending...')
                                : _tr('إرسال كود التحقق',
                                    'Send verification code'),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
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
