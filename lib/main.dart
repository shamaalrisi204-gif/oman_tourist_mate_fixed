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
import 'screens/map_gmaps_screen.dart';
import 'screens/info_screen.dart';
import 'screens/travel_tips_screen.dart';
import 'screens/ai_concierge_screen.dart';

// ✨ جديد: شاشة الـ Bottom Nav + شاشة Essentials
import 'screens/main_nav_screen.dart';
import 'screens/essentials_screen.dart';

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
    // حالياً نبدأ دائماً بالسلاش
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

              // أول شاشة
              home: start ?? const OmanSplashScreen(),

              routes: {
                '/welcome': (_) => const WelcomeScreen(),
                '/login': (_) => const LoginScreen(),
                '/forgot_password': (_) => const ForgotPasswordScreen(),
                '/signup': (_) => const SignUpScreen(),

                // 🔥 لو حبيتي لسه توصلي ل UserHome بدون البار
                '/user': (_) => const UserHome(),

                // خريطة
                '/map': (_) => const OmanGMapsScreen(),

                '/favorites': (_) => const FavoritesScreen(),
                '/ai_chat': (_) => const AiConciergeScreen(),
                '/preferences': (_) => const PreferencesScreen(),
                '/guest': (_) => const GuestHomeScreen(),
                '/about': (_) => const AboutUsScreen(),
                '/contact': (_) => const ContactUsScreen(),
                '/main': (_) => const MainMenuScreen(),
                '/user_home': (_) => const UserHome(),
                '/currency': (_) => const CurrencyConverterScreen(),
                '/my_trip': (_) => const YourTripScreen(),
                '/map_guest': (_) =>
                    const OmanGMapsScreen(enablePlanning: false),
                '/info': (_) => const InfoScreen(),
                '/tips': (_) => const TravelTipsScreen(),

                // ✨ جديد: الشاشة اللي فيها BottomNavigationBar
                '/main_nav': (_) => const MainNavScreen(),

                // ✨ جديد: شاشة Essentials (المزيد)
                '/essentials': (_) => const EssentialsScreen(),

                // لو حابّة Routes للكروت (Flights / Stays / Tours ...)
                // تقدري تبدئين بسكافولد بسيط لكل واحد حالياً:
                // '/flights': (_) => const FlightsScreen(),
                // '/stays':   (_) => const StaysScreen(),
                // ...
              },
              onGenerateRoute: (settings) {
                // تفاصيل المكان
                if (settings.name == '/place_details') {
                  final args =
                      (settings.arguments ?? {}) as Map<String, dynamic>;

                  return MaterialPageRoute(
                    builder: (_) => PlaceDetailsScreen(
                      place: args,
                      isArabic: (args['isArabic'] as bool?) ?? true,
                    ),
                  );
                }

                // شاشة OTP
                if (settings.name == '/verify_otp') {
                  final args = settings.arguments as Map<String, dynamic>?;

                  return MaterialPageRoute(
                    builder: (_) => VerifyOtpScreen(
                      email: args?['email'] ?? '',
                      firstName: args?['firstName'] ?? '',
                      lastName: args?['lastName'] ?? '',
                      phone: args?['phone'] ?? '',
                      password: args?['password'] ?? '',
                      username: args?['username'] ?? '',
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
