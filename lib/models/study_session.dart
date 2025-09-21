import 'flashcard.dart';
import 'quiz_question.dart';

// تم تعديل النموذج ليناسب القائمة الديناميكية ويحتوي على معرّف فريد
class StudySession {
  final String id; // معرّف فريد لكل جلسة
  String title;
  final DateTime createdAt;
  final String summary;
  final List<Flashcard> flashcards;
  final List<QuizQuestion> quizQuestions;
  final String languageCode;
  Set<String> correctlyAnsweredQuestions;

  StudySession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.summary,
    required this.flashcards,
    required this.quizQuestions,
    this.languageCode = 'ar',
    Set<String>? correctlyAnsweredQuestions,
  }) : correctlyAnsweredQuestions = correctlyAnsweredQuestions ?? {};

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] ?? DateTime.now().toIso8601String(),
      title: json['title'] ?? 'جلسة مذاكرة',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      summary: json['summary'] ?? '',
      flashcards: (json['flashcards'] as List<dynamic>?)?.map((e) => Flashcard.fromJson(e)).toList() ?? [],
      quizQuestions: (json['quizQuestions'] as List<dynamic>?)?.map((e) => QuizQuestion.fromJson(e)).toList() ?? [],
      languageCode: json['languageCode'] ?? 'ar',
      correctlyAnsweredQuestions: Set<String>.from(json['correctlyAnsweredQuestions'] as List<dynamic>? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'summary': summary,
      'flashcards': flashcards.map((e) => e.toJson()).toList(),
      'quizQuestions': quizQuestions.map((e) => e.toJson()).toList(),
      'languageCode': languageCode,
      'correctlyAnsweredQuestions': correctlyAnsweredQuestions.toList(),
    };
  }
}
