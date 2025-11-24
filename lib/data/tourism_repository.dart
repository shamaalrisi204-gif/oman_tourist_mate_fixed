import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ai_place_suggestion.dart';

class TourismRepository {
  TourismRepository._();
  static final I = TourismRepository._();

  final _accommodationsRef =
      FirebaseFirestore.instance.collection('accommodations');

  final _attractionsRef = FirebaseFirestore.instance.collection('attractions');

  // 🔍 بحث فنادق حسب المدينة
  Future<List<Map<String, dynamic>>> searchAccommodations({
    String? city,
  }) async {
    Query<Map<String, dynamic>> q = _accommodationsRef;

    if (city != null && city.isNotEmpty) {
      q = q.where('city', isEqualTo: city);
    }

    final snap = await q.get();

    // نرجّع البيانات + id
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  // 🔍 أماكن سياحية حسب المحافظة أو المدينة أو النوع (شاطئ، مطعم، ... إلخ)
  Future<List<Map<String, dynamic>>> searchAttractions({
    String? governorate,
    String? type,
  }) async {
    Query<Map<String, dynamic>> q = _attractionsRef;

    if (governorate != null && governorate.isNotEmpty) {
      q = q.where('governorate', isEqualTo: governorate);
    }

    if (type != null && type.isNotEmpty) {
      q = q.where('type', isEqualTo: type);
    }

    final snap = await q.get();

    // نرجّع البيانات + id
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  /// 🔹 دالة عامة يستخدمها الـ AI Concierge
  /// ترجع قائمة AiPlaceSuggestion جاهزة للكروت
  Future<List<AiPlaceSuggestion>> conciergeSearchPlaces({
    required String
        placeType, // 'lodging' أو 'restaurant' أو 'tourist_attraction'
    String? city,
  }) async {
    // فنادق
    if (placeType == 'lodging') {
      final rows = await searchAccommodations(city: city);
      return rows
          .map((m) => AiPlaceSuggestion.fromMap(
                m,
                source: 'accommodations',
              ))
          .toList();
    }

    // مطاعم: نعتبرها نوع داخل attractions
    if (placeType == 'restaurant') {
      final rows = await searchAttractions(
        governorate: city,
        type: 'restaurant',
      );
      return rows
          .map((m) => AiPlaceSuggestion.fromMap(
                m,
                source: 'attractions',
              ))
          .toList();
    }

    // أماكن سياحية عامة
    final rows = await searchAttractions(
      governorate: city,
    );
    return rows
        .map((m) => AiPlaceSuggestion.fromMap(
              m,
              source: 'attractions',
            ))
        .toList();
  }
}
