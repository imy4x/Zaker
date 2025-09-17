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

    setState(() {
      _selectedAnswerIndex = index;
      _answered = true;
      if (index == widget.questions[_currentQuestionIndex].correctAnswerIndex) {
        _score++;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if(mounted) {
        _nextQuestion();
      }
    });
  }

  void _showResultDialog() {
    final double percentage = widget.questions.isNotEmpty ? _score / widget.questions.length : 0.0;
    String understandingLevel;
    Color progressColor;

    if (percentage >= 0.9) {
      understandingLevel = 'فهم ممتاز! أنت مستعد تماماً.';
      progressColor = Colors.green;
    } else if (percentage >= 0.7) {
      understandingLevel = 'جيد جداً، استمر في المراجعة.';
      progressColor = Colors.lightGreen;
    } else if (percentage >= 0.5) {
      understandingLevel = 'تحتاج إلى مراجعة بسيطة لبعض النقاط.';
      progressColor = Colors.orange;
    } else {
      understandingLevel = 'ننصحك بإعادة مراجعة المادة.';
      progressColor = Colors.red;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('انتهى الاختبار!'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('نتيجتك هي:', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 10),
              Text(
                '$_score / ${widget.questions.length}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 32, color: Colors.indigo),
              ),
              const SizedBox(height: 20),
              Text('مستوى فهمك في هذا الاختبار:', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
              LinearPercentIndicator(
                percent: percentage,
                lineHeight: 15.0,
                barRadius: const Radius.circular(7.5),
                backgroundColor: Colors.grey.shade300,
                progressColor: progressColor,
                center: Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                animation: true,
              ),
              const SizedBox(height: 15),
              Text(
                understandingLevel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: progressColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(_score); // Go back from quiz screen and return score
            },
            child: const Text('العودة'),
          ),
        ],
      ),
    );
  }

  Color _getOptionColor(int index) {
    if (!_answered) {
      return Colors.grey.shade200;
    }
    if (index == widget.questions[_currentQuestionIndex].correctAnswerIndex) {
      return Colors.green.shade100;
    }
    if (index == _selectedAnswerIndex) {
      return Colors.red.shade100;
    }
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[_currentQuestionIndex];
    final textDirection = widget.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اختبار قصير'),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'السؤال ${_currentQuestionIndex + 1} من ${widget.questions.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              LinearPercentIndicator(
                percent: (_currentQuestionIndex + 1) / widget.questions.length,
                lineHeight: 10.0,
                barRadius: const Radius.circular(5),
                backgroundColor: Colors.grey.shade300,
                progressColor: Colors.indigo,
              ),
              const SizedBox(height: 24),
              Text(
                currentQuestion.question,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ...List.generate(currentQuestion.options.length, (index) {
                return Card(
                  color: _getOptionColor(index),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _handleAnswer(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentQuestion.options[index],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            _answered
                                ? (index == currentQuestion.correctAnswerIndex
                                    ? Icons.check_circle
                                    : (index == _selectedAnswerIndex ? Icons.cancel : Icons.radio_button_off))
                                : Icons.radio_button_off,
                            color: _getOptionColor(index) == Colors.grey.shade200
                                ? Colors.grey
                                : (index == currentQuestion.correctAnswerIndex ? Colors.green : Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
