// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'firebase_options.dart';
// حالة التطبيق + التفضيلات
import 'core/app_state.dart';
import 'core/prefs.dart';
// الشاشات
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/user_home.dart';
import 'screens/map_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/place_details_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/preference_screen.dart';
import 'screens/guest_home.dart';
import 'screens/about_us_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/verify_otp_screen.dart';
import 'screens/governorates_map_screen.dart'; // ✅ جديد (خريطة المحافظات)
import 'screens/governates_map_webview.dart';

// أثناء التطوير: ابدأ من شاشة الترحيب دائماً
const bool kForceWelcomeOnStart = true;
// فعّلي هذا فقط عند التجربة على المحلي (Emulator)
const bool kUseFunctionsEmulator = false;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ✅ تهيئة Firebase مرة واحدة فقط
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app();
    }
  } on FirebaseException catch (e) {
    // تجاهل خطأ duplicate-app
    if (e.code != 'duplicate-app') rethrow;
  }
  // ربط التطبيق بمحاكي Cloud Functions (اختياري للتطوير)
  if (kUseFunctionsEmulator) {
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    FirebaseFunctions.instanceFor(region: 'us-central1')
        .useFunctionsEmulator(host, 5002);
  }
  // أثناء التطوير: نرجّع المستخدم لشاشة الترحيب
  if (kForceWelcomeOnStart) {
    await Prefs.setLoggedIn(false);
    await Prefs.setOnboardingDone(false);
  }
  // تهيئة حالة التطبيق
  final appState = AppState();
  await appState.bootstrap();
  runApp(
    AppStateProvider(
      notifier: appState,
      child: const OmanTouristMateApp(),
    ),
  );
}

class OmanTouristMateApp extends StatelessWidget {
  const OmanTouristMateApp({super.key});
  // تحديد شاشة البداية
  Future<Widget> _decideStart() async {
    if (kForceWelcomeOnStart) return const WelcomeScreen();
    final loggedIn = await Prefs.isLoggedIn();
    final onboarded = await Prefs.getOnboardingDone();
    if (!loggedIn) return const WelcomeScreen();
    if (!onboarded) return const PreferencesScreen();
    return const UserHome();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppStateProvider.of(context);
    return AnimatedBuilder(
      animation: app,
      builder: (_, __) {
        return FutureBuilder<Widget>(
          future: _decideStart(),
          builder: (context, snap) {
            final start = snap.data;
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Oman Tourist Mate',
              // اللغة والثيم
              locale: app.locale,
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              themeMode: app.themeMode,
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                fontFamily: 'Tajawal',
              ),
              darkTheme: ThemeData.dark(useMaterial3: true),
              // شاشة البداية
              home: start ??
                  const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
              // ✅ الراوتات الثابتة
              routes: {
                '/welcome': (_) => const WelcomeScreen(),
                '/login': (_) => const LoginScreen(),
                '/signup': (_) => const SignUpScreen(),
                '/user': (_) => const UserHome(),
                '/map': (_) => const MapScreen(),
                '/gov_map': (_) => const GovernoratesMapScreen(), // ✅ جديد
                '/favorites': (_) => const FavoritesScreen(),
                '/ai_chat': (_) => const AiChatScreen(),
                '/preferences': (_) => const PreferencesScreen(),
                '/guest': (_) => const GuestHomeScreen(),
                '/about': (_) => const AboutUsScreen(),
                '/contact': (_) => const ContactUsScreen(),
                '/main': (_) => const MainMenuScreen(),
                '/user_home': (_) => const UserHome(),
                '/gov_map': (_) => const GovernoratesMapWebView(),
              },
              // ✅ الراوتات الديناميكية (مع بارامترات)
              onGenerateRoute: (settings) {
                // شاشة تفاصيل مكان
                if (settings.name == '/place_details') {
                  final args =
                      (settings.arguments ?? {}) as Map<String, dynamic>;
                  return MaterialPageRoute(
                    builder: (_) => PlaceDetailsScreen(
                      governorate: (args['gov'] ?? '') as String,
                      placeName: (args['name'] ?? '') as String,
                      lat: ((args['lat'] ?? 0) as num).toDouble(),
                      lng: ((args['lng'] ?? 0) as num).toDouble(),
                    ),
                  );
                }
                // شاشة التحقق OTP
                if (settings.name == '/verify_otp') {
                  final args =
                      (settings.arguments ?? {}) as Map<String, dynamic>;
                  return MaterialPageRoute(
                    builder: (_) => VerifyOtpScreen(
                      email: (args['email'] ?? '') as String,
                      firstName: (args['firstName'] ?? '') as String,
                      lastName: (args['lastName'] ?? '') as String,
                      phone: (args['phone'] ?? '') as String,
                      password: (args['password'] ?? '') as String,
                    ),
                  );
                }
                return null;
              },
            );
          },
        );
      },
    );
  }
}
