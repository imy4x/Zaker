import 'package:zaker/api/simple_gemini_service.dart';
import 'package:zaker/models/quiz_question.dart';
import 'package:zaker/models/flashcard.dart';
import 'package:zaker/constants/app_constants.dart';

/// 🎯 مدير الخدمات المحسن - Enhanced Service Manager
/// يدير جميع العمليات المتعلقة بالذكاء الاصطناعي مع نظام fallback قوي
class EnhancedServiceManager {
  late final GeminiService _geminiService;
  
  static EnhancedServiceManager? _instance;
  static EnhancedServiceManager get instance {
    _instance ??= EnhancedServiceManager._internal();
    return _instance!;
  }
  
  EnhancedServiceManager._internal() {
    _geminiService = GeminiService();
  }

  /// 📊 إحصائيات الاستخدام
  int _totalRequests = 0;
  int _successfulRequests = 0;
  int _failedRequests = 0;

  /// التحقق من صحة المحتوى التعليمي
  Future<ContentValidationResult> validateContent(
    String text, 
    Function(int) onKeyChanged
  ) async {
    _totalRequests++;
    
    try {
      final result = await _geminiService.validateContent(text, onKeyChanged);
      
      _successfulRequests++;
      
      return ContentValidationResult(
        isValid: result['is_study_material'] ?? false,
        reason: result['reason_ar'] ?? 'غير محدد',
        confidence: (result['confidence_score'] ?? 0.5).toDouble(),
      );
      
    } catch (e) {
      _failedRequests++;
      print('خطأ في التحقق من المحتوى: $e');
      
      return ContentValidationResult(
        isValid: false,
        reason: 'فشل في التحقق من صحة المحتوى',
        confidence: 0.0,
      );
    }
  }

