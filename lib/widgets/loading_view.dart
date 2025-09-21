import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:zaker/providers/study_provider.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<StudyProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- تعديل: تحديد حجم الأنميشن بشكل آمن لتجنب الأخطاء ---
                    // SizedBox(
                    //   width: 200,
                    //   height: 200,
                    //   child: Lottie.asset(
                    //     'assets/animations/processing.json',
                    //     fit: BoxFit.contain,
                    //   ),
                    // ),
                    const SizedBox(height: 30),
                    Text(
                      'لحظات من فضلك...',
                      style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'يقوم الذكاء الاصطناعي بتحليل المستند وإعداد مواد المذاكرة لك.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 40),
                    LinearPercentIndicator(
                      percent: provider.progressValue,
                      lineHeight: 12.0,
                      barRadius: const Radius.circular(6),
                      backgroundColor: Colors.grey.shade300,
                      progressColor: theme.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.progressMessage,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Chip(
                      label: Text(
                        'يتم استخدام المفتاح رقم ${provider.currentApiKeyIndex + 1}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryColor),
                      ),
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      side: BorderSide.none,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
