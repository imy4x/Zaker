import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:zaker/models/quiz_question.dart';

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String languageCode;
  const QuizScreen({super.key, required this.questions, required this.languageCode});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _answered = false;
  final List<QuizQuestion> _correctlyAnsweredQuestions = [];

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _answered = false;
      });
    } else {
      _showResultDialog();
    }
  }

  void _handleAnswer(int index) {
    if (_answered) return;

    final currentQuestion = widget.questions[_currentQuestionIndex];
    setState(() {
      _selectedAnswerIndex = index;
      _answered = true;
      if (index == currentQuestion.correctAnswerIndex) {
        _score++;
        _correctlyAnsweredQuestions.add(currentQuestion);
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if(mounted) _nextQuestion();
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('انتهى الاختبار!'),
        content: Text('نتيجتك هي: $_score / ${widget.questions.length}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // إغلاق النافذة
              Navigator.of(context).pop(_correctlyAnsweredQuestions); 
            },
            child: const Text('العودة'),
          ),
        ],
      ),
    );
  }

  Color _getOptionColor(int index) {
    if (!_answered) return Theme.of(context).colorScheme.surface;
    if (index == widget.questions[_currentQuestionIndex].correctAnswerIndex) return Colors.green.shade50;
    if (index == _selectedAnswerIndex) return Colors.red.shade50;
    return Theme.of(context).colorScheme.surface;
  }

   Border? _getOptionBorder(int index) {
    if (!_answered) return Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3));
    if (index == widget.questions[_currentQuestionIndex].correctAnswerIndex) return Border.all(color: Colors.green.shade600, width: 2);
    if (index == _selectedAnswerIndex) return Border.all(color: Colors.red.shade600, width: 2);
    return Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3));
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[_currentQuestionIndex];
    final textDirection = widget.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(title: const Text('اختبار قصير')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('السؤال ${_currentQuestionIndex + 1} من ${widget.questions.length}'),
              const SizedBox(height: 8),
              LinearPercentIndicator(
                percent: (_currentQuestionIndex + 1) / widget.questions.length,
                lineHeight: 10.0,
                barRadius: const Radius.circular(5),
                progressColor: Theme.of(context).primaryColor,
                backgroundColor: Colors.grey.shade300,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(currentQuestion.question, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22), textAlign: TextAlign.center),
                      const SizedBox(height: 32),
                      ...List.generate(currentQuestion.options.length, (index) {
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: _getOptionBorder(index)!.top,
                          ),
                          color: _getOptionColor(index),
                          child: InkWell(
                            onTap: () => _handleAnswer(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(currentQuestion.options[index], style: Theme.of(context).textTheme.bodyLarge),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
