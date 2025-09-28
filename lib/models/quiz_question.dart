import 'package:zaker/constants/app_constants.dart';

class QuizQuestion {
  final String questionAr;
  final List<String> optionsAr;
  final String questionEn;
  final List<String> optionsEn;
  final int correctAnswerIndex;
  final QuizDifficulty difficulty;

  QuizQuestion({
    required this.questionAr,
    required this.optionsAr,
    required this.questionEn,
    required this.optionsEn,
    required this.correctAnswerIndex,
    required this.difficulty,
  });

  // Legacy constructor for backward compatibility
  QuizQuestion.legacy({
    required String question,
    required List<String> options,
    required this.correctAnswerIndex,
    required this.difficulty,
  })  : questionAr = question,
        optionsAr = options,
        questionEn = question, // Fallback to same content
        optionsEn = options;

  // Get content based on language
  String getQuestion(String languageCode) {
    return languageCode == 'en' ? questionEn : questionAr;
  }

  List<String> getOptions(String languageCode) {
    return languageCode == 'en' ? optionsEn : optionsAr;
  }

  // For backward compatibility
  String get question => questionAr;
  List<String> get options => optionsAr;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    QuizDifficulty parseDifficulty(String? diff) {
      switch (diff?.toLowerCase()) {
        case 'easy':
          return QuizDifficulty.easy;
        case 'medium':
          return QuizDifficulty.medium;
        case 'hard':
          return QuizDifficulty.hard;
        case 'very_hard':
          return QuizDifficulty.veryHard;
        default:
          return QuizDifficulty.medium;
      }
    }

    // Handle both new bilingual format and legacy format
    if (json.containsKey('questionAr') && json.containsKey('questionEn')) {
      return QuizQuestion(
        questionAr: json['questionAr'] ?? 'لا يوجد سؤال',
        optionsAr: List<String>.from(json['optionsAr'] ?? []),
        questionEn: json['questionEn'] ?? 'No question',
        optionsEn: List<String>.from(json['optionsEn'] ?? []),
        correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
        difficulty: parseDifficulty(json['difficulty']),
      );
    } else {
      // Legacy format
      return QuizQuestion.legacy(
        question: json['question'] ?? 'لا يوجد سؤال',
        options: List<String>.from(json['options'] ?? []),
        correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
        difficulty: parseDifficulty(json['difficulty']),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'questionAr': questionAr,
      'optionsAr': optionsAr,
      'questionEn': questionEn,
      'optionsEn': optionsEn,
      'correctAnswerIndex': correctAnswerIndex,
      'difficulty': difficulty.toString().split('.').last,
      // Keep legacy fields for backward compatibility
      'question': questionAr,
      'options': optionsAr,
    };
  }
}
