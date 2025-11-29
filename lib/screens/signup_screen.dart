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

  bool _usernameEditedByUser = false;

  bool _uLenOK = false;
  bool _uCaseOK = false;
  bool _uCharsOK = false;

  bool _pLenOK = false;
  bool _pUpperOK = false;
  bool _pLowerOK = false;
  bool _pDigitOK = false;
  bool _pSymbolOK = false;

  String _tr(String ar, String en) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    final sys = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _isArabic = (sys == 'ar');

    first.addListener(_onNameChanged);
    last.addListener(_onNameChanged);
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

  void _onNameChanged() {
    if (_usernameEditedByUser) {
      return;
    }
    final suggestion = _buildUsernameSuggestion(first.text, last.text);

    if (suggestion.isEmpty) return;

    username.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );

    _updateUsernameValidation(suggestion);
  }

  String _buildUsernameSuggestion(String f, String l) {
    f = f.trim();
    l = l.trim();

    if (f.isEmpty && l.isEmpty) return '';

    f = f.toLowerCase();
    l = l.toLowerCase();

    if (f.isEmpty) return l;
    if (l.isEmpty) return f;

    final base = '${f}_${l}';
    final suffixNumber = DateTime.now().millisecond % 100; // 0–99
    return '$base#${suffixNumber.toString().padLeft(2, '0')}';
  }

  void _updateUsernameValidation([String? value]) {
    final u = (value ?? username.text).trim();

    setState(() {
      _uLenOK = u.length >= 4 && u.length <= 20;
      final hasLower = RegExp(r'[a-z]').hasMatch(u);
      final hasUpper = RegExp(r'[A-Z]').hasMatch(u);
      _uCaseOK = hasLower && hasUpper;
      _uCharsOK = RegExp(r'^[A-Za-z0-9_.#~]*$').hasMatch(u) && u.isNotEmpty;
    });
  }

  bool _isValidUsername(String uname) {
    _updateUsernameValidation(uname);
    return _uLenOK && _uCaseOK && _uCharsOK;
  }

  void _updatePasswordValidation([String? value]) {
    final p = (value ?? pass.text);

    setState(() {
      _pLenOK = p.length >= 8;
      _pUpperOK = RegExp(r'[A-Z]').hasMatch(p);
      _pLowerOK = RegExp(r'[a-z]').hasMatch(p);
      _pDigitOK = RegExp(r'\d').hasMatch(p);
      _pSymbolOK = RegExp(r'[^\w\s]').hasMatch(p);
    });
  }

  bool _isValidPassword(String p) {
    _updatePasswordValidation(p);
    return _pLenOK && _pUpperOK && _pLowerOK && _pDigitOK && _pSymbolOK;
  }

  Future<bool> _emailAlreadyUsed(String email) async {
    final methods =
        await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    return methods.isNotEmpty;
  }

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

    if (!_isValidUsername(uname)) {
      return _snack(
        'اسم المستخدم لا يطابق كل الشروط.\n'
            'راجعي القائمة تحت خانة اسم المستخدم.',
        'Username does not satisfy all rules.\nPlease check the rules below the username field.',
      );
    }

    if (!_okEmail(e)) {
      return _snack(
        'البريد الإلكتروني غير صالح',
        'Invalid email address',
      );
    }

    if (!_isValidPassword(p)) {
      return _snack(
        'كلمة المرور لا تطابق كل الشروط.\n'
            'راجعي القائمة تحت خانة كلمة المرور.',
        'Password does not satisfy all rules.\nPlease check the rules below the password field.',
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
      if (await _emailAlreadyUsed(e)) {
        _snack(
          'هذا البريد مستخدم من قبل، جرّبي بريدًا آخر',
          'This email is already registered, please use another one',
        );
        setState(() => busy = false);
        return;
      }

      if (await _usernameAlreadyUsed(uname)) {
        _snack(
          'اسم المستخدم مسجّل من قبل، اختاري اسمًا آخر',
          'This username is already taken, choose another one',
        );
        setState(() => busy = false);
        return;
      }

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
            'username': uname,
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

  Widget _ruleItem(bool ok, String ar, String en) {
    final textColor = ok ? Colors.green : Colors.grey;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: textColor,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            _tr(ar, en),
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontFamily: 'Tajawal',
              fontWeight: ok ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
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
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _tr('إنشاء حساب جديد', 'Create a new account'),
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                        TextField(
                          controller: username,
                          decoration: InputDecoration(
                            labelText: _tr('اسم المستخدم', 'Username'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (v) {
                            _usernameEditedByUser = v.isNotEmpty;
                            _updateUsernameValidation(v);
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 6),
                        _ruleItem(
                          _uLenOK,
                          '٤–٢٠ حرفًا',
                          '4–20 characters',
                        ),
                        _ruleItem(
                          _uCaseOK,
                          'يحتوي حروف إنجليزية كبيرة وصغيرة',
                          'Contains uppercase & lowercase letters',
                        ),
                        _ruleItem(
                          _uCharsOK,
                          'أحرف إنجليزية / أرقام / الرموز:  _  .  #  ~',
                          'Letters / numbers / symbols:  _  .  #  ~',
                        ),
                        const SizedBox(height: 12),
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
                          onChanged: _updatePasswordValidation,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 6),
                        _ruleItem(
                          _pLenOK,
                          '٨ أحرف على الأقل',
                          'At least 8 characters',
                        ),
                        _ruleItem(
                          _pUpperOK,
                          'يحتوي حرفًا إنجليزيًا كبيرًا (A-Z)',
                          'Contains an uppercase letter (A-Z)',
                        ),
                        _ruleItem(
                          _pLowerOK,
                          'يحتوي حرفًا إنجليزيًا صغيرًا (a-z)',
                          'Contains a lowercase letter (a-z)',
                        ),
                        _ruleItem(
                          _pDigitOK,
                          'يحتوي رقمًا واحدًا على الأقل',
                          'Contains at least one digit',
                        ),
                        _ruleItem(
                          _pSymbolOK,
                          'يحتوي رمزًا واحدًا مثل (! @ # \$ % ^ & *)',
                          'Contains at least one symbol (e.g. ! @ # \$ % ^ & *)',
                        ),
                        const SizedBox(height: 12),
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
                        ElevatedButton.icon(
                          onPressed: busy ? null : _send,
                          icon: busy
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
