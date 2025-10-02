import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// هذا الكلاس مسؤول عن حفظ وتبديل الثيم (فاتح/داكن)
class ThemeProvider with ChangeNotifier {
  static const _themePrefKey = 'themeMode';
  ThemeMode _themeMode = ThemeMode.system; // الوضع الافتراضي هو وضع النظام

  ThemeProvider() {
    _loadTheme(); // تحميل الثيم المحفوظ عند بدء التشغيل
  }

  // للوصول إلى الوضع الحالي
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // دالة لتبديل الثيم
  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    _saveTheme(); // حفظ الخيار الجديد
    notifyListeners(); // إعلام الواجهات بالتغيير
  }

  // تحميل الثيم من الذاكرة المحلية
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(_themePrefKey);
    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  // حفظ الثيم في الذاكرة المحلية
  void _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (_themeMode == ThemeMode.dark) {
      prefs.setString(_themePrefKey, 'dark');
    } else {
      prefs.setString(_themePrefKey, 'light');
    }
  }
}
