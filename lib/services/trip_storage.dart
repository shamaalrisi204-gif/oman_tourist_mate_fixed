// lib/services/trip_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_plan.dart';

class TripStorage {
  static const _key = 'saved_trips';
  // حفظ خطة جديدة
  static Future<void> savePlan(TripPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key) ?? [];
    saved.add(jsonEncode(plan.toJson()));
    await prefs.setStringList(_key, saved);
  }

  // استرجاع جميع الخطط
  static Future<List<TripPlan>> loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key) ?? [];
    return saved.map((s) => TripPlan.fromJson(jsonDecode(s))).toList();
  }

  // حذف جميع الخطط
  static Future<void> clearPlans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
