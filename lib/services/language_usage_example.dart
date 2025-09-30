// هذا ملف توضيحي لكيفية استخدام LanguageService في أجزاء أخرى من التطبيق
// يمكنك حذف هذا الملف بعد تطبيق الأمثلة في التطبيق

import 'package:flutter/material.dart';
import 'package:zaker/services/language_service.dart';

// مثال 1: كيفية استخدام LanguageService في أي Widget
class ExampleWidget extends StatefulWidget {
  @override
  State<ExampleWidget> createState() => _ExampleWidgetState();
}

class _ExampleWidgetState extends State<ExampleWidget> {
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    // إضافة مستمع لتغييرات اللغة
    _languageService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    // إزالة المستمع لتجنب memory leaks
    _languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged(String newLanguage) {
    // تحديث الواجهة عند تغيير اللغة
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          // استخدام getText للحصول على النص المناسب
          _languageService.getText(
            ar: 'البطاقات التعليمية',
            en: 'Flashcards',
          ),
        ),
        actions: [
          // زر تبديل اللغة
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () async {
              await _languageService.toggleLanguage();
            },
          ),
        ],
      ),
      // تحديد اتجاه النص حسب اللغة
      body: Directionality(
        textDirection: _languageService.isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          children: [
            // مثال على الحصول على النص المترجم
            Text(
              _languageService.getText(
                ar: 'مرحباً بك في التطبيق',
                en: 'Welcome to the app',
              ),
              style: TextStyle(fontSize: 18),
            ),
            
            // مثال على استخدام الخصائص المساعدة
            if (_languageService.isArabic) 
              Text('هذا النص يظهر فقط في العربية'),
            
            if (_languageService.isEnglish)
              Text('This text shows only in English'),
              
            // زر لتغيير اللغة مع نص مترجم
            ElevatedButton(
              onPressed: () async {
                await _languageService.toggleLanguage();
              },
              child: Text(
                _languageService.getText(
                  ar: _languageService.isArabic ? 'تغيير إلى الإنجليزية' : 'تغيير إلى العربية',
                  en: _languageService.isEnglish ? 'Switch to Arabic' : 'Switch to English',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// مثال 2: كيفية تهيئة الخدمة في main.dart
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة خدمة اللغة
  await LanguageService().initialize();
  
  runApp(MyApp());
}
*/

// مثال 3: كيفية استخدام الخدمة في الدوال العادية (بدون Widgets)
class LanguageUtils {
  static String getFormattedText() {
    final languageService = LanguageService();
    return languageService.getText(
      ar: 'النص باللغة العربية',
      en: 'Text in English',
    );
  }
  
  static bool isCurrentLanguageArabic() {
    return LanguageService().isArabic;
  }
}

// مثال 4: Widget مبسط للتبديل بين اللغات (يمكن استخدامه في أي مكان)
class LanguageToggleButton extends StatefulWidget {
  @override
  State<LanguageToggleButton> createState() => _LanguageToggleButtonState();
}

class _LanguageToggleButtonState extends State<LanguageToggleButton> {
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged(String newLanguage) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await _languageService.toggleLanguage();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate, size: 16),
            SizedBox(width: 4),
            Text(
              _languageService.isArabic ? 'EN' : 'عر',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// ملاحظات مهمة:
// 1. تأكد من استدعاء initialize() في main.dart
// 2. تذكر إضافة وإزالة المستمعين لتجنب memory leaks  
// 3. استخدم getText() للحصول على النصوص المترجمة
// 4. استخدم isRTL لتحديد اتجاه النص
// 5. الخدمة تحفظ التفضيل تلقائياً في SharedPreferences