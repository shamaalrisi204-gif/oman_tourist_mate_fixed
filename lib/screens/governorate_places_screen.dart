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
  /// التصنيف الرئيسي المختار (أماكن سياحية / فنادق / مطاعم / كوفيهات)

  GovPlaceCategory _selectedCategory = GovPlaceCategory.attraction;

  /// الفلتر الحالي داخل الأماكن السياحية (null = الكل)

  AttractionType? _selectedAttractionType;

  // ---------- نصوص المساعدة ----------

  String _categoryTitleAr(GovPlaceCategory c) {
    switch (c) {
      case GovPlaceCategory.attraction:
        return 'أماكن سياحية';

      case GovPlaceCategory.hotel:
        return 'فنادق';

      case GovPlaceCategory.restaurant:
        return 'مطاعم';

      case GovPlaceCategory.cafe:
        return 'كوفيهات';
    }
  }

  String _categoryTitleEn(GovPlaceCategory c) {
    switch (c) {
      case GovPlaceCategory.attraction:
        return 'Attractions';

      case GovPlaceCategory.hotel:
        return 'Hotels';

      case GovPlaceCategory.restaurant:
        return 'Restaurants';

      case GovPlaceCategory.cafe:
        return 'Cafés';
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

  // ---------- فتح الخرائط / الروابط ----------

  Future<void> _openInMaps(LatLng loc) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}';

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ---------- Widgets مساعدة ----------

  /// Chip لاختيار التصنيف الرئيسي (سياحي / فندق / مطعم / كوفي)

  Widget _buildCategoryChip(GovPlaceCategory cat) {
    final bool selected = _selectedCategory == cat;

    return ChoiceChip(
      label: Text(
        '${_categoryTitleAr(cat)} / ${_categoryTitleEn(cat)}',
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
          _selectedCategory = cat;

          // إذا تغيّر التصنيف عن الأماكن السياحية نحذف فلتر الأنواع

          if (cat != GovPlaceCategory.attraction) {
            _selectedAttractionType = null;
          }
        });
      },
    );
  }

  /// Chip لنوع المكان السياحي (بحري / تاريخي / جبلي / برية)

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
        });
      },
    );
  }

  /// بطاقة المكان (تستخدم لكل التصنيفات)

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

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    // الأماكن الخاصة بهذه المحافظة

    final allPlaces =
        widget.places.where((p) => p.govKey == widget.govKey).toList();

    // نفلتر حسب التصنيف الرئيسي

    List<GovPlace> visiblePlaces =
        allPlaces.where((p) => p.category == _selectedCategory).toList();

    // ولو كانت أماكن سياحية نطبّق فلتر الأنواع

    if (_selectedCategory == GovPlaceCategory.attraction &&
        _selectedAttractionType != null) {
      visiblePlaces = visiblePlaces
          .where((p) => p.attractionType == _selectedAttractionType)
          .toList();
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
              '${widget.titleAr} / ${widget.titleEn}',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: allPlaces.isNotEmpty
                  ? Image.asset(
                      allPlaces.first.imageAsset,
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
                  // 👇 عنوان واضح بدل النص فوق الصورة

                  Text(
                    'تقويم الفعاليات والأماكن في ${widget.titleAr}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Events & Places Calendar in ${widget.titleEn}',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'استعرض الأماكن البحرية، الجبلية، التاريخية، إلى جانب الفنادق والمطاعم والكوفيهات المميزة في المحافظة.',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 تصنيفات رئيسية: سياحية / فنادق / مطاعم / كوفيهات

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip(GovPlaceCategory.attraction),
                        const SizedBox(width: 8),
                        _buildCategoryChip(GovPlaceCategory.hotel),
                        const SizedBox(width: 8),
                        _buildCategoryChip(GovPlaceCategory.restaurant),
                        const SizedBox(width: 8),
                        _buildCategoryChip(GovPlaceCategory.cafe),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // عنوان القسم الحالي

                  Text(
                    '${_categoryTitleAr(_selectedCategory)} / ${_categoryTitleEn(_selectedCategory)}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // وصف بسيط حسب التصنيف

                  Text(
                    () {
                      switch (_selectedCategory) {
                        case GovPlaceCategory.attraction:
                          return 'تعرّف على أجمل الأماكن السياحية في ${widget.titleAr}.';

                        case GovPlaceCategory.hotel:
                          return 'اكتشفي أفضل خيارات الإقامة في ${widget.titleAr}.';

                        case GovPlaceCategory.restaurant:
                          return 'تذوّقي أشهى الأطباق في مطاعم ${widget.titleAr}.';

                        case GovPlaceCategory.cafe:
                          return 'استمتعي بأجواء الكوفيهات المميزة في ${widget.titleAr}.';
                      }
                    }(),
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // لو التصنيف "أماكن سياحية" نعرض فلاتر الأنواع

                  if (_selectedCategory == GovPlaceCategory.attraction) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTypeChip(null),
                          const SizedBox(width: 8),
                          _buildTypeChip(AttractionType.beach),
                          const SizedBox(width: 8),
                          _buildTypeChip(AttractionType.historic),
                          const SizedBox(width: 8),
                          _buildTypeChip(AttractionType.mountain),
                          const SizedBox(width: 8),
                          _buildTypeChip(AttractionType.desert),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // قائمة الأماكن حسب الفلاتر

                  if (visiblePlaces.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'لا توجد أماكن متاحة لهذا التصنيف حاليًا.',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: visiblePlaces.map(_buildPlaceCard).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
