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

  // نتأكد إننا نحمّل CSV مرة وحدة بس

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    // حمّل ملفات CSV من assets

    final accCsv =
        await rootBundle.loadString('assets/data/accommodations.csv');

    final attCsv = await rootBundle.loadString('assets/data/attractions.csv');

    _accommodations = _parseCsv(accCsv);

    _attractions = _parseCsv(attCsv);

    _initialized = true;
  }

  // نحول CSV -> List<Map<String, dynamic>>

  List<Map<String, dynamic>> _parseCsv(String csv) {
    final converter = const CsvToListConverter(eol: '\n');

    final rows = converter.convert(csv);

    if (rows.isEmpty) return [];

    final headers = rows.first.map((e) => e.toString()).toList();

    return rows.skip(1).where((row) => row.isNotEmpty).map((row) {
      final map = <String, dynamic>{};

      for (int i = 0; i < headers.length && i < row.length; i++) {
        map[headers[i]] = row[i];
      }

      // نخزّن category أيضاً في حقل type علشان AiPlaceSuggestion يستخدمه

      if (!map.containsKey('type') && map['category'] != null) {
        map['type'] = map['category'];
      }

      return map;
    }).toList();
  }

  // -------------------------------------------------------------

  // 1) البحث عن فنادق / منتجعات من accommodations.csv

  //    city مثل Muscat, Salalah...

  //    category مثل "hotel" أو "resort" (تقدر تتركيها null عشان يرجّع الكل)

  // -------------------------------------------------------------

  Future<List<AiPlaceSuggestion>> searchAccommodations({
    String? city,
    String? category,
  }) async {
    await _ensureInitialized();

    bool matchesCity(Map<String, dynamic> row) {
      if (city == null || city.isEmpty) return true;

      final c = row['city']?.toString().toLowerCase() ?? '';

      return c.contains(city.toLowerCase());
    }

    bool matchesCategory(Map<String, dynamic> row) {
      if (category == null || category.isEmpty) return true;

      final cat =
          (row['category'] ?? row['type'] ?? '').toString().toLowerCase();

      return cat.contains(category.toLowerCase());
    }

    final data = _accommodations.where((row) {
      return matchesCity(row) && matchesCategory(row);
    }).toList();

    return data
        .map((row) => AiPlaceSuggestion.fromMap(row, source: "accommodations"))
        .toList();
  }

  // -------------------------------------------------------------

  // 2) البحث عن أماكن سياحية من attractions.csv

  // -------------------------------------------------------------

  Future<List<AiPlaceSuggestion>> searchAttractions({
    String? city,
  }) async {
    await _ensureInitialized();

    final data = _attractions.where((row) {
      if (city == null || city.isEmpty) return true;

      final c = row['city']?.toString().toLowerCase() ?? '';

      return c.contains(city.toLowerCase());
    }).toList();

    return data
        .map((row) => AiPlaceSuggestion.fromMap(row, source: "attractions"))
        .toList();
  }
}
