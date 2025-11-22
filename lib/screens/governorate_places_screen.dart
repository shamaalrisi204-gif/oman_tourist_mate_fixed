// lib/screens/governorate_places_screen.dart

import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

import '../models/gov_places.dart';

class GovernoratePlacesScreen extends StatefulWidget {
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

  @override
  State<GovernoratePlacesScreen> createState() =>
      _GovernoratePlacesScreenState();
}

class _GovernoratePlacesScreenState extends State<GovernoratePlacesScreen> {
  /// الفلتر الحالي للأماكن السياحية (null = الكل)

  AttractionType? _selectedAttractionType;

  /// صورة الهيدر الحالية (تتغير حسب نوع المكان)

  String? _headerImageAsset;

  @override
  void initState() {
    super.initState();

    _headerImageAsset = _findHeaderImageFor(null);
  }

  // —————————————  Helpers  —————————————

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

  String _attractionTypeLabel(AttractionType? t) {
    switch (t) {
      case null:
        return 'الكل / All';

      case AttractionType.beach:
        return 'أماكن بحرية';

      case AttractionType.historic:
        return 'أماكن تاريخية';

      case AttractionType.mountain:
        return 'أماكن جبلية';

      case AttractionType.desert:
        return 'أماكن برية / صحراوية';
    }
  }

  /// اختيار صورة مناسبة للهيدر بناءً على نوع المكان السياحي

  String? _findHeaderImageFor(AttractionType? type) {
    if (widget.places.isEmpty) return null;

    // لو فيه نوع معيّن، نجيب أول مكان سياحي من هذا النوع

    if (type != null) {
      final matches = widget.places.where((p) =>
          p.category == GovPlaceCategory.attraction &&
          p.attractionType == type);

      if (matches.isNotEmpty) return matches.first.imageAsset;
    }

    // غير كذا: أول صورة في القائمة (أيًا كان نوعها)

    return widget.places.first.imageAsset;
  }

  Future<void> _openInMaps(LatLng loc) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}';

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// يبني Chip لنوع المكان السياحي

  Widget _buildTypeChip(AttractionType? type) {
    final bool selected = _selectedAttractionType == type;

    return ChoiceChip(
      label: Text(
        _attractionTypeLabel(type),
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 11,
          color: selected ? Colors.white : Colors.black87,
        ),
      ),
      selected: selected,
      selectedColor: const Color(0xFF5E2BFF),
      backgroundColor: Colors.grey.shade200,
      onSelected: (_) {
        setState(() {
          _selectedAttractionType = type;

          _headerImageAsset = _findHeaderImageFor(type);
        });
      },
    );
  }

  /// ترجع الأماكن بعد الفلترة حسب النوع (لو كان Attractions)

  List<GovPlace> _filteredByCategory(
      GovPlaceCategory cat, List<GovPlace> original) {
    if (cat != GovPlaceCategory.attraction || _selectedAttractionType == null) {
      return original;
    }

    return original
        .where((p) => p.attractionType == _selectedAttractionType)
        .toList();
  }

  Widget _buildPlaceCard(GovPlace place) {
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
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

                  // ⭐ التقييم لو موجود

                  if (place.rating != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${place.rating!.toStringAsFixed(1)} / 5',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // 🔗 روابط خارجية (إنستغرام / Booking / خريطة)

                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (place.instagramUrl != null)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(place.instagramUrl!);

                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: const Text(
                            'Instagram',
                            style:
                                TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                          ),
                        ),
                      if (place.bookingUrl != null)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(place.bookingUrl!);

                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.hotel, size: 16),
                          label: const Text(
                            'احجز عن طريق Booking / Book',
                            style:
                                TextStyle(fontFamily: 'Tajawal', fontSize: 11),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _openInMaps(place.location),
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text(
                          'عرض في الخريطة / View on map',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // —————————————  BUILD  —————————————

  @override
  Widget build(BuildContext context) {
    // نقسم الأماكن حسب الكاتيجوري

    final byCategory = <GovPlaceCategory, List<GovPlace>>{};

    for (final p in widget.places) {
      byCategory.putIfAbsent(p.category, () => []).add(p);
    }

    final titleText = '${widget.titleAr} / ${widget.titleEn}';

    final headlineAr = 'تقويم الفعاليات والأماكن في ${widget.titleAr}';

    final headlineEn = 'Events & Places Calendar in ${widget.titleEn}';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // الهيدر بالصورة الكبيرة

          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            title: Text(
              titleText,
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _headerImageAsset != null
                  ? Image.asset(
                      _headerImageAsset!,
                      fit: BoxFit.cover,
                    )
                  : (widget.places.isNotEmpty
                      ? Image.asset(
                          widget.places.first.imageAsset,
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey.shade300)),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الجملة الرئيسية الواضحة بدل اللي كانت فوق الصورة

                  Text(
                    headlineAr,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    headlineEn,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'استعرض الأماكن البحرية، التاريخية، الجبلية والبرية،'
                    ' بالإضافة إلى فنادق ومطاعم وكوفيهات مختارة في المحافظة.',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 20),

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

                    // لو كان القسم "أماكن سياحية" نعرض فلتر الأنواع

                    if (entry.key == GovPlaceCategory.attraction) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTypeChip(null),
                            _buildTypeChip(AttractionType.beach),
                            _buildTypeChip(AttractionType.historic),
                            _buildTypeChip(AttractionType.mountain),
                            _buildTypeChip(AttractionType.desert),
                          ]
                              .map(
                                (w) => Padding(
                                  padding:
                                      const EdgeInsetsDirectional.only(end: 8),
                                  child: w,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Column(
                      children: _filteredByCategory(entry.key, entry.value)
                          .map(_buildPlaceCard)
                          .toList(),
                    ),

                    const SizedBox(height: 24),
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
