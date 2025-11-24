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

import 'screens/oman_splash_screen.dart';

import 'screens/welcome_screen.dart';

import 'screens/login_screen.dart';

import 'screens/currency_converter_screen.dart';

import 'screens/forgot_password_screen.dart';

import 'screens/signup_screen.dart';

import 'screens/user_home.dart';

import 'screens/favorites_screen.dart';

import 'screens/place_details_screen.dart';

import 'screens/ai_chat_screen.dart';

import 'screens/your_trip_screen.dart';

import 'screens/preference_screen.dart';

import 'screens/guest_home.dart';

import 'screens/about_us_screen.dart';

import 'screens/contact_us_screen.dart';

import 'screens/main_menu_screen.dart';

import 'screens/verify_otp_screen.dart';

// 👇 هذا هو ملف خريطة جوجل الحقيقية

import 'screens/map_gmaps_screen.dart';

import 'screens/info_screen.dart';

import 'screens/travel_tips_screen.dart';

// الإذونات

import 'package:permission_handler/permission_handler.dart';

import 'package:geolocator/geolocator.dart';

const bool kForceWelcomeOnStart = true;

const bool kUseFunctionsEmulator = false;

Future<void> _ensureLocationPermission() async {
  final enabled = await Geolocator.isLocationServiceEnabled();

  if (!enabled) await Geolocator.openLocationSettings();

  var status = await Permission.locationWhenInUse.status;

  if (status.isDenied || status.isRestricted) {
    status = await Permission.locationWhenInUse.request();
  }

  if (status.isPermanentlyDenied) {
    await openAppSettings();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
              supportedLocales: const [
                Locale('ar'),
                Locale('en'),
              ],
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
              home: start ?? const OmanSplashScreen(),
              routes: {
                '/welcome': (_) => const WelcomeScreen(),

                '/login': (_) => const LoginScreen(),

                '/forgot_password': (_) => const ForgotPasswordScreen(),

                '/signup': (_) => const SignUpScreen(),

                '/user': (_) => const UserHome(),

                // 🔥 هذا هو Route الخريطة الوحيد

                '/map': (_) => const OmanGMapsScreen(),

                '/favorites': (_) => const FavoritesScreen(),

                '/ai_chat': (_) => const AiChatScreen(),

                '/preferences': (_) => const PreferencesScreen(),

                '/guest': (_) => const GuestHomeScreen(),

                '/about': (_) => const AboutUsScreen(),

                '/contact': (_) => const ContactUsScreen(),

                '/main': (_) => const MainMenuScreen(),

                '/user_home': (_) => const UserHome(),

                '/currency': (_) => const CurrencyConverterScreen(),

                '/my_trip': (context) => const YourTripScreen(),

                '/map_guest': (_) =>
                    const OmanGMapsScreen(enablePlanning: false), // guest

                '/info': (_) => const InfoScreen(),

                '/tips': (context) => const TravelTipsScreen(),
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
                      username: (args['username'] ?? '') as String,
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
