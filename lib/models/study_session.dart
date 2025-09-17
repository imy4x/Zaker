import 'dart:convert';
import 'package:zaker/models/flashcard.dart';
import 'package:zaker/models/quiz_question.dart';

class StudySession {
  final String title;
  final String summary;
  final List<Flashcard> flashcards;
  final List<QuizQuestion> quizQuestions;
  final String languageCode; // 'ar' or 'en'
  int totalQuestionsAnswered;
  int totalCorrectAnswers;

  StudySession({
    required this.title,
    required this.summary,
    required this.flashcards,
    required this.quizQuestions,
    this.languageCode = 'ar',
    this.totalQuestionsAnswered = 0,
    this.totalCorrectAnswers = 0,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      title: json['title'] ?? 'جلسة مذاكرة',
      summary: json['summary'] ?? '',
      flashcards: (json['flashcards'] as List<dynamic>?)
          ?.map((e) => Flashcard.fromJson(e))
          .toList() ?? [],
      quizQuestions: (json['quizQuestions'] as List<dynamic>?)
          ?.map((e) => QuizQuestion.fromJson(e))
          .toList() ?? [],
      languageCode: json['languageCode'] ?? 'ar',
      totalQuestionsAnswered: json['totalQuestionsAnswered'] ?? 0,
      totalCorrectAnswers: json['totalCorrectAnswers'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'flashcards': flashcards.map((e) => e.toJson()).toList(),
      'quizQuestions': quizQuestions.map((e) => e.toJson()).toList(),
      'languageCode': languageCode,
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'totalCorrectAnswers': totalCorrectAnswers,
    };
  }
}