  /// توليد ملخص تفاعلي
  Future<SummaryResult> generateSummary({
    required String text,
    String targetLanguage = 'ar',
    AnalysisDepth depth = AnalysisDepth.medium,
    required Function(int) onKeyChanged,
    String? customNotes,
  }) async {
    _totalRequests++;
    
    try {
      final result = await _geminiService.generateSummary(
        text, 
        targetLanguage, 
        depth, 
        onKeyChanged,
        customNotes: customNotes,
      );
      
      _successfulRequests++;
      
      return SummaryResult(
        isSuccess: true,
        arabicSummary: result['ar'] ?? '',
        englishSummary: result['en'] ?? '',
        wordCount: text.length,
        processingTime: DateTime.now(),
      );
      
    } catch (e) {
      _failedRequests++;
      print('خطأ في توليد الملخص: $e');
      
      return SummaryResult(
        isSuccess: false,
        arabicSummary: _getFallbackSummary('ar', text),
        englishSummary: _getFallbackSummary('en', text),
        wordCount: text.length,
        processingTime: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// توليد أسئلة تفاعلية
  Future<QuizResult> generateQuiz({
    required String text,
    String targetLanguage = 'ar',
    required Function(int) onKeyChanged,
    String? customNotes,
  }) async {
    _totalRequests++;
    
    try {
      final questions = await _geminiService.generateQuiz(
        text, 
        targetLanguage, 
        onKeyChanged,
        customNotes: customNotes,
      );
      
      _successfulRequests++;
      
      return QuizResult(
        isSuccess: true,
        questions: questions,
        totalQuestions: questions.length,
        processingTime: DateTime.now(),
      );
      
    } catch (e) {
      _failedRequests++;
      print('خطأ في توليد الأسئلة: $e');
      
      return QuizResult(
        isSuccess: false,
        questions: _getFallbackQuestions(),
        totalQuestions: 1,
        processingTime: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// توليد بطاقات تعليمية
  Future<FlashcardResult> generateFlashcards({
    required String text,
    String targetLanguage = 'ar',
    AnalysisDepth depth = AnalysisDepth.medium,
    required Function(int) onKeyChanged,
    String? customNotes,
  }) async {
    _totalRequests++;
    
    try {
      final flashcards = await _geminiService.generateFlashcards(
        text, 
        targetLanguage, 
        depth, 
        onKeyChanged,
        customNotes: customNotes,
      );
      
      _successfulRequests++;
      
      return FlashcardResult(
        isSuccess: true,
        flashcards: flashcards,
        totalCards: flashcards.length,
        processingTime: DateTime.now(),
      );
      
    } catch (e) {
      _failedRequests++;
      print('خطأ في توليد البطاقات: $e');
      
      return FlashcardResult(
        isSuccess: false,
        flashcards: _getFallbackFlashcards(),
        totalCards: 1,
        processingTime: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// 📈 الحصول على إحصائيات الاستخدام
  ServiceStats getStats() {
    return ServiceStats(
      totalRequests: _totalRequests,
      successfulRequests: _successfulRequests,
      failedRequests: _failedRequests,
      successRate: _totalRequests > 0 ? (_successfulRequests / _totalRequests) : 0.0,
    );
  }

  /// إعادة تعيين الإحصائيات
  void resetStats() {
    _totalRequests = 0;
    _successfulRequests = 0;
    _failedRequests = 0;
  }

  // === Fallback Methods ===

  String _getFallbackSummary(String language, String originalText) {
    if (language == 'ar') {
      return '''
# ملخص تلقائي

## نظرة عامة
تم استخراج هذا المحتوى من النص المرفق وهو جاهز للمراجعة والدراسة.

### المحتوى الأساسي
النص يحتوي على ${originalText.length} حرف من المعلومات التعليمية المهمة.

### نقاط للمراجعة
- قم بقراءة النص الأصلي بعناية
- حدد النقاط الرئيسية والمفاهيم المهمة
- اربط المعلومات ببعضها البعض

## توصيات للدراسة
- راجع النص مرة أخرى للتفاصيل
- اكتب ملاحظاتك الخاصة
- اختبر فهمك للمادة
''';
    } else {
      return '''
# Automatic Summary

## Overview
This content has been extracted from the provided text and is ready for review and study.

### Main Content
The text contains ${originalText.length} characters of important educational information.

### Points for Review
- Read the original text carefully
- Identify key points and important concepts
- Connect information together

## Study Recommendations
- Review the text again for details
- Write your own notes
- Test your understanding of the material
''';
    }
  }

  List<QuizQuestion> _getFallbackQuestions() {
    return [
      QuizQuestion(
        questionAr: 'ما هو الموضوع الرئيسي لهذا المحتوى؟',
        questionEn: 'What is the main topic of this content?',
        optionsAr: ['موضوع تعليمي مهم', 'معلومات عامة', 'نص غير مفهوم', 'لا شيء مما سبق'],
        optionsEn: ['Important educational topic', 'General information', 'Unclear text', 'None of the above'],
        correctAnswerIndex: 0,
        difficulty: QuizDifficulty.easy,
      ),
    ];
  }

  List<Flashcard> _getFallbackFlashcards() {
    return [
      Flashcard(
        questionAr: 'ما هو هذا المحتوى؟',
        answerAr: 'هو محتوى تعليمي يحتوي على معلومات مهمة للدراسة والمراجعة.',
        questionEn: 'What is this content?',
        answerEn: 'It is educational content containing important information for study and review.',
      ),
    ];
  }
}

/// نتيجة التحقق من صحة المحتوى
class ContentValidationResult {
  final bool isValid;
  final String reason;
  final double confidence;

  ContentValidationResult({
    required this.isValid,
    required this.reason,
    required this.confidence,
  });
}

/// نتيجة توليد الملخص
class SummaryResult {
  final bool isSuccess;
  final String arabicSummary;
  final String englishSummary;
  final int wordCount;
  final DateTime processingTime;
  final String? errorMessage;

  SummaryResult({
    required this.isSuccess,
    required this.arabicSummary,
    required this.englishSummary,
    required this.wordCount,
    required this.processingTime,
    this.errorMessage,
  });

  Map<String, String> get summaryMap => {
    'ar': arabicSummary,
    'en': englishSummary,
  };
}

/// نتيجة توليد الأسئلة
class QuizResult {
  final bool isSuccess;
  final List<QuizQuestion> questions;
  final int totalQuestions;
  final DateTime processingTime;
  final String? errorMessage;

  QuizResult({
    required this.isSuccess,
    required this.questions,
    required this.totalQuestions,
    required this.processingTime,
    this.errorMessage,
  });
}

/// نتيجة توليد البطاقات
class FlashcardResult {
  final bool isSuccess;
  final List<Flashcard> flashcards;
  final int totalCards;
  final DateTime processingTime;
  final String? errorMessage;

  FlashcardResult({
    required this.isSuccess,
    required this.flashcards,
    required this.totalCards,
    required this.processingTime,
    this.errorMessage,
  });
}

/// إحصائيات الخدمة
class ServiceStats {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final double successRate;

  ServiceStats({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.successRate,
  });

  String get successRatePercent => '${(successRate * 100).toStringAsFixed(1)}%';
}