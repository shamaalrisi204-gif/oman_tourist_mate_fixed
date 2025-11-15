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

import 'screens/oman_splash_screen.dart'; // 👈 أضفنا شاشة الترحيب الجديدة

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
import 'screens/map_gmaps_screen.dart'; // 👈 خريطة جوجل لعُمان

// ⭐ NEW

import 'package:permission_handler/permission_handler.dart';

import 'package:geolocator/geolocator.dart';

const bool kForceWelcomeOnStart = true;

const bool kUseFunctionsEmulator = false;

Future<void> _ensureLocationPermission() async {
  // تفعيل خدمات الموقع

  final enabled = await Geolocator.isLocationServiceEnabled();

  if (!enabled) {
    // افتحي إعدادات تفعيل الـ GPS

    await Geolocator.openLocationSettings();
  }

  // اطلب الإذن

  var status = await Permission.locationWhenInUse.status;

  if (status.isDenied || status.isRestricted) {
    status = await Permission.locationWhenInUse.request();
  }

  // في حال "عدم السؤال مجدداً"

  if (status.isPermanentlyDenied) {
    await openAppSettings();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app();
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  if (kUseFunctionsEmulator) {
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';

    FirebaseFunctions.instanceFor(region: 'us-central1')
        .useFunctionsEmulator(host, 5002);
  }

  if (kForceWelcomeOnStart) {
    await Prefs.setLoggedIn(false);

    await Prefs.setOnboardingDone(false);
  }

  // ⭐ NEW: اطلب إذن الموقع قبل تشغيل التطبيق

  await _ensureLocationPermission();

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

  Future<Widget> _decideStart() async {
    // 👇 نحافظ على نفس المنطق القديم، لكن نبدأ أولاً بـ شاشة عمان الترحيبية

    return const OmanSplashScreen();
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

              // 👇 شاشة البداية الجديدة

              home: start ?? const OmanSplashScreen(),

              routes: {
                '/welcome': (_) => const WelcomeScreen(),

                '/login': (_) => const LoginScreen(),

                '/signup': (_) => const SignUpScreen(),

                '/user': (_) => const UserHome(),

                '/map': (_) =>
                    const MapScreen(), // ← الخريطة (WebView أو Leaflet)

                '/favorites': (_) => const FavoritesScreen(),

                '/ai_chat': (_) => const AiChatScreen(),

                '/preferences': (_) => const PreferencesScreen(),

                '/guest': (_) => const GuestHomeScreen(),

                '/about': (_) => const AboutUsScreen(),

                '/contact': (_) => const ContactUsScreen(),

                '/main': (_) => const MainMenuScreen(),

                '/user_home': (_) => const UserHome(),

                '/map': (_) => const OmanGMapsScreen(), // ← خريطة جوجل لعُمان
              },

              onGenerateRoute: (settings) {
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
