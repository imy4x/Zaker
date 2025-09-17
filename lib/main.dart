import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zaker/constants/api_keys.dart';
import 'package:zaker/providers/study_provider.dart';
import 'package:zaker/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ZakerApp());
}

class ZakerApp extends StatelessWidget {
  const ZakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StudyProvider(),
      child: MaterialApp(
        title: 'Zaker - ذاكر',
        debugShowCheckedModeBanner: false,
        // --- إعدادات دعم اللغة العربية والاتجاه من اليمين لليسار ---
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', ''), // Arabic
          Locale('en', ''), // English
        ],
        locale: const Locale('ar', ''), // تعيين اللغة العربية كلغة افتراضية
        // --- نهاية الإعدادات ---
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          fontFamily: 'Tajawal',
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF5F7FA),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontFamily: 'Tajawal',
              color: Color(0xFF1A252F),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Color(0xFF1A252F)),
          ),
          // --- تحديث ألوان النصوص لتكون أوضح ---
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontFamily: 'Tajawal', fontSize: 16, color: Color(0xFF1A252F)), // لون أغمق
            bodyMedium: TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: Color(0xFF4A5568)), // لون أغمق قليلاً
            titleLarge: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF1A252F)),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
