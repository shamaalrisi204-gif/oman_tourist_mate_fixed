import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/create_trip_sheet.dart';
import '../models/gov_places.dart';

import '../models/place_data.dart' show PlaceType;

// نستخدم MapTripPlan و Place و متغيرات الرحلة من شاشة الخريطة
import '../screens/map_gmaps_screen.dart'
    show MapTripPlan, Place, kTripPlans, kTripName, kTripDays, kTripStartDate;

import 'your_trip_screen.dart';

// لو عندك PlaceType وحابة تربطيه اكتبي:
// import '../models/place_data.dart' show PlaceType;

class GovernoratePlacesScreen extends StatefulWidget {
  final String govKey;
  final String titleAr;
  final String titleEn;
  final LatLng? center;
  final List<GovPlace> places;

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
  GovPlaceCategory _selectedCategory = GovPlaceCategory.attraction;
  AttractionType? _selectedAttractionType;

  // ❤️ المفضلة
  final Set<String> _favoritePlaceIds = {};

  // ➕ الأماكن المضافة لرحلتك (نخزن id حق GovPlace نفسه)
  final Set<String> _tripPlaceIds = {};

  bool _isFavorite(GovPlace p) => _favoritePlaceIds.contains(p.id);
  bool _isInTrip(GovPlace p) => _tripPlaceIds.contains(p.id);

