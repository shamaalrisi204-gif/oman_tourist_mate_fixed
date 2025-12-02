// lib/data/tourism_repository.dart

import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;

import 'package:csv/csv.dart';

import '../models/ai_place_suggestion.dart';

class TourismRepository {
  TourismRepository._();

  static final TourismRepository I = TourismRepository._();

  bool _initialized = false;

  List<Map<String, dynamic>> _accommodations = [];

  List<Map<String, dynamic>> _attractions = [];

  List<Map<String, dynamic>> _restaurants = []; // ✅ المطاعم

  // تحميل CSV مرة وحدة

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final accCsv =
        await rootBundle.loadString('assets/data/accommodations.csv');

    final attCsv = await rootBundle.loadString('assets/data/attractions.csv');

    // ✅ لو عندك ملف المطاعم

    final restCsv = await rootBundle.loadString('assets/data/restaurants.csv');

    _accommodations = _parseCsv(accCsv);

    _attractions = _parseCsv(attCsv);

    _restaurants = _parseCsv(restCsv);

    _initialized = true;
  }

  // تحويل CSV → List<Map<String, dynamic>>

  List<Map<String, dynamic>> _parseCsv(String csv) {
    final converter = const CsvToListConverter(eol: '\n');

    final rows = converter.convert(csv);

    if (rows.isEmpty) return [];

    // أول سطر = العناوين

    final headers = rows.first.map((e) => e.toString()).toList();

    return rows.skip(1).where((row) => row.isNotEmpty).map((row) {
      final map = <String, dynamic>{};

      for (int i = 0; i < headers.length && i < row.length; i++) {
        map[headers[i]] = row[i];
      }

      // نخزّن category في type علشان AiPlaceSuggestion يستخدمها

      if (!map.containsKey('type') && map['category'] != null) {
        map['type'] = map['category'];
      }

      return map;
    }).toList();
  }

  // -----------------------------------------

  // بحث فنادق من accommodations.csv

  // -----------------------------------------

  Future<List<AiPlaceSuggestion>> searchAccommodations({String? city}) async {
    await _ensureInitialized();

    final data = _accommodations.where((row) {
      if (city == null) return true;

      return row['city']
              ?.toString()
              .toLowerCase()
              .contains(city.toLowerCase()) ??
          false;
    }).toList();

    return data
        .map((row) => AiPlaceSuggestion.fromMap(row, source: "accommodations"))
        .toList();
  }

  // -----------------------------------------

  // بحث أماكن سياحية من attractions.csv

  // -----------------------------------------

  Future<List<AiPlaceSuggestion>> searchAttractions({String? city}) async {
    await _ensureInitialized();

    final data = _attractions.where((row) {
      if (city == null) return true;

      return row['city']
              ?.toString()
              .toLowerCase()
              .contains(city.toLowerCase()) ??
          false;
    }).toList();

    return data
        .map((row) => AiPlaceSuggestion.fromMap(row, source: "attractions"))
        .toList();
  }

  // -----------------------------------------

  // بحث مطاعم من restaurants.csv

  // -----------------------------------------

  Future<List<AiPlaceSuggestion>> searchRestaurants({String? city}) async {
    await _ensureInitialized();

    final data = _restaurants.where((row) {
      if (city == null) return true;

      return row['city']
              ?.toString()
              .toLowerCase()
              .contains(city.toLowerCase()) ??
          false;
    }).toList();

    return data
        .map((row) => AiPlaceSuggestion.fromMap(row, source: "restaurants"))
        .toList();
  }

  // -----------------------------------------

  // دالة التخطيط: أماكن سياحية لمدينة + نوع (بحرية، تاريخية...)

  // تستخدمها TripPlannerScreen

  // -----------------------------------------

  Future<List<AiPlaceSuggestion>> getAttractionsForPlanner({
    required String city, // هنا بالعربي مثل اللي في CSV: مسقط، صلالة...

    String? category, // بحرية / تاريخية / ...
  }) async {
    await _ensureInitialized();

    final data = _attractions.where((row) {
      final c = row['city']?.toString() ?? '';

      if (!c.contains(city)) return false;

      if (category != null && category.isNotEmpty) {
        final t = (row['type'] ?? row['category'] ?? '').toString();

        return t.contains(category);
      }

      return true;
    }).toList();

    return data
        .map((row) => AiPlaceSuggestion.fromMap(row, source: "attractions"))
        .toList();
  }

  // -----------------------------------------

  // الدالة التي يستخدمها AI Concierge

  // placeType = lodging | restaurant | tourist_attraction

  // -----------------------------------------

  Future<List<AiPlaceSuggestion>> conciergeSearchPlaces({
    required String placeType,
    String? city,
  }) async {
    await _ensureInitialized();

    List<Map<String, dynamic>> sourceList;

    if (placeType == 'tourist_attraction') {
      sourceList = _attractions;
    } else if (placeType == 'restaurant') {
      sourceList = _restaurants; // ✅ المطاعم من ملف المطاعم
    } else {
      // lodging = فنادق من accommodations

      sourceList = _accommodations;
    }

    final filtered = sourceList.where((row) {
      // فلتر المدينة لو محددة

      if (city != null && city.isNotEmpty) {
        final c = row['city']?.toString().toLowerCase() ?? '';

        if (!c.contains(city.toLowerCase())) return false;
      }

      final type =
          (row['type'] ?? row['category'] ?? '').toString().toLowerCase();

      if (placeType == 'lodging') {
        return type.contains('hotel') ||
            type.contains('resort') ||
            type.contains('فندق') ||
            type.contains('منتجع');
      }

      if (placeType == 'restaurant') {
        // لو في كاتجوري مخصص للمطاعم (مثلاً Restaurant, مطعم)

        return type.contains('restaurant') ||
            type.contains('مطعم') ||
            type.contains('food') ||
            type.contains('cafe') ||
            type.contains('كوفي');
      }

      // tourist_attraction

      return true;
    }).toList();

    return filtered
        .map((row) => AiPlaceSuggestion.fromMap(row, source: placeType))
        .toList();
  }
}
