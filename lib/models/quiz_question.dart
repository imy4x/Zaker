import 'package:zaker/constants/app_constants.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  // --- التعديل: تمت إضافة مستوى الصعوبة لكل سؤال ---
  final QuizDifficulty difficulty; 

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.difficulty,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    // دالة داخلية لتحويل النص القادم من API إلى enum
    QuizDifficulty parseDifficulty(String? diff) {
      switch (diff?.toLowerCase()) {
        case 'easy': return QuizDifficulty.easy;
        case 'medium': return QuizDifficulty.medium;
        case 'hard': return QuizDifficulty.hard;
        case 'very_hard': return QuizDifficulty.veryHard;
        default: return QuizDifficulty.medium; // قيمة افتراضية في حال حدوث خطأ
      }
    }

    return QuizQuestion(
      question: json['question'] ?? 'لا يوجد سؤال',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
      difficulty: parseDifficulty(json['difficulty']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      // تحويل الـ enum إلى نص عند الحفظ
      'difficulty': difficulty.toString().split('.').last,
    };
  }
}
