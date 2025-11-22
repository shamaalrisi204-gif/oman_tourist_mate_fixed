// lib/screens/governorate_places_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/gov_places.dart';

class GovernoratePlacesScreen extends StatelessWidget {
  final String govKey;
  final String titleAr;
  final String titleEn;
  final LatLng? center; // مركز المحافظة (من الخريطة)
  final List<GovPlace> places; // الأماكن الخاصة بهذه المحافظة

  const GovernoratePlacesScreen({
    super.key,
    required this.govKey,
    required this.titleAr,
    required this.titleEn,
    required this.places,
    this.center,
  });

  String _categoryLabel(GovPlaceCategory c) {
    switch (c) {
      case GovPlaceCategory.attraction:
        return 'أماكن سياحية / Attractions';
      case GovPlaceCategory.hotel:
        return 'فنادق / Hotels';
      case GovPlaceCategory.restaurant:
        return 'مطاعم / Restaurants';
      case GovPlaceCategory.cafe:
        return 'كوفيهات / Cafes';
    }
  }

  Future<void> _openInMaps(LatLng loc) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // نقسم الأماكن حسب الكاتيجوري
    final byCategory = <GovPlaceCategory, List<GovPlace>>{};
    for (final p in places) {
      byCategory.putIfAbsent(p.category, () => []).add(p);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // الهيدر بالصورة الكبيرة
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            title: Text(
              '$titleAr / $titleEn',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: places.isNotEmpty
                  ? Image.asset(
                      places.first.imageAsset,
                      fit: BoxFit.cover,
                    )
                  : Container(color: Colors.grey.shade300),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'استكشف ${titleAr} / Explore $titleEn',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اختر من الأماكن التالية: سياحية، فنادق، مطاعم، كوفيهات.',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔻 لكل كاتيجوري نعرض عنوان + كروت
                  for (final entry in byCategory.entries) ...[
                    Text(
                      _categoryLabel(entry.key),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: entry.value.map((place) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () => _openInMaps(place.location),
                            borderRadius: BorderRadius.circular(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(18)),
                                  child: Image.asset(
                                    place.imageAsset,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${place.nameAr} / ${place.nameEn}',
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        place.descriptionAr,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment:
                                            AlignmentDirectional.centerEnd,
                                        child: Text(
                                          'عرض في الخريطة / View on map',
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 12,
                                            color: Colors.teal.shade700,
                                            decoration:
                                                TextDecoration.underline,
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
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
