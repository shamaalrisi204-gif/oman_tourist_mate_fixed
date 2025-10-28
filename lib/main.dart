// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// بدون Firebase علشان الإقلاع يكون فوري
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

// أثناء التطوير: ابدأ دائمًا من شاشة الترحيب
const bool kForceWelcomeOnStart = true;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // نخلي المستخدم غير مسجل ومكمّل Onboarding عشان يفتح Welcome
  if (kForceWelcomeOnStart) {
    await Prefs.setLoggedIn(false);
    await Prefs.setOnboardingDone(false);
  }
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
    if (kForceWelcomeOnStart) {
      return const WelcomeScreen();
    }
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
              themeMode: app.themeMode,
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                fontFamily: 'Tajawal',
              ),
              darkTheme: ThemeData.dark(useMaterial3: true),
              locale: app.locale,
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              // شاشة البداية
              home: start ??
                  const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
              // كل الراوتات
              routes: {
                '/welcome': (_) => const WelcomeScreen(),
                '/login': (_) => const LoginScreen(),
                '/signup': (_) => const SignupScreen(),
                '/user': (_) => const UserHome(),
                '/map': (_) => const MapScreen(),
                '/favorites': (_) => const FavoritesScreen(),
                '/ai_chat': (_) => const AiChatScreen(),
                '/preferences': (_) => const PreferencesScreen(),
                '/guest': (_) => const GuestHomeScreen(),
                '/about': (_) => const AboutUsScreen(),
                '/contact': (_) => const ContactUsScreen(),
                '/main': (_) => const MainMenuScreen(),
                '/user_home': (_) => const UserHome(), // alias اختياري
              },
              // route ديناميكي لتفاصيل المكان
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
                return null;
              },
            );
          },
        );
      },
    );
  }
}
