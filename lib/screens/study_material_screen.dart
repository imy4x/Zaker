import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:zaker/models/quiz_question.dart';
import 'package:zaker/models/study_session.dart';
import 'package:zaker/providers/study_provider.dart';
import 'package:zaker/screens/quiz_screen.dart';
import 'package:zaker/widgets/flashcard_widget.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class StudyMaterialScreen extends StatelessWidget {
  final StudySession session;
  final int slotIndex;
  const StudyMaterialScreen({super.key, required this.session, required this.slotIndex});

  void _startQuiz(BuildContext context, int questionCount) async {
    final allQuestions = session.quizQuestions;
    if (allQuestions.length < questionCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يوجد عدد كافٍ من الأسئلة ($questionCount)')),
      );
      return;
    }
    
    final shuffledQuestions = List<QuizQuestion>.from(allQuestions)..shuffle();
    final selectedQuestions = shuffledQuestions.take(questionCount).toList();

    final questionsWithShuffledOptions = selectedQuestions.map((q) {
      final correctAnswerText = q.options[q.correctAnswerIndex];
      final shuffledOptions = List<String>.from(q.options)..shuffle();
      final newCorrectIndex = shuffledOptions.indexOf(correctAnswerText);
      return QuizQuestion(
        question: q.question,
        options: shuffledOptions,
        correctAnswerIndex: newCorrectIndex,
      );
    }).toList();

    // --- استقبال النتيجة بعد انتهاء الاختبار ---
    final score = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          questions: questionsWithShuffledOptions,
          languageCode: session.languageCode,
        ),
      ),
    );

    // --- تحديث سجل الاختبارات في حالة وجود نتيجة ---
    if (score != null && context.mounted) {
      final provider = Provider.of<StudyProvider>(context, listen: false);
      await provider.updateQuizHistory(slotIndex, score, questionCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableQuizOptions = [5, 10, 20]
        .where((count) => session.quizQuestions.length >= count)
        .toList();

    // --- تحديد اتجاه الواجهة بناءً على لغة الجلسة ---
    final textDirection = session.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(session.title, overflow: TextOverflow.ellipsis),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.of(context).pop(),
            ),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.summarize_outlined), text: 'ملخص'),
                Tab(icon: Icon(Icons.style_outlined), text: 'بطاقات'),
                Tab(icon: Icon(Icons.quiz_outlined), text: 'اختبار'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: MarkdownBody(
                      data: session.summary,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7, fontSize: 16.5),
                        h1: Theme.of(context).textTheme.titleLarge,
                        h2: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FlashcardWidget(flashcards: session.flashcards),
              ),

              // --- تبويب الاختبار المحدث بالكامل ---
              Consumer<StudyProvider>(
                builder: (context, provider, child) {
                  final currentSession = provider.sessions[slotIndex]!;
                  final totalAnswered = currentSession.totalQuestionsAnswered;
                  final totalCorrect = currentSession.totalCorrectAnswers;
                  final cumulativePercentage = totalAnswered > 0 ? totalCorrect / totalAnswered : 0.0;

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.school_outlined, size: 80, color: Colors.indigo),
                          const SizedBox(height: 12),
                          Text('اختبر فهمك للمادة', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 24),

                          // --- قسم مؤشر الفهم التراكمي ---
                          if (totalAnswered > 0) ...[
                            Text('مستوى فهمك التراكمي', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            LinearPercentIndicator(
                              percent: cumulativePercentage,
                              lineHeight: 18.0,
                              barRadius: const Radius.circular(9),
                              backgroundColor: Colors.grey.shade300,
                              progressColor: Colors.green,
                              center: Text(
                                '${(cumulativePercentage * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('تمت الإجابة على $totalAnswered سؤال بإجمالي دقة ${(cumulativePercentage * 100).toStringAsFixed(0)}%'),
                            const Divider(height: 40),
                          ],

                          Text('ابدأ اختباراً جديداً', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('اختر عدد الأسئلة', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          if (availableQuizOptions.isEmpty)
                            const Text('لم يتم إنشاء أسئلة لهذه المادة.')
                          else
                            Wrap(
                              spacing: 12.0,
                              runSpacing: 12.0,
                              alignment: WrapAlignment.center,
                              children: availableQuizOptions.map((count) {
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo.withOpacity(0.1),
                                    foregroundColor: Colors.indigo,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                    textStyle: const TextStyle(fontSize: 16, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () => _startQuiz(context, count),
                                  child: Text('$count أسئلة'),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}