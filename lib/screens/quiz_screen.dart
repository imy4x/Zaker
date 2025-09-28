import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaker/models/quiz_question.dart';
import 'package:zaker/constants/app_constants.dart';

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String languageCode;
  const QuizScreen(
      {super.key, required this.questions, required this.languageCode});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _answered = false;
  final List<QuizQuestion> _correctlyAnsweredQuestions = [];
  String _currentLanguage = 'ar'; // Default to Arabic
  late AnimationController _languageToggleController;
  late Animation<double> _languageToggleAnimation;
  late AnimationController _questionTransitionController;
  late Animation<Offset> _questionSlideAnimation;
  late Animation<double> _questionFadeAnimation;

  @override
  void initState() {
    super.initState();
    _languageToggleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _languageToggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _languageToggleController,
      curve: Curves.easeInOut,
    ));

    _questionTransitionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _questionSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _questionTransitionController,
      curve: Curves.easeInOut,
    ));
    _questionFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _questionTransitionController,
      curve: Curves.easeInOut,
    ));

    _questionTransitionController.forward();
  }

  @override
  void dispose() {
    try {
      if (_languageToggleController.isAnimating) {
        _languageToggleController.stop();
      }
      _languageToggleController.dispose();

      if (_questionTransitionController.isAnimating) {
        _questionTransitionController.stop();
      }
      _questionTransitionController.dispose();
    } catch (e) {
      // Ignore disposal errors
    }
    super.dispose();
  }

  void _toggleLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'ar' ? 'en' : 'ar';
    });

    if (_currentLanguage == 'en') {
      _languageToggleController.forward();
    } else {
      _languageToggleController.reverse();
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      _questionTransitionController.reset();
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _answered = false;
      });
      _questionTransitionController.forward();
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
      if (mounted) _nextQuestion();
    });
  }

  void _showResultDialog() {
    final isArabic = _currentLanguage == 'ar';
    final percentage = ((_score / widget.questions.length) * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: percentage >= 70
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : percentage >= 50
                      ? [Colors.orange.shade400, Colors.orange.shade600]
                      : [Colors.red.shade400, Colors.red.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                percentage >= 70 ? Icons.celebration : Icons.quiz_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isArabic ? 'انتهى الاختبار!' : 'Quiz Complete!',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    isArabic ? 'نتيجتك' : 'Your Score',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_score / ${widget.questions.length}',
                    style: GoogleFonts.cairo(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: percentage >= 70
                          ? Colors.green.shade600
                          : percentage >= 50
                              ? Colors.orange.shade600
                              : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              percentage >= 70
                  ? (isArabic ? 'أحسنت! نتيجة ممتازة' : 'Excellent! Great job!')
                  : percentage >= 50
                      ? (isArabic
                          ? 'جيد! يمكنك التحسن'
                          : 'Good! You can improve')
                      : (isArabic ? 'حاول مرة أخرى' : 'Try again'),
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(_correctlyAnsweredQuestions);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isArabic ? 'العودة' : 'Back',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getOptionColor(int index) {
    if (!_answered) return Theme.of(context).colorScheme.surface;
    if (index == widget.questions[_currentQuestionIndex].correctAnswerIndex)
      return Colors.green.shade50;
    if (index == _selectedAnswerIndex) return Colors.red.shade50;
    return Theme.of(context).colorScheme.surface;
  }

  Border? _getOptionBorder(int index) {
    if (!_answered)
      return Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3));
    if (index == widget.questions[_currentQuestionIndex].correctAnswerIndex)
      return Border.all(color: Colors.green.shade600, width: 2);
    if (index == _selectedAnswerIndex)
      return Border.all(color: Colors.red.shade600, width: 2);
    return Border.all(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.3));
  }

  Widget _buildDifficultyBadge(QuizDifficulty difficulty) {
    final isArabic = _currentLanguage == 'ar';
    String difficultyText;
    Color difficultyColor;
    IconData difficultyIcon;

    switch (difficulty) {
      case QuizDifficulty.easy:
        difficultyText = isArabic ? 'سهل' : 'Easy';
        difficultyColor = Colors.green;
        difficultyIcon = Icons.sentiment_satisfied_rounded;
        break;
      case QuizDifficulty.medium:
        difficultyText = isArabic ? 'متوسط' : 'Medium';
        difficultyColor = Colors.orange;
        difficultyIcon = Icons.sentiment_neutral_rounded;
        break;
      case QuizDifficulty.hard:
        difficultyText = isArabic ? 'صعب' : 'Hard';
        difficultyColor = Colors.red;
        difficultyIcon = Icons.sentiment_dissatisfied_rounded;
        break;
      case QuizDifficulty.veryHard:
        difficultyText = isArabic ? 'صعب جداً' : 'Very Hard';
        difficultyColor = Colors.purple;
        difficultyIcon = Icons.sentiment_very_dissatisfied_rounded;
        break;
      case QuizDifficulty.mixed:
        difficultyText = isArabic ? 'متنوع' : 'Mixed';
        difficultyColor = Colors.blue;
        difficultyIcon = Icons.shuffle_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            difficultyColor,
            difficultyColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: difficultyColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              difficultyIcon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isArabic
                ? 'مستوى الصعوبة: $difficultyText'
                : 'Difficulty: $difficultyText',
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[_currentQuestionIndex];
    final textDirection =
        _currentLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr;
    final isArabic = _currentLanguage == 'ar';

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          title: Text(
            isArabic ? 'اختبار قصير' : 'Quick Quiz',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
          actions: [
            // Language toggle button
            AnimatedBuilder(
              animation: _languageToggleAnimation,
              builder: (context, child) {
                return GestureDetector(
                  onTap: _toggleLanguage,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: _languageToggleAnimation.value * 3.14159,
                          child: const Icon(
                            Icons.translate_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentLanguage == 'ar' ? 'EN' : 'عر',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Progress Section
                  _buildProgressSection(),

                  const SizedBox(height: 24),

                  // Question Section
                  Expanded(
                    child: SlideTransition(
                      position: _questionSlideAnimation,
                      child: FadeTransition(
                        opacity: _questionFadeAnimation,
                        child: _buildQuestionSection(currentQuestion),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    final isArabic = _currentLanguage == 'ar';
    final progress = (_currentQuestionIndex + 1) / widget.questions.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic
                    ? 'السؤال ${_currentQuestionIndex + 1}'
                    : 'Question ${_currentQuestionIndex + 1}',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isArabic
                      ? 'من ${widget.questions.length}'
                      : 'of ${widget.questions.length}',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearPercentIndicator(
            percent: progress,
            lineHeight: 8.0,
            barRadius: const Radius.circular(4),
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            progressColor: Theme.of(context).colorScheme.primary,
            animation: true,
            animationDuration: 300,
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? '${(progress * 100).toInt()}% من الاختبار مكتمل'
                : '${(progress * 100).toInt()}% Complete',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection(QuizQuestion currentQuestion) {
    final isArabic = _currentLanguage == 'ar';
    final questionText = currentQuestion.getQuestion(_currentLanguage);
    final options = currentQuestion.getOptions(_currentLanguage);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          // Difficulty Level Badge - Centered
          Center(
            child: _buildDifficultyBadge(currentQuestion.difficulty),
          ),

          const SizedBox(height: 24),

          // Question Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.quiz_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isArabic ? 'سؤال' : 'Question',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  questionText,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Options
          ...List.generate(options.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: _buildOptionCard(index, options[index]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int index, String optionText) {
    final isCorrect =
        index == widget.questions[_currentQuestionIndex].correctAnswerIndex;
    final isSelected = index == _selectedAnswerIndex;
    final isAnswered = _answered;

    Color cardColor;
    Color borderColor;
    Color textColor = Theme.of(context).colorScheme.onSurface;
    IconData? icon;

    if (!isAnswered) {
      cardColor = Theme.of(context).colorScheme.surface;
      borderColor = Theme.of(context).colorScheme.outline.withOpacity(0.3);
    } else if (isCorrect) {
      cardColor = Colors.green.shade50;
      borderColor = Colors.green.shade400;
      textColor = Colors.green.shade800;
      icon = Icons.check_circle_rounded;
    } else if (isSelected) {
      cardColor = Colors.red.shade50;
      borderColor = Colors.red.shade400;
      textColor = Colors.red.shade800;
      icon = Icons.cancel_rounded;
    } else {
      cardColor = Theme.of(context).colorScheme.surface.withOpacity(0.5);
      borderColor = Theme.of(context).colorScheme.outline.withOpacity(0.2);
      textColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isAnswered && (isCorrect || isSelected) ? 2 : 1,
        ),
        boxShadow: isAnswered && (isCorrect || isSelected)
            ? [
                BoxShadow(
                  color: borderColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleAnswer(index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isAnswered && (isCorrect || isSelected)
                        ? borderColor
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: icon != null
                        ? Icon(
                            icon,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    optionText,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
