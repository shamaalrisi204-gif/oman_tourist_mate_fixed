import 'package:flutter/material.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _isArabic = true;
  String t(String ar, String en) => _isArabic ? ar : en;
  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(Icons.map, t('الخريطة', 'Map'), '/map'),
      _MenuItem(Icons.favorite_border, t('المفضلة', 'Favorites'), '/favorites'),
      _MenuItem(Icons.smart_toy_outlined, t('مساعد الرحلات', 'Assistant'),
          '/assistant'),
      _MenuItem(Icons.dashboard_customize_outlined,
          t('قائمة المستخدم', 'User Home'), '/user_home'),
      _MenuItem(
          Icons.home_outlined, t('القائمة الرئيسية', 'Main Menu'), '/main'),
      _MenuItem(Icons.logout, t('تسجيل الخروج', 'Sign out'), '/login',
          isSignOut: true),
    ];
    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('القائمة الرئيسية', 'Main Menu')),
          actions: [
            TextButton(
              onPressed: () => setState(() => _isArabic = !_isArabic),
              child: Text(_isArabic ? 'English' : 'العربية'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // شبكتين
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, i) => _MenuCard(item: items[i]),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String route;
  final bool isSignOut;
  const _MenuItem(this.icon, this.title, this.route, {this.isSignOut = false});
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;
    return InkWell(
      onTap: () {
        if (item.isSignOut) {
          // لو عندك FirebaseAuth: اعملي signOut هنا قبل التوجيه.
          Navigator.pushNamedAndRemoveUntil(context, item.route, (_) => false);
        } else {
          Navigator.pushNamed(context, item.route);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 36),
              const SizedBox(height: 8),
              Text(item.title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
