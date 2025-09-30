import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zaker/constants/api_keys.dart';
import 'package:zaker/constants/app_theme_enhanced.dart';
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

        // --- تعديل: فرض اتجاه الواجهة من اليمين لليسار للتطبيق بالكامل ---
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },

        theme: EnhancedAppTheme.lightTheme,

        home: const HomeScreen(),
      ),
    );
  }
}
