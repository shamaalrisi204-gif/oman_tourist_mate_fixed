// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  // Controllers
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController(); // اختياري (لن نخزّنه الآن)
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _creating = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  String? _emailValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'ادخلي البريد الإلكتروني';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
    if (!ok) return 'صيغة بريد غير صحيحة';
    return null;
  }

  Future<void> _onCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (_password.text != _confirm.text) {
      _snack('كلمتا المرور غير متطابقتين', color: Colors.red);
      return;
    }
    setState(() => _creating = true);
    try {
      // إنشاء المستخدم
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim().toLowerCase(),
        password: _password.text,
      );
      // تحديث الاسم الظاهر
      final displayName =
          '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim();
      await cred.user?.updateDisplayName(displayName);
      // (اختياري) ممكن تحفظي الهاتف في Firestore لاحقًا
      _snack('تم إنشاء الحساب 🎉', color: Colors.green);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'تعذر إنشاء الحساب';
      if (e.code == 'email-already-in-use') msg = 'البريد مستخدم من قبل';
      if (e.code == 'weak-password') msg = 'كلمة المرور ضعيفة';
      _snack('$msg: ${e.message}', color: Colors.red);
    } catch (e) {
      _snack('خطأ غير متوقع: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إنشاء حساب جديد')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _firstName,
                  decoration: InputDecoration(
                    labelText: 'الاسم الأول',
                    prefixIcon: const Icon(Icons.person),
                    border: inputBorder,
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'ادخلي الاسم' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastName,
                  decoration: InputDecoration(
                    labelText: 'الاسم الثاني',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: inputBorder,
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'ادخلي الاسم' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.email),
                    border: inputBorder,
                  ),
                  validator: _emailValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف (اختياري)',
                    prefixIcon: const Icon(Icons.phone),
                    border: inputBorder,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure1,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock),
                    border: inputBorder,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                      icon: Icon(
                          _obscure1 ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  validator: (v) {
                    final s = (v ?? '');
                    if (s.length < 6) return 'الحد الأدنى 6 أحرف';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: inputBorder,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                      icon: Icon(
                          _obscure2 ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _creating ? null : _onCreateAccount,
                    child: _creating
                        ? const CircularProgressIndicator()
                        : const Text('إنشاء حساب'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
