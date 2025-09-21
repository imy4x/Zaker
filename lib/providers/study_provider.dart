import 'package:flutter/material.dart';
import 'package:zaker/api/gemini_service.dart';
import 'package:zaker/constants/app_constants.dart';
import 'package:zaker/models/study_session.dart';
import 'package:zaker/services/storage_service.dart';
import 'package:zaker/services/text_extraction_service.dart';
import 'package:zaker/services/usage_service.dart';
import 'package:zaker/models/flashcard.dart';
import 'package:zaker/models/quiz_question.dart';

enum AppState { idle, loading, success, error }

class StudyProvider extends ChangeNotifier {
  final GeminiService _aiService = GeminiService();
  final StorageService _storageService = StorageService();
  final TextExtractionService _textExtractionService = TextExtractionService();
  final UsageService _usageService = UsageService(); 

  AppState _state = AppState.idle;
  AppState get state => _state;
  
  List<StudySession> _sessions = [];
  List<StudySession> get sessions => _sessions;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  double _progressValue = 0.0;
  double get progressValue => _progressValue;
  
  String _progressMessage = '';
  String get progressMessage => _progressMessage;

  int _currentApiKeyIndex = 0;
  int get currentApiKeyIndex => _currentApiKeyIndex;

  StudyProvider() {
    _init();
  }

  Future<void> _init() async {
    await _usageService.init();
    await _loadSessions();
  }

  UsageService get usageService => _usageService;

  Future<void> _loadSessions() async {
    _sessions = await _storageService.getSessions();
    _sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }
  
  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    await _storageService.saveSessions(_sessions);
    notifyListeners();
  }

  Future<StudySession?> createSessionFromFile(
    FileTypeOption fileType, 
    String targetLanguage, 
    String title,
    AnalysisDepth depth,
  ) async {
    // --- تعديل: استخدام نظام الحصص اليومية الجديد ---
    if (!_usageService.canUse()) {
      _errorMessage = 'لقد استهلكت رصيدك اليومي من التحليلات (محاولتان). حاول مجدداً غداً.';
      _state = AppState.error;
      notifyListeners();
      return null;
    }
    
    _state = AppState.loading;
    _updateProgress(0.0, 'جاري اختيار الملف...');
    notifyListeners();

    try {
      void updateKeyIndex(int index) {
        _currentApiKeyIndex = index;
        notifyListeners();
      }

      _updateProgress(0.1, 'الخطوة 1/4: استخراج النص (نموذج سريع)...');
      final text = await _textExtractionService.extractTextFromFile(fileType);
      if (text == null || text.trim().isEmpty) {
        throw Exception('لم يتم اختيار ملف أو أن الملف فارغ.');
      }

      _updateProgress(0.25, 'الخطوة 2/4: تحليل المحتوى (نموذج سريع)...');
      // --- تعديل: استدعاء الخدمة بدون عمق التحليل ---
      final validationResult = await _aiService.validateContent(text, updateKeyIndex);
      if (validationResult['is_study_material'] == false) {
        final reason = validationResult['reason_ar'] ?? 'السبب غير معروف.';
        throw Exception('هذا المستند لا يبدو كمادة دراسية.\nالسبب: $reason');
      }

      _updateProgress(0.5, 'الخطوة 3/4: إنشاء الملخص والبطاقات (نموذج احترافي)...');
      // --- ملاحظة: عمق التحليل يمرر هنا فقط لتخصيص نوعية الملخص المطلوب ---
      final summaryFuture = _aiService.generateSummary(text, targetLanguage, depth, updateKeyIndex);
      final flashcardsFuture = _aiService.generateFlashcards(text, targetLanguage, depth, updateKeyIndex);
      
      _updateProgress(0.75, 'الخطوة 4/4: بناء بنك الأسئلة (نموذج احترافي)...');
      final quizFuture = _aiService.generateQuiz(text, targetLanguage, updateKeyIndex);

      final results = await Future.wait([summaryFuture, flashcardsFuture, quizFuture]);
      
      final newSession = StudySession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        createdAt: DateTime.now(),
        languageCode: targetLanguage == 'العربية' ? 'ar' : 'en',
        summary: results[0] as String,
        flashcards: results[1] as List<Flashcard>,
        quizQuestions: results[2] as List<QuizQuestion>,
      );
      
      _sessions.insert(0, newSession);
      await _storageService.saveSessions(_sessions);
      
      // --- تعديل: تسجيل محاولة استخدام واحدة ---
      await _usageService.recordUsage(); 

      _state = AppState.success;
      notifyListeners();
      return newSession;

    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _state = AppState.error;
      notifyListeners();
      return null;
    }
  }

  void _updateProgress(double value, String message) {
    _progressValue = value;
    _progressMessage = message;
    notifyListeners();
  }

  void resetState() async {
    await _usageService.init(); 
    _state = AppState.idle;
    _errorMessage = '';
    _progressValue = 0.0;
    _progressMessage = '';
    notifyListeners();
  }
   Future<void> recordQuizResult(String sessionId, List<QuizQuestion> correctlyAnswered) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      for (var question in correctlyAnswered) {
        _sessions[sessionIndex].correctlyAnsweredQuestions.add(question.question);
      }
      await _storageService.saveSessions(_sessions);
      notifyListeners();
    }
  }

  Future<void> resetQuizProgress(String sessionId) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      _sessions[sessionIndex].correctlyAnsweredQuestions.clear();
      await _storageService.saveSessions(_sessions);
      notifyListeners();
    }
  }
}
