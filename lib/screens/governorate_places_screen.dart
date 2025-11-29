// lib/screens/governorate_places_screen.dart

import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

import '../models/gov_places.dart';

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

  Future<void> _openInMaps(LatLng loc) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}';

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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

          if (cat != GovPlaceCategory.attraction) {
            _selectedAttractionType = null;
          }
        });
      },
    );
  }

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
                  Wrap(
                    spacing: 8,
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
                            'احجز عبر Booking / Book',
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
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allPlaces =
        widget.places.where((p) => p.govKey == widget.govKey).toList();

    List<GovPlace> visiblePlaces =
        allPlaces.where((p) => p.category == _selectedCategory).toList();

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
                'assets/places/salalah/header.jpg',
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
                      'أشهى المطاعم والمقاهي في ${widget.titleAr}.',
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
