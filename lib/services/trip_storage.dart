// lib/services/trip_storage.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_plan.dart'; // فيه TripPlanModel

class TripStorage {
  static const _key = 'saved_trips';

  /// حفظ خطة جديدة
  static Future<void> savePlan(TripPlanModel plan) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key) ?? [];

    // نحول TripPlanModel إلى JSON String
    saved.add(jsonEncode(plan.toJson()));

    await prefs.setStringList(_key, saved);
  }

  /// استرجاع جميع الخطط
  static Future<List<TripPlanModel>> loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key) ?? [];

    return saved
        .map(
          (s) => TripPlanModel.fromJson(
            jsonDecode(s) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// حذف جميع الخطط
  static Future<void> clearPlans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
