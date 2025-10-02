import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:zaker/providers/study_provider.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<StudyProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceVariant.withOpacity(0.5),
                ],
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Replaced Lottie with a static CircularProgressIndicator
                    // const SizedBox(
                    //   width: 120,
                    //   height: 120,
                    //   child: CircularProgressIndicator(
                    //     strokeWidth: 8,
                    //   ),
                    // ),
                    // const SizedBox(height: 40),
                    Text(
                      'جاري التحليل...',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'يقوم الذكاء الاصطناعي ببناء جلستك الدراسية. قد يستغرق هذا بعض الوقت.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 50),
                    CircularPercentIndicator(
                      radius: 65.0,
                      lineWidth: 13.0,
                      percent: provider.progressValue,
                      center: Text(
                        "${(provider.progressValue * 100).toInt()}%",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      progressColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      circularStrokeCap: CircularStrokeCap.round,
                      animation: false, // Animation disabled
                    ),
                    const SizedBox(height: 24),
                    // Replaced AnimatedSwitcher with a simple Text widget
                    Text(
                      provider.progressMessage,
                      key: ValueKey<String>(provider.progressMessage),
                      style: theme.textTheme.bodyMedium?.copyWith(
                         color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
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

