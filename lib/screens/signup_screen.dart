// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import '../services/otp_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController first = TextEditingController();
  final TextEditingController last = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController pass = TextEditingController();
  final TextEditingController pass2 = TextEditingController();
  bool busy = false;
  bool showPass = false;
  bool showPass2 = false;
  @override
  void dispose() {
    first.dispose();
    last.dispose();
    email.dispose();
    phone.dispose();
    pass.dispose();
    pass2.dispose();
    super.dispose();
  }

  bool _okEmail(String v) => v.contains('@') && v.contains('.');
  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  Future<void> _send() async {
    final e = email.text.trim();
    final p = pass.text;
    final p2 = pass2.text;
    if (!_okEmail(e)) return _snack('البريد الإلكتروني غير صالح');
    if (p.length < 6) return _snack('كلمة المرور 6 أحرف على الأقل');
    if (p != p2) return _snack('تأكيد كلمة المرور غير مطابق');
    setState(() => busy = true);
    try {
      // ✅ إرسال الكود عبر OtpService
      final sent = await OtpService.I.sendVerificationCode(e);
      if (!mounted) return;
      if (sent) {
        _snack('تم إرسال كود التحقق إلى بريدك ✉️');
        Navigator.pushNamed(
          context,
          '/verify_otp',
          arguments: {
            'email': e,
            'firstName': first.text.trim(),
            'lastName': last.text.trim(),
            'phone': phone.text.trim(),
            'password': p,
          },
        );
      } else {
        _snack('تعذر إرسال الكود، جرّبي لاحقاً');
      }
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إنشاء حساب جديد'), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: first,
                decoration: const InputDecoration(labelText: 'الاسم الأول'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: last,
                decoration: const InputDecoration(labelText: 'الاسم الأخير'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    suffixIcon: Icon(Icons.public),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'رقم الهاتف (اختياري)'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pass,
                obscureText: !showPass,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => showPass = !showPass),
                    icon: Icon(
                        showPass ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pass2,
                obscureText: !showPass2,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => showPass2 = !showPass2),
                    icon: Icon(
                        showPass2 ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: busy ? null : _send,
                icon: busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(busy ? 'جارٍ الإرسال...' : 'إرسال كود التحقق'),
                style:
                    ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
