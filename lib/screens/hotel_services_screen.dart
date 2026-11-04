import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/trip_hotel_item.dart';

import 'your_trip_screen.dart';

import 'map_gmaps_screen.dart' show kTripPlans;

class HotelServicesScreen extends StatefulWidget {
  final bool isArabic;

  final bool isGuest;

  const HotelServicesScreen({
    super.key,
    required this.isArabic,
    this.isGuest = false,
  });

  @override
  State<HotelServicesScreen> createState() => _HotelServicesScreenState();
}

class _HotelServicesScreenState extends State<HotelServicesScreen> {
  String selectedCity = "all";

  final cities = {
    "all": {"ar": "كل المحافظات", "en": "All Regions"},
    "Muscat": {"ar": "مسقط", "en": "Muscat"},
    "Dhofar": {"ar": "ظفار", "en": "Dhofar"},
    "SouthSharqiyah": {"ar": "الشرقية الجنوبية", "en": "South Sharqiyah"},
  };

  List<TripHotelItem> get filteredHotels {
    if (selectedCity == "all") return kHotelsList;

    return kHotelsList.where((h) => h.cityKey == selectedCity).toList();
  }

  void _showGuestDialog() {
    final isAr = widget.isArabic;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAr ? 'تسجيل الدخول مطلوب' : 'Login required',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        content: Text(
          isAr
              ? 'لإضافة الفنادق إلى رحلتك أو المفضلة أو فتح الموقع، الرجاء تسجيل الدخول أو إنشاء حساب جديد.'
              : 'To add hotels to your trip or favorites, or open location, please sign in or create an account.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);

              Navigator.pushNamed(context, '/login');
            },
            child: Text(
              isAr ? 'تسجيل الدخول' : 'Sign in',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);

              Navigator.pushNamed(context, '/signup');
            },
            child: Text(
              isAr ? 'إنشاء حساب' : 'Create account',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAr ? "أماكن الإقامة" : "Stays",
          style: const TextStyle(fontFamily: "Tajawal"),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHero(
            isAr ? "استكشفي أفضل الفنادق" : "Discover the best stays",
            isAr
                ? "اختاري مكان الإقامة المثالي واحجزي عبر المواقع الرسمية."
                : "Choose your perfect stay and book via official websites.",
          ),
          const SizedBox(height: 20),
          Text(
            isAr ? "الفلترة حسب المحافظة:" : "Filter by region:",
            style: const TextStyle(
              fontFamily: "Tajawal",
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedCity,
            items: cities.entries.map((c) {
              return DropdownMenuItem(
                value: c.key,
                child: Text(isAr ? c.value["ar"]! : c.value["en"]!),
              );
            }).toList(),
            onChanged: (val) => setState(() => selectedCity = val!),
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isAr ? "أفضل الخيارات" : "Top stays",
            style: const TextStyle(
              fontFamily: "Tajawal",
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          ...filteredHotels.map((h) => _hotelCard(context, h)).toList(),
        ],
      ),
    );
  }

  Widget _buildHero(String title, String sub) {
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              "assets/hotels/hero.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: "Tajawal",
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontFamily: "Tajawal",
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hotelCard(BuildContext context, TripHotelItem h) {
    final isAr = widget.isArabic;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.asset(
              h.imgAsset,
              height: 170,
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
                  isAr ? h.nameAr : h.nameEn,
                  style: const TextStyle(
                    fontFamily: "Tajawal",
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr ? h.descAr : h.descEn,
                  style: const TextStyle(fontFamily: "Tajawal", fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr ? "السعر: ${h.priceAr}" : "Price: ${h.priceEn}",
                  style: const TextStyle(
                    fontFamily: "Tajawal",
                    fontSize: 13,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        h.isFav ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        if (widget.isGuest) {
                          _showGuestDialog();

                          return;
                        }

                        setState(() => h.isFav = !h.isFav);

                        Navigator.pushNamed(context, '/favorites');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.location_pin, color: Colors.blue),
                      onPressed: () {
                        if (widget.isGuest) {
                          _showGuestDialog();

                          return;
                        }

                        _openInMaps(h.lat, h.lng);
                      },
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        isAr ? "أضف لرحلتي" : "Add to trip",
                        style: const TextStyle(fontFamily: "Tajawal"),
                      ),
                      onPressed: () {
                        if (widget.isGuest) {
                          _showGuestDialog();

                          return;
                        }

                        if (!kTripHotels.contains(h)) {
                          kTripHotels.add(h);
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => YourTripScreen(plans: kTripPlans),
                          ),
                        );
                      },
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

  // OPEN MAPS

  Future<void> _openInMaps(double lat, double lng) async {
    final url =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
