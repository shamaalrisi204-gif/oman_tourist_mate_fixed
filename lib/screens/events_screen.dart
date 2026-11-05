import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';

import 'package:url_launcher/url_launcher.dart';

import 'dart:ui' as ui;

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  static const Color green = Color(0xFF123F35);

  static const Color gold = Color(0xFFD9BA7A);

  static const Color background = Color(0xFFFFF8EF);

  bool _isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar';

  String _text(
    BuildContext context,
    String ar,
    String en,
  ) =>
      _isArabic(context) ? ar : en;

  Stream<QuerySnapshot<Map<String, dynamic>>> _eventsStream() {
    return FirebaseFirestore.instance.collection('events').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _isArabic(context);

    return Directionality(
      textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: green),
          title: Text(
            _text(context, 'فعاليات عُمان', 'Oman Events'),
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              color: green,
              fontSize: 21,
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _eventsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('EVENTS ERROR: ${snapshot.error}');

              return _message(
                _text(
                  context,
                  'حدث خطأ أثناء تحميل الفعاليات.',
                  'Could not load events.',
                ),
                Icons.error_outline,
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: green),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return _message(
                _text(
                  context,
                  'لا توجد فعاليات قادمة حالياً.\nتابعنا لاكتشاف الفعاليات الجديدة!',
                  'No upcoming events yet.\nCheck back for new events!',
                ),
                Icons.event_available_outlined,
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(context),
                const SizedBox(height: 18),
                Text(
                  _text(
                    context,
                    'الفعاليات القادمة',
                    'Upcoming Events',
                  ),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                const SizedBox(height: 12),
                ...docs.map((doc) {
                  final data = doc.data();

                  return _eventCard(context, data);
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      height: 155,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [green, Color(0xFF245F4C)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: gold, width: 1.2),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            bottom: 0,
            child: Icon(
              Icons.landscape,
              size: 115,
              color: gold.withValues(alpha: 0.30),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _text(
                    context,
                    'اكتشف عُمان',
                    'Discover Oman',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Tajawal',
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _text(
                    context,
                    'تابع أبرز الفعاليات والأنشطة في السلطنة',
                    'Explore events and activities across Oman',
                  ),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final isAr = _isArabic(context);

    final title = (isAr ? data['titleAr'] : data['titleEn']) ??
        data['titleAr'] ??
        data['titleEn'] ??
        '';

    final location = data['locationName'] ?? '';

    final imageUrl = data['imageUrl'] ?? '';

    final startAt = data['startAt'];

    DateTime? date;

    if (startAt is Timestamp) {
      date = startAt.toDate();
    } else if (startAt is DateTime) {
      date = startAt;
    }

    final dateText = date == null
        ? ''
        : DateFormat(
            'dd MMM yyyy - hh:mm a',
            isAr ? 'ar' : 'en',
          ).format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: const Color(0xFFFFFCF7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: gold, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context, data),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 175,
              width: double.infinity,
              child: imageUrl.toString().startsWith('http')
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['isFeatured'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4E7CB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _text(context, 'فعالية مميزة', 'Featured'),
                        style: const TextStyle(
                          color: green,
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    title.toString(),
                    style: const TextStyle(
                      color: green,
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoRow(Icons.location_on_outlined, location.toString()),
                  const SizedBox(height: 7),
                  _infoRow(Icons.calendar_month_outlined, dateText),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _text(context, 'عرض التفاصيل ←', 'View Details →'),
                      style: const TextStyle(
                        color: green,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFE9E1D2),
      child: const Center(
        child: Icon(
          Icons.event,
          color: green,
          size: 55,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 19, color: gold),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.black87,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _message(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: green, size: 55),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                color: green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final isAr = _isArabic(context);

    final title = (isAr ? data['titleAr'] : data['titleEn']) ??
        data['titleAr'] ??
        data['titleEn'] ??
        '';

    final description =
        (isAr ? data['descriptionAr'] : data['descriptionEn']) ??
            data['descriptionAr'] ??
            data['descriptionEn'] ??
            _text(context, 'لا توجد تفاصيل إضافية.', 'No additional details.');

    final sourceUrl = data['sourceUrl']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) => Directionality(
        textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SafeArea(
            child: Wrap(
              children: [
                Text(
                  title.toString(),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  description.toString(),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
                if (sourceUrl.startsWith('https://'))
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                      ),
                      onPressed: () async {
                        final uri = Uri.tryParse(sourceUrl);

                        if (uri != null) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: Text(
                        _text(
                          context,
                          'زيارة المصدر الرسمي',
                          'Visit Official Source',
                        ),
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
