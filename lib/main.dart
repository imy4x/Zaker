import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:zaker/providers/theme_provider.dart';
import 'package:zaker/constants/app_theme_enhanced.dart';
import 'package:zaker/providers/study_provider.dart';
import 'package:zaker/screens/home_screen.dart';
import 'package:zaker/services/usage_service.dart';

void main() async {
  // التأكد من تهيئة Flutter قبل تشغيل أي كود يعتمد عليه
  WidgetsFlutterBinding.ensureInitialized();
  // تهيئة خدمة تتبع الاستخدام
  final usageService = UsageService();
  // تعديل: تم استدعاء الدالة الصحيحة لتهيئة الخدمة
  await usageService.init();

  runApp(
    // استخدام MultiProvider لتوفير جميع الحالات للتطبيق بأكمله
    MultiProvider(
      providers: [
        // توفير حالة مزود المذاكرة مع خدمة تتبع الاستخدام
        ChangeNotifierProvider(create: (_) => StudyProvider(usageService)),
        // توفير حالة مدير الثيم
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const ZakerApp(),
    ),
  );
}

class ZakerApp extends StatelessWidget {
  const ZakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدام Consumer للاستماع إلى تغييرات الثيم وتحديث واجهة التطبيق
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Zaker - ذاكر',
          debugShowCheckedModeBanner: false,

          // إعدادات دعم اللغة العربية والإنجليزية
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', ''), // Arabic
            Locale('en', ''), // English
          ],
          locale: const Locale('ar', ''),

          // فرض اتجاه الواجهة من اليمين لليسار للتطبيق بالكامل
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },

          // تطبيق الثيمات بناءً على اختيار المستخدم
          theme: EnhancedAppTheme.lightTheme,
          darkTheme: EnhancedAppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          home: const HomeScreen(),
        );
      },
    );
  }
}

