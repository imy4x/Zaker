import 'flashcard.dart';
import 'quiz_question.dart';

// --- تعديل: تمت إضافة حقل `listId` لربط الجلسة بقائمة محددة ---
class StudySession {
  final String id;
  String title;
  final DateTime createdAt;
  final String summaryAr;
  final String summaryEn;
  final List<Flashcard> flashcards;
  final List<QuizQuestion> quizQuestions;
  final String languageCode;
  Set<String> correctlyAnsweredQuestions;
  String? listId; // المعرّف الخاص بالقائمة التي تنتمي إليها الجلسة

  StudySession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.summaryAr,
    required this.summaryEn,
    required this.flashcards,
    required this.quizQuestions,
    this.languageCode = 'ar',
    this.listId,
    Set<String>? correctlyAnsweredQuestions,
  }) : correctlyAnsweredQuestions = correctlyAnsweredQuestions ?? {};

  // Legacy constructor for backward compatibility
  StudySession.legacy({
    required this.id,
    required this.title,
    required this.createdAt,
    required String summary,
    required this.flashcards,
    required this.quizQuestions,
    this.languageCode = 'ar',
    this.listId,
    Set<String>? correctlyAnsweredQuestions,
  }) : summaryAr = summary,
       summaryEn = summary, // Fallback to same content
       correctlyAnsweredQuestions = correctlyAnsweredQuestions ?? {};

  // Get summary based on language
  String getSummary(String languageCode) {
    return languageCode == 'en' ? summaryEn : summaryAr;
  }

  // For backward compatibility
  String get summary => summaryAr;

  factory StudySession.fromJson(Map<String, dynamic> json) {
    // Handle both new bilingual format and legacy format
    if (json.containsKey('summaryAr') && json.containsKey('summaryEn')) {
      return StudySession(
        id: json['id'] ?? DateTime.now().toIso8601String(),
        title: json['title'] ?? 'جلسة مذاكرة',
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        summaryAr: json['summaryAr'] ?? '',
        summaryEn: json['summaryEn'] ?? '',
        flashcards: (json['flashcards'] as List<dynamic>?)?.map((e) => Flashcard.fromJson(e)).toList() ?? [],
        quizQuestions: (json['quizQuestions'] as List<dynamic>?)?.map((e) => QuizQuestion.fromJson(e)).toList() ?? [],
        languageCode: json['languageCode'] ?? 'ar',
        listId: json['listId'],
        correctlyAnsweredQuestions: Set<String>.from(json['correctlyAnsweredQuestions'] as List<dynamic>? ?? []),
      );
    } else {
      // Legacy format
      return StudySession.legacy(
        id: json['id'] ?? DateTime.now().toIso8601String(),
        title: json['title'] ?? 'جلسة مذاكرة',
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        summary: json['summary'] ?? '',
        flashcards: (json['flashcards'] as List<dynamic>?)?.map((e) => Flashcard.fromJson(e)).toList() ?? [],
        quizQuestions: (json['quizQuestions'] as List<dynamic>?)?.map((e) => QuizQuestion.fromJson(e)).toList() ?? [],
        languageCode: json['languageCode'] ?? 'ar',
        listId: json['listId'],
        correctlyAnsweredQuestions: Set<String>.from(json['correctlyAnsweredQuestions'] as List<dynamic>? ?? []),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'summaryAr': summaryAr,
      'summaryEn': summaryEn,
      'flashcards': flashcards.map((e) => e.toJson()).toList(),
      'quizQuestions': quizQuestions.map((e) => e.toJson()).toList(),
      'languageCode': languageCode,
      'listId': listId,
      'correctlyAnsweredQuestions': correctlyAnsweredQuestions.toList(),
      // Keep legacy field for backward compatibility
      'summary': summaryAr,
    };
  }
}
