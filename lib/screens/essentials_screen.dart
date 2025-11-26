import 'package:flutter/material.dart';

class EssentialsScreen extends StatelessWidget {
  const EssentialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    String t(String ar, String en) => isAr ? ar : en;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('الأساسيات', 'Essentials'),
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(t('معلومات قد تهمك', 'Useful info'),
                style: const TextStyle(fontFamily: 'Tajawal')),
            onTap: () => Navigator.pushNamed(context, '/tips'),
          ),
          ListTile(
            leading: const Icon(Icons.apartment),
            title: Text(t('نبذة عنا', 'About us'),
                style: const TextStyle(fontFamily: 'Tajawal')),
            onTap: () => Navigator.pushNamed(context, '/about'),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(t('تواصل معنا', 'Contact us'),
                style: const TextStyle(fontFamily: 'Tajawal')),
            onTap: () => Navigator.pushNamed(context, '/contact'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: Text(t('محوّل العملات', 'Currency converter'),
                style: const TextStyle(fontFamily: 'Tajawal')),
            onTap: () => Navigator.pushNamed(context, '/currency'),
          ),
        ],
      ),
    );
  }
}
