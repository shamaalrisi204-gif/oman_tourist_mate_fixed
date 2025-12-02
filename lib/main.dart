import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

// Firebase

import 'package:firebase_core/firebase_core.dart';

import 'package:cloud_functions/cloud_functions.dart';

import 'firebase_options.dart';

// حالة التطبيق

import 'core/app_state.dart';

import 'core/prefs.dart';

// شاشة البداية الوحيدة

import 'screens/onboarding_screen.dart';

// باقي الشاشات

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

import 'screens/main_nav_screen.dart';

import 'screens/essentials_screen.dart';
import 'screens/trip_planner_screen.dart';

// الإذن للموقع

import 'package:permission_handler/permission_handler.dart';

import 'package:geolocator/geolocator.dart';

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

  await Prefs.setLoggedIn(false);

  await Prefs.setOnboardingDone(false);

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

  @override
  Widget build(BuildContext context) {
    final app = AppStateProvider.of(context);

    return AnimatedBuilder(
      animation: app,
      builder: (_, __) {
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

          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            fontFamily: 'Tajawal',
          ),

          darkTheme: ThemeData.dark(useMaterial3: true),

          // 👈 شاشة الورد + الشعار هي البداية الوحيدة

          home: const OnboardingScreen(),

          routes: {
            '/welcome': (_) => const WelcomeScreen(),
            '/login': (_) => const LoginScreen(),
            '/forgot_password': (_) => const ForgotPasswordScreen(),
            '/signup': (_) => const SignUpScreen(),
            '/user': (_) => const UserHome(),
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
            '/trip_planner': (context) => const TripPlannerScreen(),
            '/my_trip': (ctx) {
              final args = ModalRoute.of(ctx)?.settings.arguments;
              final plans = args is List<MapTripPlan> ? args : <MapTripPlan>[];
              return YourTripScreen(plans: plans);
            },
            '/map_guest': (_) => const OmanGMapsScreen(enablePlanning: false),
            '/info': (_) => const InfoScreen(),
            '/tips': (_) => const TravelTipsScreen(),
            '/main_nav': (_) => const MainNavScreen(),
            '/essentials': (_) => const EssentialsScreen(),
          },
        );
      },
    );
  }
}