  // ======================= مساعدات نصوص =======================

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
        return 'أماكن صحراوية / برية';
    }
  }

  // ======================= فتح الموقع في Google Maps =======================

  Future<void> _openInMaps(LatLng loc) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ======================= BottomSheet اختيار اليوم والمدة =======================

  Widget _buildAddPlaceSheet(
    BuildContext context,
    GovPlace place,
    int initialDay,
    int initialHours,
  ) {
    int day = initialDay;
    int hours = initialHours;

    return StatefulBuilder(
      builder: (ctx, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إضافة ${place.nameAr} إلى الرحلة',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // اختيار اليوم
              Row(
                children: [
                  const Text('اليوم:', style: TextStyle(fontFamily: 'Tajawal')),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: day,
                    items: List.generate(
                      kTripDays,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('اليوم ${index + 1}'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setSheetState(() => day = v);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // اختيار مدة الزيارة
              Row(
                children: [
                  const Text(
                    'المدة (ساعات):',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: hours,
                    items: List.generate(
                      10,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1} ساعة'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setSheetState(() => hours = v);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(
                      {
                        'day': day,
                        'durationHours': hours,
                      },
                    );
                  },
                  child: const Text(
                    'تأكيد الإضافة',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ======================= تحويل GovPlace → Place للخريطة =======================

  Place _toMapPlace(GovPlace p) {
    return Place(
      id: 'gov_${p.id}',
      govKey: p.govKey,
      nameAr: p.nameAr,
      nameEn: p.nameEn,
      imageAsset: p.imageAsset,
      position: p.location,
      // لو عندك PlaceType وتبين تربطيه حسب الفئة تقدري تعدّلي هنا
      type: PlaceType.general, // أو ثبّتي general لو ما تحتاجي تفاصيل
    );
  }

  // ======================= إضافة مكان للرحلة مع BottomSheet =======================

  Future<void> _addPlaceToTripWithSheet(GovPlace govPlace) async {
    // لو ما فيه رحلة أساساً
    if (kTripDays <= 0 || kTripName == null) {
      await showCreateTripSheet(context);
      if (kTripDays <= 0 || kTripName == null) return;
    }

    int selectedDay = 1;
    int durationHours = 2;

    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _buildAddPlaceSheet(ctx, govPlace, selectedDay, durationHours);
      },
    );

    if (result == null) return;

    final day = result['day'] ?? 1;
    final hours = result['durationHours'] ?? 2;

    // 1) حوّل GovPlace إلى Place (حق الخريطة)
    final place = _toMapPlace(govPlace);

    // 2) هنا ما عندنا موقع المستخدم → نخليها 0 حالياً
    final int driveMinutes = 0;

    // 3) أضف المكان للخطة
    setState(() {
      _tripPlaceIds.add(govPlace.id);

      kTripPlans.add(
        MapTripPlan(
          place: place,
          day: day,
          durationHours: hours.toDouble(),
          durationText: '$hours ساعة تقريباً',
          wantHotels: true,
          wantRestaurants: true,
          wantSittings: false,
          createdAt: DateTime.now(),
          driveMinutes: driveMinutes, // 👈 مهم
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تمت إضافة المكان إلى رحلتك ✅',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YourTripScreen(plans: kTripPlans),
      ),
    );
  }

  // ======================= Chips الفئات =======================

  Widget _buildCategoryChip(GovPlaceCategory cat) {
    final selected = _selectedCategory == cat;

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
          if (cat != GovPlaceCategory.attraction) {
            _selectedAttractionType = null;
          }
        });
      },
    );
  }

  Widget _buildTypeChip(AttractionType? type) {
    final selected = _selectedAttractionType == type;

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

  // ======================= كرت المكان =======================

  Widget _buildPlaceCard(GovPlace place) {
    final bool isFav = _isFavorite(place);
    final bool inTrip = _isInTrip(place);

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
            // ================= صورة + زر المفضلة =================
            Stack(
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
                Positioned(
                  top: 10,
                  left: 10,
                  child: Column(
                    children: [
                      // زر المفضلة
                      Material(
                        color: Colors.white.withOpacity(0.9),
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isFav ? Colors.pink : Colors.black87,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isFav) {
                                _favoritePlaceIds.remove(place.id);
                              } else {
                                _favoritePlaceIds.add(place.id);
                              }
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFav
                                      ? 'تمت إزالة المكان من المفضلة'
                                      : 'تمت إضافة المكان إلى المفضلة ❤',
                                  style: const TextStyle(fontFamily: 'Tajawal'),
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ================= النصوص والأزرار السفلية =================

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

                  // أزرار إنستغرام / بوكينغ / خريطة
                  Wrap(
                    spacing: 8,
                    children: [
                      if (place.instagramUrl != null)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(place.instagramUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: const Text(
                            'Instagram',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (place.bookingUrl != null)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(place.bookingUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(Icons.hotel, size: 16),
                          label: const Text(
                            'احجز عبر Booking / Book',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11,
                            ),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _openInMaps(place.location),
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text(
                          'عرض في الخريطة / View on map',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // زر إضافة / إزالة من الرحلة مع الـ BottomSheet
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: () async {
                        if (inTrip) {
                          // إزالة من الرحلة
                          setState(() {
                            _tripPlaceIds.remove(place.id);
                            kTripPlans.removeWhere(
                              (plan) => plan.place.id == 'gov_${place.id}',
                            );
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'تمت إزالة المكان من رحلتك',
                                style: TextStyle(fontFamily: 'Tajawal'),
                              ),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        } else {
                          // إضافة مع اختيار اليوم + المدة
                          await _addPlaceToTripWithSheet(place);
                        }
                      },
                      icon: Icon(inTrip ? Icons.check : Icons.add),
                      label: Text(
                        inTrip ? 'مضاف إلى رحلتي' : 'إضافة إلى رحلتي',
                        style: const TextStyle(fontFamily: 'Tajawal'),
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

  // ======================= build =======================

  @override
  Widget build(BuildContext context) {
    // نرشّح الأماكن حسب المحافظة
    final allPlaces =
        widget.places.where((p) => p.govKey == widget.govKey).toList();

    // ثم حسب التصنيف
    List<GovPlace> visiblePlaces =
        allPlaces.where((p) => p.category == _selectedCategory).toList();

    // ولو كانت أماكن سياحية نفلتر حسب النوع (بحري / تاريخي...)
    if (_selectedCategory == GovPlaceCategory.attraction &&
        _selectedAttractionType != null) {
      visiblePlaces = visiblePlaces
          .where((p) => p.attractionType == _selectedAttractionType)
          .toList();
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            title: Text(
              '${widget.titleAr} / ${widget.titleEn}',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(
                'assets/places/salalah/header.jpg', // عدّليها لو حابة
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    'استعرض أجمل الأماكن البحرية، الجبلية، التاريخية، الفنادق، المطاعم، والكوفيهات في المحافظة.',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // فئات رئيسية
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

                  Text(
                    '${_categoryTitleAr(_selectedCategory)} / ${_categoryTitleEn(_selectedCategory)}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  if (_selectedCategory == GovPlaceCategory.attraction)
                    Text(
                      'اكتشفي أجمل الوجهات في ${widget.titleAr}.',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                      ),
                    )
                  else if (_selectedCategory == GovPlaceCategory.hotel)
                    Text(
                      'أفضل أماكن الإقامة في ${widget.titleAr}.',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                      ),
                    )
                  else if (_selectedCategory == GovPlaceCategory.restaurant)
                    Text(
                      'أشهى المطاعم في ${widget.titleAr}.',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                      ),
                    )
                  else
                    Text(
                      'أفضل الكوفيهات في ${widget.titleAr}.',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // فلتر أنواع الأماكن السياحية
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
                  ],

                  const SizedBox(height: 16),

                  // قائمة الأماكن
                  visiblePlaces.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'لا توجد أماكن متاحة لهذا التصنيف.',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : Column(
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
