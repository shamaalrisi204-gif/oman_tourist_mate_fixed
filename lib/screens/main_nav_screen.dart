import 'package:flutter/material.dart';

import 'user_home.dart';
import 'ai_concierge_screen.dart';
import 'favorites_screen.dart'; // غيّري الاسم إذا ملفك مختلف
import 'map_gmaps_screen.dart';
import 'essentials_screen.dart'; // بنكتبه تحت

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({
    super.key,
    this.isGuest = false,
  });

  final bool isGuest;

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final pages = <Widget>[
      UserHome(isGuest: widget.isGuest),
      const AiConciergeScreen(),
      const FavoritesScreen(), // لو ما عندك شاشة مفضلة حطي Placeholder
      OmanGMapsScreen(enablePlanning: !widget.isGuest),
      const EssentialsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: isArabic ? 'الرئيسية' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_border),
            label: isArabic ? 'المفضلة' : 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: isArabic ? 'الخريطة' : 'Map',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_rounded),
            label: isArabic ? 'المزيد' : 'Essentials',
          ),
        ],
      ),
    );
  }
}
