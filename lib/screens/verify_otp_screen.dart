// lib/screens/verify_otp_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/prefs.dart';
import '../services/otp_service.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({
    super.key,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.password,
  });

  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String phone;
  final String password;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _verify() async {
    final code = _code.text.trim();

    if (code.length < 4) {
      _snack('أدخلي كود التحقق');
      return;
    }

    setState(() => _busy = true);

    try {
      final ok = await OtpService.I.verifyCode(widget.email, code);

      if (!mounted) return;

      if (!ok) {
        _snack('الكود غير صحيح');
        setState(() => _busy = false);
        return;
      }

      // إنشاء المستخدم في Firebase Auth
      UserCredential cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      final uid = cred.user!.uid;

      // حفظ بياناته في Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': widget.email,
        'username': widget.username,
        'usernameLower': widget.username.trim().toLowerCase(),
        'firstName': widget.firstName,
        'lastName': widget.lastName,
        'phone': widget.phone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ حفظ حالة الدخول و الـ onboarding
      await Prefs.setLoggedIn(true);
      await Prefs.setOnboardingDone(true);

      // ✅ أهم سطر: حفظ اسم المستخدم في SharedPreferences
      await Prefs.setUserName(widget.username);

      _snack('تم التحقق وإنشاء الحساب بنجاح ✅');

      // الانتقال إلى شاشة التفضيلات
      Navigator.pushReplacementNamed(context, '/preferences');
    } on FirebaseAuthException catch (e) {
      String msg = 'حدث خطأ أثناء إنشاء الحساب';

      if (e.code == 'email-already-in-use') {
        msg = 'هذا البريد مسجَّل من قبل، حاولي تسجيل الدخول بدلاً من ذلك';
      }

      _snack(msg);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدخال كود التحقق')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'أدخل الكود'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _busy ? null : _verify,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified),
                label: Text(_busy ? 'جارٍ التحقق...' : 'تحقق'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
