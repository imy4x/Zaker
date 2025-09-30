import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String defaultLanguage = 'ar';
  
  // إنشاء Singleton للخدمة
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();
  
  String _currentLanguage = defaultLanguage;
  final List<Function(String)> _listeners = [];
  
  /// الحصول على اللغة الحالية
  String get currentLanguage => _currentLanguage;
  
  /// تحديد ما إذا كانت اللغة الحالية عربية
  bool get isArabic => _currentLanguage == 'ar';
  
  /// تحديد ما إذا كانت اللغة الحالية إنجليزية
  bool get isEnglish => _currentLanguage == 'en';
  
  /// تهيئة الخدمة واستعادة اللغة المحفوظة
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? defaultLanguage;
  }
  
  /// تغيير اللغة وحفظها
  Future<void> setLanguage(String language) async {
    if (language == _currentLanguage) return;
    
    _currentLanguage = language;
    
    // حفظ في SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
    
    // إشعار جميع المستمعين بالتغيير
    for (final listener in _listeners) {
      listener(_currentLanguage);
    }
  }
  
  /// تبديل اللغة بين العربية والإنجليزية
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguage == 'ar' ? 'en' : 'ar';
    await setLanguage(newLanguage);
  }
  
  /// إضافة مستمع للتغييرات في اللغة
  void addListener(Function(String) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }
  
  /// إزالة مستمع
  void removeListener(Function(String) listener) {
    _listeners.remove(listener);
  }
  
  /// تنظيف جميع المستمعين
  void dispose() {
    _listeners.clear();
  }
  
  /// الحصول على النص المترجم حسب اللغة الحالية
  String getText({required String ar, required String en}) {
    return _currentLanguage == 'ar' ? ar : en;
  }
  
  /// الحصول على اتجاه النص حسب اللغة
  bool get isRTL => _currentLanguage == 'ar';
}