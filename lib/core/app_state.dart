import 'package:flutter/material.dart';
import 'prefs.dart';

class AppState extends ChangeNotifier {
  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.light;
  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  /// تحميل الإعدادات من Prefs
  Future<void> bootstrap() async {
    final lang = await Prefs.getLanguage();
    _locale = Locale(lang);
    final dark = await Prefs.getDarkMode();
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    await Prefs.setLanguage(code);
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool enabled) async {
    await Prefs.setDarkMode(enabled);
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

/// مزوّد حالة بسيط
class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);
  static AppState of(BuildContext context) {
    final p = context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(p != null, 'AppStateProvider not found in context');
    return p!.notifier!;
  }

  @override
  bool updateShouldNotify(covariant InheritedNotifier<AppState> oldWidget) =>
      true;
}
