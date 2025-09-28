import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UsageService {
  static const _usageKey = 'daily_usage_stats_v4';
  late SharedPreferences _prefs;

  static const int _dailyLimit = 3;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay();
  }

  Future<void> _resetIfNewDay() async {
    final stats = getUsageStats();
    final today = _getDateString(DateTime.now());

    if (stats['date'] != today) {
      final newStats = {
        'date': today,
        'usage_count': 0,
      };
      await _prefs.setString(_usageKey, jsonEncode(newStats));
    }
  }

  bool canUse({int count = 1}) {
    final stats = getUsageStats();
    final currentUsage = stats['usage_count'] as int? ?? 0;
    return (currentUsage + count) <= _dailyLimit;
  }

  // --- تعديل: الدالة الآن تقبل عدد المحاولات لتسجيلها ---
  Future<void> recordUsage({int count = 1}) async {
    final stats = getUsageStats();
    stats['usage_count'] = (stats['usage_count'] as int? ?? 0) + count;
    await _prefs.setString(_usageKey, jsonEncode(stats));
  }

  Map<String, dynamic> getUsageStats() {
    final jsonString = _prefs.getString(_usageKey);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString);
      } catch (e) {
        // In case of corrupted data, return default
      }
    }
    return {
      'date': _getDateString(DateTime.now()),
      'usage_count': 0,
    };
  }

  int getRemainingUses() {
    final stats = getUsageStats();
    final currentUsage = stats['usage_count'] as int? ?? 0;
    return _dailyLimit - currentUsage;
  }

  Duration getTimeUntilReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  String _getDateString(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }
}
