import 'package:flutter/material.dart';
import '../core/prefs.dart';

/// شاشة تسجيل الدخول (عربية / إنجليزية) مع خلفية
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _isArabic = true; // ✅ اللغة الافتراضية
  Future<void> _doLogin() async {
    if (_busy) return;
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 600));
    await Prefs.setLoggedIn(true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/preferences');
    setState(() => _busy = false);
  }

  Future<void> _continueAsGuest() async {
    await Prefs.setLoggedIn(true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/preferences');
  }

  @override
  Widget build(BuildContext context) {
    // ✅ النصوص حسب اللغة
    final title = _isArabic ? 'تسجيل الدخول' : 'Sign In';
    final welcome = _isArabic ? 'مرحباً بعودتك 👋' : 'Welcome back 👋';
    final subtitle = _isArabic
        ? 'سجّل دخولك للمتابعة إلى عالم السياحة العُماني ✨'
        : 'Sign in to continue your Omani tourism journey ✨';
    final emailLabel = _isArabic ? 'البريد الإلكتروني' : 'Email';
    final passLabel = _isArabic ? 'كلمة المرور' : 'Password';
    final loginBtn = _isArabic ? 'تسجيل الدخول' : 'Sign In';
    final guestBtn = _isArabic ? 'المتابعة كزائر' : 'Continue as Guest';
    final noAccount = _isArabic ? 'ليس لديك حساب؟' : "Don't have an account?";
    final signupBtn = _isArabic ? 'إنشاء حساب جديد' : 'Create Account';
    final langBtn = _isArabic ? 'English' : 'العربية';
    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(title),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8),
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isArabic = !_isArabic),
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
              'assets/images/oman_background.jpg',
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withOpacity(0.45)),
            // ✅ المحتوى
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 120, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    welcome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // ✅ البريد الإلكتروني
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: emailLabel,
                      prefixIcon: const Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ✅ كلمة المرور
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: passLabel,
                      prefixIcon: const Icon(Icons.lock),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ✅ زر تسجيل الدخول
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
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(loginBtn),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ✅ زر متابعة كزائر
                  TextButton(
                    onPressed: _continueAsGuest,
                    child: Text(
                      guestBtn,
                      style: const TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ✅ رابط إنشاء حساب
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        noAccount,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signup'),
                        child: Text(
                          signupBtn,
                          style: const TextStyle(
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
