import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:zaker/providers/study_provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

// واجهة جديدة لعرض شاشة التحميل المطورة
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyProvider>(
      builder: (context, provider, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/processing.json', // يمكن استخدام انيميشن مختلف
              width: 250,
              height: 250,
              errorBuilder: (c, e, s) => const CircularProgressIndicator(),
            ),
            const SizedBox(height: 20),
            Text(
              'جاري تحليل المستند...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: LinearPercentIndicator(
                percent: provider.progressValue,
                lineHeight: 12.0,
                barRadius: const Radius.circular(6),
                backgroundColor: Colors.grey.shade300,
                progressColor: Colors.indigo,
                animation: true,
                animationDuration: 300,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              provider.progressMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      },
    );
  }
}
