import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:intl/intl.dart';

import 'package:url_launcher/url_launcher.dart';

import 'dart:ui' as ui;

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  static const Color bg = Color(0xFF171426);

  static const Color card = Color(0xFF282036);

  static const Color purple = Color(0xFF49304F);

  static const Color gold = Color(0xFFFFC56E);

  static const Color white = Color(0xFFFFF8F0);

  bool isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar';

  String txt(BuildContext context, String ar, String en) =>
      isArabic(context) ? ar : en;

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get savedRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('savedEvents');

  CollectionReference<Map<String, dynamic>> get reminderRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('eventReminders');

  Stream<QuerySnapshot<Map<String, dynamic>>> eventsStream() {
    return FirebaseFirestore.instance
        .collection('events')
        .where(
          'startAt',
          isGreaterThanOrEqualTo: Timestamp.now(),
        )
        .orderBy('startAt')
        .snapshots();
  }

  Future<void> toggleSaved(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
    bool currentlySaved,
  ) async {
    if (uid.isEmpty) {
      showMessage(
          context,
          txt(context, 'سجّل الدخول أولاً لحفظ الفعالية',
              'Please sign in first.'));

      return;
    }

    try {
      if (currentlySaved) {
        await savedRef.doc(id).delete();
      } else {
        await savedRef.doc(id).set({
          ...data,
          'eventId': id,
          'savedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('$e');
      if (!context.mounted) return;
      showMessage(context, 'تعذر تحديث المحفوظات');
    }
  }

  Future<void> toggleReminder(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
    bool enabled,
  ) async {
    if (uid.isEmpty) {
      showMessage(
          context,
          txt(context, 'سجّل الدخول أولاً لتفعيل التذكير',
              'Please sign in first.'));

      return;
    }

    try {
      if (enabled) {
        await reminderRef.doc(id).delete();
      } else {
        await reminderRef.doc(id).set({
          ...data,
          'eventId': id,
          'enabled': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (!context.mounted) return;
      showMessage(
        context,
        enabled
            ? txt(context, 'تم إيقاف التذكير', 'Reminder disabled')
            : txt(context, 'تم تفعيل التذكير', 'Reminder enabled'),
      );
    } catch (e) {
      debugPrint('$e');
      if (!context.mounted) return;
      showMessage(context, 'تعذر تحديث التذكير');
    }
  }

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);

    return DefaultTabController(
      length: 3,
      child: Directionality(
        textDirection: ar ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: white),
            title: Text(
              txt(context, 'فعاليات عُمان', 'Oman Events'),
              style: const TextStyle(
                color: white,
                fontWeight: FontWeight.bold,
                fontSize: 21,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => DefaultTabController.of(context).animateTo(2),
                icon: const Icon(
                  Icons.notifications_active_outlined,
                  color: gold,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              _hero(context),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                      color: Colors.white12,
                    ),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    labelColor: bg,
                    unselectedLabelColor: white,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        text: txt(context, 'اكتشف', 'Explore'),
                        icon: const Icon(Icons.explore_outlined),
                      ),
                      Tab(
                        text: txt(context, 'المحفوظة', 'Saved'),
                        icon: const Icon(Icons.favorite_border),
                      ),
                      Tab(
                        text: txt(context, 'تذكيراتي', 'Reminders'),
                        icon: const Icon(Icons.notifications_none),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    _explore(context),
                    _saved(context),
                    _reminders(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        image: const DecorationImage(
          image: AssetImage('assets/images/oman_fort.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.65),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                txt(context, 'اكتشف أجمل فعاليات عُمان',
                    'Discover Oman Events'),
                style: const TextStyle(
                  color: white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                txt(
                  context,
                  'اكتشف المهرجانات والأنشطة والمناسبات في مختلف المحافظات',
                  'Explore festivals and activities across Oman',
                ),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  const Icon(Icons.location_on, color: gold, size: 17),
                  const SizedBox(width: 5),
                  Text(
                    txt(context, 'سلطنة عُمان', 'Sultanate of Oman'),
                    style: const TextStyle(
                      color: gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _explore(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: eventsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _empty(
            context,
            txt(context, 'حدث خطأ في تحميل الفعاليات', 'Could not load events'),
            Icons.error_outline,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: gold),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _empty(
            context,
            txt(context, 'لا توجد فعاليات قادمة حالياً', 'No upcoming events'),
            Icons.event_busy,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle(
              context,
              txt(context, 'الفعاليات القادمة', 'Upcoming Events'),
              docs.length,
            ),
            const SizedBox(height: 14),
            ...docs.map(
              (doc) => _eventCard(
                context,
                doc.id,
                doc.data(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _saved(BuildContext context) {
    if (uid.isEmpty) {
      return _empty(
        context,
        txt(context, 'سجّل الدخول لعرض فعالياتك المحفوظة',
            'Sign in to see saved events'),
        Icons.lock_outline,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: savedRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: gold),
          );
        }

        if (snapshot.hasError) {
          return _empty(context, 'تعذر تحميل المحفوظات', Icons.error_outline);
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _empty(
            context,
            txt(context, 'لم تحفظ أي فعالية حتى الآن',
                'You have no saved events yet'),
            Icons.favorite_border,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle(
              context,
              txt(context, 'فعالياتي المحفوظة', 'Saved Events'),
              docs.length,
            ),
            const SizedBox(height: 14),
            ...docs.map(
              (doc) => _eventCard(
                context,
                doc.id,
                doc.data(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _reminders(BuildContext context) {
    if (uid.isEmpty) {
      return _empty(
        context,
        txt(context, 'سجّل الدخول لعرض تذكيراتك',
            'Sign in to see your reminders'),
        Icons.lock_outline,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: reminderRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: gold),
          );
        }

        if (snapshot.hasError) {
          return _empty(context, 'تعذر تحميل التذكيرات', Icons.error_outline);
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _empty(
            context,
            txt(
              context,
              'لم تفعل أي تذكيرات بعد.\nاحفظ الفعاليات وفعل الجرس لتجدها هنا.',
              'No reminders yet.\nEnable reminders on events to see them here.',
            ),
            Icons.notifications_none,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            const Icon(
              Icons.event_available,
              size: 65,
              color: gold,
            ),
            const SizedBox(height: 12),
            Text(
              txt(context, 'تذكيرات فعالياتي', 'My Event Reminders'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              txt(
                context,
                'قائمة الفعاليات التي قمت بتفعيل التذكير لها',
                'Events for which you enabled reminders',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ...docs.map(
              (doc) => _reminderCard(
                context,
                doc.id,
                doc.data(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _reminderCard(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    final ar = isArabic(context);

    final title = ar
        ? data['titleAr'] ?? data['titleEn'] ?? ''
        : data['titleEn'] ?? data['titleAr'] ?? '';

    final location = data['locationName'] ?? '';

    final imageUrl = data['imageUrl']?.toString() ?? '';

    final date = _eventDate(data['startAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _eventImage(imageUrl, 85, 90),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                _smallInfo(Icons.location_on, location.toString()),
                if (date != null)
                  _smallInfo(
                    Icons.calendar_month,
                    DateFormat('dd/MM/yyyy - hh:mm a').format(date),
                  ),
                const SizedBox(height: 7),
                Text(
                  txt(context, 'التذكير مفعّل', 'Reminder enabled'),
                  style: const TextStyle(
                    color: gold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: true,
            activeThumbColor: gold,
            onChanged: (value) {
              toggleReminder(context, id, data, true);
            },
          ),
        ],
      ),
    );
  }

  Widget _eventCard(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    final ar = isArabic(context);

    final title = ar
        ? data['titleAr'] ?? data['titleEn'] ?? ''
        : data['titleEn'] ?? data['titleAr'] ?? '';

    final isTestEvent = title.toString().contains('تجريبية');

    final location = data['locationName'] ?? '';

    final imageUrl = data['imageUrl']?.toString() ?? '';

    final date = _eventDate(data['startAt']);

    final userExists = uid.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: isTestEvent
                    ? Image.asset(
                        'assets/images/muscat_nights_fireworks.jpg',
                        width: double.infinity,
                        height: 185,
                        fit: BoxFit.cover,
                      )
                    : _eventImage(imageUrl, double.infinity, 185),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: data['isFeatured'] == true
                        ? gold
                        : Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['isFeatured'] == true
                        ? txt(context, 'فعالية مميزة', 'Featured')
                        : txt(context, 'اكتشف الفعالية', 'Discover'),
                    style: TextStyle(
                      color: data['isFeatured'] == true ? bg : white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              if (userExists)
                Positioned(
                  top: 8,
                  left: 8,
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: savedRef.doc(id).snapshots(),
                    builder: (context, snap) {
                      final saved = snap.data?.exists ?? false;

                      return IconButton(
                        onPressed: () => toggleSaved(
                          context,
                          id,
                          data,
                          saved,
                        ),
                        icon: Icon(
                          saved ? Icons.favorite : Icons.favorite_border,
                          color: saved ? Colors.redAccent : white,
                          size: 29,
                        ),
                      );
                    },
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 16,
                child: Text(
                  title.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _smallInfo(Icons.location_on_outlined, location.toString()),
                if (date != null) ...[
                  const SizedBox(height: 9),
                  _smallInfo(
                    Icons.calendar_month_outlined,
                    DateFormat('dd/MM/yyyy - hh:mm a').format(date),
                  ),
                ],
                const SizedBox(height: 15),
                Row(
                  children: [
                    if (userExists)
                      Expanded(
                        child: StreamBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                          stream: reminderRef.doc(id).snapshots(),
                          builder: (context, snap) {
                            final enabled = snap.data?.exists ?? false;

                            return OutlinedButton.icon(
                              onPressed: () => toggleReminder(
                                context,
                                id,
                                data,
                                enabled,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: gold,
                                side: const BorderSide(color: gold),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                              ),
                              icon: Icon(
                                enabled
                                    ? Icons.notifications_active
                                    : Icons.notifications_none,
                                size: 19,
                              ),
                              label: Text(
                                enabled
                                    ? txt(
                                        context, 'التذكير مفعّل', 'Reminder on')
                                    : txt(context, 'ذكّرني', 'Remind me'),
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showDetails(
                          context,
                          data,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: bg,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          txt(context, 'عرض التفاصيل ←', 'View Details →'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _eventDate(dynamic value) {
    if (value is Timestamp) return value.toDate();

    if (value is DateTime) return value;

    return null;
  }

  Widget _eventImage(String url, double width, double height) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: purple,
      child: const Center(
        child: Icon(
          Icons.event,
          size: 45,
          color: gold,
        ),
      ),
    );
  }

  Widget _smallInfo(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: gold, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
    int count,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: purple,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _empty(
    BuildContext context,
    String message,
    IconData icon,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: gold, size: 65),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: white,
                fontSize: 15,
                height: 1.7,
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
    final ar = isArabic(context);

    final title = ar
        ? data['titleAr'] ?? data['titleEn'] ?? ''
        : data['titleEn'] ?? data['titleAr'] ?? '';

    final description = ar
        ? data['descriptionAr'] ?? data['descriptionEn'] ?? ''
        : data['descriptionEn'] ?? data['descriptionAr'] ?? '';

    final source = data['sourceUrl']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return Directionality(
          textDirection: ar ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.all(23),
            child: SafeArea(
              child: Wrap(
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    title.toString(),
                    style: const TextStyle(
                      color: gold,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    description.toString().isEmpty
                        ? txt(context, 'لا توجد تفاصيل إضافية',
                            'No additional details')
                        : description.toString(),
                    style: const TextStyle(
                      color: white,
                      fontSize: 15,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (source.startsWith('https://'))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: bg,
                        ),
                        onPressed: () async {
                          final uri = Uri.tryParse(source);

                          if (uri != null) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: Text(
                          txt(context, 'زيارة المصدر الرسمي',
                              'Visit Official Source'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
