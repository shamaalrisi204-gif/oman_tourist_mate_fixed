// lib/widgets/create_trip_sheet.dart

import 'package:flutter/material.dart';

// نجيب المتغيّرات العامة من شاشة الخريطة

import '../screens/map_gmaps_screen.dart'
    show kTripName, kTripDays, kTripStartDate;

/// BottomSheet بسيط لإنشاء رحلة جديدة (اسم + عدد أيام)

Future<void> showCreateTripSheet(BuildContext context) async {
  final nameController = TextEditingController(
    text: kTripName ?? 'رحلتي',
  );

  int days = kTripDays > 0 ? kTripDays : 1;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'إنشاء رحلة / Create a trip',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'اسم الرحلة / Trip name',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'مثال: رحلة مسقط ٢٠٢٥',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'عدد الأيام / Number of days',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (days > 1) {
                          setSheetState(() => days--);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$days',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setSheetState(() => days++);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'اكتبي اسم للرحلة أولاً 😊',
                              style: TextStyle(fontFamily: 'Tajawal'),
                            ),
                          ),
                        );

                        return;
                      }

                      // نحفظ القيم في المتغيّرات العامة

                      kTripName = name;

                      kTripDays = days;

                      kTripStartDate = DateTime.now(); // تقدير بسيط الآن

                      Navigator.of(ctx).pop();
                    },
                    child: const Text(
                      'إنشاء رحلة / Create trip',
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );

  nameController.dispose();
}
