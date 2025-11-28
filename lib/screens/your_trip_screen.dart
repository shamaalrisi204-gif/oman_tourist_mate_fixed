import 'package:flutter/material.dart';

import 'map_gmaps_screen.dart'; // عشان MapTripPlan

class YourTripScreen extends StatelessWidget {
  final List<MapTripPlan> plans;

  const YourTripScreen({
    super.key,
    required this.plans,
  });

  @override
  Widget build(BuildContext context) {
    final hasPlans = plans.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'رحلتي / My Trip',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        centerTitle: true,
      ),
      body: hasPlans
          ? ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final plan = plans[index];

                final place = plan.place;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.nameAr,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          place.nameEn,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'المدة: ${plan.durationText}',
                          style: const TextStyle(fontFamily: 'Tajawal'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'اقتراحات: '
                          '${plan.wantHotels ? 'فنادق ✔ ' : ''}'
                          '${plan.wantRestaurants ? 'مطاعم ✔ ' : ''}'
                          '${plan.wantSittings ? 'جلسات ✔ ' : ''}',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'ما عندك خطط محفوظة حتى الآن.\n'
                  'اختاري مكان من الخريطة واضغطي "تأكيد الخطة".',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                ),
              ),
            ),
    );
  }
}
