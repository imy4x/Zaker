import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zaker/models/quiz_question.dart';
import 'package:zaker/providers/study_provider.dart';
import 'package:zaker/models/study_session.dart';
import 'package:zaker/screens/quiz_screen.dart';
import 'package:zaker/widgets/flashcard_widget.dart';
import 'package:zaker/widgets/enhanced_summary_widget.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class StudyMaterialScreen extends StatelessWidget {
  final StudySession session;
  const StudyMaterialScreen({super.key, required this.session});

  void _startQuiz(BuildContext context, int questionCount) async {
    final provider = Provider.of<StudyProvider>(context, listen: false);
    final currentSessionState =
        provider.sessions.firstWhere((s) => s.id == session.id);

    final availableQuestions = currentSessionState.quizQuestions
        .where((q) =>
            !currentSessionState.correctlyAnsweredQuestions.contains(q.question))
        .toList();

    if (availableQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لقد أجبت على جميع الأسئلة بنجاح!')),
      );
      return;
    }

    final questionsToTake = questionCount > availableQuestions.length
        ? availableQuestions.length
        : questionCount;

    final shuffledQuestions = List<QuizQuestion>.from(availableQuestions)
      ..shuffle();
    final selectedQuestions = shuffledQuestions.take(questionsToTake).toList();

    final questionsWithShuffledOptions = selectedQuestions.map((q) {
      final correctAnswerText = q.options[q.correctAnswerIndex];
      final shuffledOptions = List<String>.from(q.options)..shuffle();
      final newCorrectIndex = shuffledOptions.indexOf(correctAnswerText);
      return QuizQuestion(
          question: q.question,
          options: shuffledOptions,
          correctAnswerIndex: newCorrectIndex,
          difficulty: q.difficulty);
    }).toList();

    final correctAnswers = await Navigator.push<List<QuizQuestion>>(
      context,
      MaterialPageRoute(
          builder: (context) => QuizScreen(
              questions: questionsWithShuffledOptions,
              languageCode: session.languageCode)),
    );

    if (correctAnswers != null && context.mounted) {
      await provider.recordQuizResult(session.id, correctAnswers);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textDirection =
        session.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
    final theme = Theme.of(context);

    return Directionality(
      textDirection: textDirection,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(session.title, overflow: TextOverflow.ellipsis),
            bottom: const TabBar(tabs: [
              Tab(text: 'الملخص'),
              Tab(text: 'البطاقات'),
              Tab(text: 'الاختبار'),
            ]),
          ),
          body: TabBarView(
            children: [
              EnhancedSummaryWidget(summary: session.summary),

              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: FlashcardWidget(flashcards: session.flashcards)),

              _buildQuizTab(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizTab(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<StudyProvider>(
      builder: (context, provider, child) {
        final currentSession = provider.sessions.firstWhere((s) => s.id == session.id);
        final totalGenerated = currentSession.quizQuestions.length;
        final totalUniqueCorrect = currentSession.correctlyAnsweredQuestions.length;
        final progressPercentage = totalGenerated > 0 ? totalUniqueCorrect / totalGenerated : 0.0;
        
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined,
                    size: 80, color: theme.primaryColor),
                const SizedBox(height: 16),
                Text('اختبر فهمك للمادة',
                    style: theme.textTheme.displayLarge
                        ?.copyWith(fontSize: 24)),
                const SizedBox(height: 8),
                Text(
                  'ستظهر لك أسئلة متنوعة الصعوبة بشكل عشوائي.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // --- تعديل: تحسين مظهر شريط التقدم وتوسيط النص ---
                if (totalGenerated > 0)
                  LinearPercentIndicator(
                    percent: progressPercentage,
                    lineHeight: 14.0, // زيادة الارتفاع قليلاً
                    barRadius: const Radius.circular(7),
                    center: Text(
                      '${(progressPercentage * 100).toStringAsFixed(0)}% مكتمل',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      )
                    ),
                    progressColor: Colors.green,
                    backgroundColor: Colors.grey.shade300,
                  ),
                
                const Divider(height: 40),

                Text('ابدأ اختباراً جديداً',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                if (session.quizQuestions.isEmpty)
                  const Text('لم يتم إنشاء أسئلة لهذه المادة.')
                else
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [5, 10, 20]
                        .where((num) => session.quizQuestions.length >= num)
                        .map((num) => ElevatedButton(
                              onPressed: () => _startQuiz(context, num),
                              child: Text('$num أسئلة'),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

