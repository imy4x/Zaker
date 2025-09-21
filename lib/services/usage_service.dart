import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// --- ملف معدل بالكامل لتطبيق نظام الحصص اليومية الموحد ---
class UsageService {
  static const _usageKey = 'daily_usage_stats_v4'; // مفتاح جديد لضمان إعادة التعيين
  late SharedPreferences _prefs;

  // --- تعديل: حد يومي موحد لجميع أنواع التحليلات ---
  static const int _dailyLimit = 5;

  // يتم استدعاؤها عند بدء تشغيل التطبيق
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay();
  }

  // دالة ذكية لإعادة تعيين العدادات تلقائياً في بداية كل يوم جديد
  Future<void> _resetIfNewDay() async {
    final stats = getUsageStats();
    final today = _getDateString(DateTime.now());

    if (stats['date'] != today) {
      // إذا كان التاريخ المحفوظ غير تاريخ اليوم، يتم تصفير العداد
      final newStats = {
        'date': today,
        'usage_count': 0,
      };
      await _prefs.setString(_usageKey, jsonEncode(newStats));
    }
  }

  // دالة للتحقق مما إذا كان يمكن للمستخدم إجراء تحليل
  bool canUse() {
    final stats = getUsageStats();
    final currentUsage = stats['usage_count'] as int? ?? 0;
    return currentUsage < _dailyLimit;
  }

  // دالة لتسجيل استخدام جديد بعد نجاح عملية التحليل
  Future<void> recordUsage() async {
    if (canUse()) {
      final stats = getUsageStats();
      stats['usage_count'] = (stats['usage_count'] as int? ?? 0) + 1;
      await _prefs.setString(_usageKey, jsonEncode(stats));
    }
  }

  // دالة للحصول على إحصائيات الاستخدام الحالية من التخزين المحلي
  Map<String, dynamic> getUsageStats() {
    final jsonString = _prefs.getString(_usageKey);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString);
      } catch (e) {
         // In case of corrupted data, return default
      }
    }
    // إرجاع قيمة ابتدائية إذا لم توجد بيانات مخزنة
    return {
      'date': _getDateString(DateTime.now()),
      'usage_count': 0,
    };
  }

  // دالة للحصول على عدد المحاولات المتبقية
  int getRemainingUses() {
    final stats = getUsageStats();
    final currentUsage = stats['usage_count'] as int? ?? 0;
    return _dailyLimit - currentUsage;
  }
  
  // دالة لحساب الوقت المتبقي حتى منتصف الليل (موعد إعادة تعيين الحدود)
  Duration getTimeUntilReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  // دالة مساعدة لتحويل التاريخ إلى نص
  String _getDateString(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }
}
