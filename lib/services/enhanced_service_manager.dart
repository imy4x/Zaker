import 'package:zaker/api/simple_gemini_service.dart';
import 'package:zaker/models/quiz_question.dart';
import 'package:zaker/models/flashcard.dart';
import 'package:zaker/constants/app_constants.dart';

/// 🎯 مدير الخدمات المحسن - Enhanced Service Manager v2.0
/// يدير الجيل الجديد من العمليات المعززة بالذكاء الاصطناعي، مع نظام تحليل ثنائي المراحل.
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
      
      // Fallback: Assume content is valid if validation fails, to not block the user.
      return ContentValidationResult(
        isValid: true,
        reason: 'فشل التحقق، تم القبول افتراضياً',
        confidence: 0.5,
      );
    }
  }

  /// توليد ملخص تفاعلي باستخدام "شخصية الخبير"
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
        wordCount: text.split(RegExp(r'\s+')).length,
        processingTime: DateTime.now(),
      );
      
    } catch (e) {
      _failedRequests++;
      print('خطأ في توليد الملخص: $e');
      
      return SummaryResult(
        isSuccess: false,
        arabicSummary: _getFallbackSummary('ar', text),
        englishSummary: _getFallbackSummary('en', text),
        wordCount: text.split(RegExp(r'\s+')).length,
        processingTime: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// توليد أسئلة تفاعلية باستخدام "شخصية مصمم الاختبارات"
  Future<QuizResult> generateQuiz({
    required String text,
    String targetLanguage = 'ar',
    AnalysisDepth depth = AnalysisDepth.medium,
    required Function(int) onKeyChanged,
    String? customNotes,
  }) async {
    _totalRequests++;
    
    try {
      final questions = await _geminiService.generateQuiz(
        text, 
        targetLanguage, 
        depth,
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

  /// توليد بطاقات تعليمية باستخدام "شخصية صانع الامتحانات"
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
    final wordCount = originalText.split(RegExp(r'\s+')).length;
    if (language == 'ar') {
      return '''
# ملخص احتياطي

## تعذر إنشاء الملخص
حدث خطأ أثناء محاولة تحليل النص. هذا ملخص احتياطي.

### محتوى النص
النص الأصلي يحتوي على ما يقارب $wordCount كلمة.

> **نصيحة:** يرجى المحاولة مرة أخرى. إذا استمرت المشكلة، تأكد من أن النص واضح وقابل للقراءة.
''';
    } else {
      return '''
# Fallback Summary

## Summary Generation Failed
An error occurred while trying to analyze the text. This is a fallback summary.

### Text Content
The original text contains approximately $wordCount words.

> **Tip:** Please try again. If the problem persists, ensure the text is clear and readable.
''';
    }
  }

  List<QuizQuestion> _getFallbackQuestions() {
    return [
      QuizQuestion(
        questionAr: 'لماذا ظهر هذا السؤال؟',
        questionEn: 'Why did this question appear?',
        optionsAr: ['لأن الذكاء الاصطناعي فشل في إنشاء أسئلة', 'سؤال عشوائي', 'لا أعرف', 'كل ما سبق'],
        optionsEn: ['Because the AI failed to generate questions', 'A random question', 'I don\'t know', 'All of the above'],
        correctAnswerIndex: 0,
        difficulty: QuizDifficulty.easy,
      ),
    ];
  }

  List<Flashcard> _getFallbackFlashcards() {
    return [
      Flashcard(
        questionAr: 'ما سبب ظهور هذه البطاقة؟',
        answerAr: 'ظهرت هذه البطاقة كبديل لأن النظام واجه خطأ أثناء محاولة إنشاء بطاقات تعليمية من النص.',
        questionEn: 'Why did this flashcard appear?',
        answerEn: 'This flashcard appeared as a fallback because the system encountered an error while trying to generate flashcards from the text.',
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

