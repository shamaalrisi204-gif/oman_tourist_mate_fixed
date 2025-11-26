// lib/core/prefs.dart

import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  // مفاتيح داخل SharedPreferences

  static const _kOnboardingDone = 'onboarding_done';

  static const _kUserLat = 'user_lat';

  static const _kUserLng = 'user_lng';

  static const _kUserCity = 'user_city';

  static const _kUserInterests = 'user_interests';

  static const _kLoggedIn = 'logged_in';

  static const _kLanguage = 'language'; // 'ar' أو 'en'

  static const _kDarkMode = 'dark_mode'; // true/false

  static const _kUserName = 'username'; // 👈 لعرضه في الصفحة الرئيسية

  /// حالة تسجيل الدخول

  static Future<void> setLoggedIn(bool v) async {
    final sp = await SharedPreferences.getInstance();

    await sp.setBool(_kLoggedIn, v);
  }

  static Future<bool> isLoggedIn() async {
    final sp = await SharedPreferences.getInstance();

    return sp.getBool(_kLoggedIn) ?? false;
  }

  /// Onboarding

  static Future<void> setOnboardingDone(bool done) async {
    final sp = await SharedPreferences.getInstance();

    await sp.setBool(_kOnboardingDone, done);
  }

  static Future<bool> getOnboardingDone() async {
    final sp = await SharedPreferences.getInstance();

    return sp.getBool(_kOnboardingDone) ?? false;
  }

  /// حفظ اسم المستخدم لعرضه في الصفحة الرئيسية

  static Future<void> setUserName(String name) async {
    final sp = await SharedPreferences.getInstance();

    await sp.setString(_kUserName, name);
  }

  static Future<String> getUserName() async {
    final sp = await SharedPreferences.getInstance();

    return sp.getString(_kUserName) ?? '';
  }

  /// الموقع

  static Future<void> saveHome({
    required double lat,
    required double lng,
    required String city,
  }) async {
    final sp = await SharedPreferences.getInstance();

    await sp.setDouble(_kUserLat, lat);

    await sp.setDouble(_kUserLng, lng);

    await sp.setString(_kUserCity, city);
  }

  static Future<({double? lat, double? lng, String? city})> loadHome() async {
    final sp = await SharedPreferences.getInstance();

    return (
      lat: sp.getDouble(_kUserLat),
      lng: sp.getDouble(_kUserLng),
      city: sp.getString(_kUserCity)
    );
  }

  /// الاهتمامات

  static Future<void> saveInterests(List<String> interests) async {
    final sp = await SharedPreferences.getInstance();

    await sp.setStringList(_kUserInterests, interests);
  }

  static Future<List<String>> getInterests() async {
    final sp = await SharedPreferences.getInstance();

    return sp.getStringList(_kUserInterests) ?? <String>[];
  }

  /// اللغة

  static Future<void> setLanguage(String code) async {
    final sp = await SharedPreferences.getInstance();

    await sp.setString(_kLanguage, code); // 'ar' أو 'en'
  }

  static Future<String> getLanguage() async {
    final sp = await SharedPreferences.getInstance();

    return sp.getString(_kLanguage) ?? 'ar';
  }

  static Future<bool> get isArabic async => (await getLanguage()) == 'ar';

  /// الوضع الليلي

  static Future<void> setDarkMode(bool v) async {
    final sp = await SharedPreferences.getInstance();

    await sp.setBool(_kDarkMode, v);
  }

  static Future<bool> getDarkMode() async {
    final sp = await SharedPreferences.getInstance();

    return sp.getBool(_kDarkMode) ?? false;
  }

  /// وصول خام (لو احتجتي)

  static Future<SharedPreferences> get raw => SharedPreferences.getInstance();
}
