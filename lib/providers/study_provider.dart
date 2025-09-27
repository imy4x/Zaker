import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:zaker/api/gemini_service.dart';
import 'package:zaker/constants/app_constants.dart';
import 'package:zaker/models/study_list.dart';
import 'package:zaker/models/study_session.dart';
import 'package:zaker/services/storage_service.dart';
import 'package:zaker/services/text_extraction_service.dart';
import 'package:zaker/services/usage_service.dart';
import 'package:zaker/models/flashcard.dart';
import 'package:zaker/models/quiz_question.dart';
import 'package:uuid/uuid.dart';

enum AppState { idle, loading, success, error }

class StudyProvider extends ChangeNotifier {
  final GeminiService _aiService = GeminiService();
  final StorageService _storageService = StorageService();
  final TextExtractionService _textExtractionService = TextExtractionService();
  final UsageService _usageService = UsageService(); 
  final Uuid _uuid = const Uuid();

  AppState _state = AppState.idle;
  AppState get state => _state;
  
  List<StudySession> _sessions = [];
  List<StudySession> get sessions => _sessions;

  List<StudyList> _lists = [];
  List<StudyList> get lists => _lists;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;
  
  String _warningMessage = '';
  String get warningMessage => _warningMessage;

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
    await _loadData();
  }

  UsageService get usageService => _usageService;

  Future<void> _loadData() async {
    _sessions = await _storageService.getSessions();
    _lists = await _storageService.getLists();
    _sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _lists.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }
  
  // --- دوال إدارة الجلسات ---

  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    await _storageService.saveSessions(_sessions);
    notifyListeners();
  }

  Future<void> moveSessionToList(String sessionId, String? listId) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if(sessionIndex != -1) {
      _sessions[sessionIndex].listId = listId;
      await _storageService.saveSessions(_sessions);
      notifyListeners();
    }
  }

  Future<void> renameSession(String sessionId, String newName) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if(sessionIndex != -1) {
      _sessions[sessionIndex].title = newName;
      await _storageService.saveSessions(_sessions);
      notifyListeners();
    }
  }

  Future<StudySession?> createSessionFromFiles(
    List<PlatformFile> files, 
    String targetLanguage, 
    String title,
    AnalysisDepth depth,
    {String? customNotes, String? listId}
  ) async {
    if (!_usageService.canUse(count: files.length)) {
      _errorMessage = 'رصيدك اليومي لا يكفي لتحليل هذا العدد من الملفات.';
      _state = AppState.error;
      notifyListeners();
      return null;
    }
    
    _state = AppState.loading;
    _updateProgress(0.0, 'جاري تهيئة الجلسة...');
    notifyListeners();

    try {
      void updateKeyIndex(int index) {
        _currentApiKeyIndex = index;
        notifyListeners();
      }

      _updateProgress(0.1, 'الخطوة 1/${files.length + 3}: تجميع النصوص...');
      final combinedText = await _textExtractionService.extractTextFromMultipleFiles(files);
      if (combinedText.trim().isEmpty) {
        throw Exception('لم يتم استخلاص أي نص من الملفات المحددة.');
      }

      _updateProgress(0.25, 'الخطوة 2/${files.length + 3}: التحقق من المحتوى...');
      final validationResult = await _aiService.validateContent(combinedText, updateKeyIndex);
      if (validationResult['is_study_material'] == false) {
        final reason = validationResult['reason_ar'] ?? 'السبب غير معروف.';
        throw Exception('هذا المستند لا يبدو كمادة دراسية.\nالسبب: $reason');
      }

      _updateProgress(0.5, 'الخطوة 3/${files.length + 3}: إنشاء الملخص...');
      final summaryFuture = _aiService.generateSummary(combinedText, targetLanguage, depth, updateKeyIndex, customNotes: customNotes);
      
      _updateProgress(0.7, 'الخطوة 4/${files.length + 3}: إنشاء البطاقات التعليمية...');
      final flashcardsFuture = _aiService.generateFlashcards(combinedText, targetLanguage, depth, updateKeyIndex, customNotes: customNotes);
      
      _updateProgress(0.85, 'الخطوة 5/${files.length + 3}: بناء بنك الأسئلة...');
      final quizFuture = _aiService.generateQuiz(combinedText, targetLanguage, updateKeyIndex, customNotes: customNotes);

      final results = await Future.wait([summaryFuture, flashcardsFuture, quizFuture]);
      
      final summaryData = results[0] as Map<String, String>;
      final flashcards = results[1] as List<Flashcard>;
      final quizQuestions = results[2] as List<QuizQuestion>;
      
      final newSession = StudySession(
        id: _uuid.v4(),
        title: title,
        createdAt: DateTime.now(),
        languageCode: targetLanguage == 'العربية' ? 'ar' : 'en',
        summaryAr: summaryData['ar'] ?? '',
        summaryEn: summaryData['en'] ?? '',
        flashcards: flashcards,
        quizQuestions: quizQuestions,
        listId: listId, // Assign to selected folder
      );
      
      _sessions.insert(0, newSession);
      await _storageService.saveSessions(_sessions);
      
      // --- تعديل: تم تمرير عدد الملفات لتسجيل الاستخدام بشكل صحيح ---
      await _usageService.recordUsage(count: files.length); 

      _state = AppState.success;
      notifyListeners();
      return newSession;

    } catch (e) {
      // Check if it's an AI quota/overload error
      if (e.toString().contains('Quota') || e.toString().contains('exceeded') || 
          e.toString().contains('quota') || e.toString().contains('overloaded')) {
        _errorMessage = 'الذكاء الاصطناعي مرهق حالياً \u{1F614}\n\nيرجى المحاولة مرة أخرى بعد بضع دقائق. \u{1F504}';
      } else {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
      }
      _state = AppState.error;
      notifyListeners();
      return null;
    }
  }

  // --- دوال إدارة القوائم ---

  Future<void> createList(String name) async {
    final newList = StudyList(id: _uuid.v4(), name: name);
    _lists.add(newList);
    await _storageService.saveLists(_lists);
    notifyListeners();
  }

  Future<void> renameList(String listId, String newName) async {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if(listIndex != -1) {
      _lists[listIndex].name = newName;
      await _storageService.saveLists(_lists);
      notifyListeners();
    }
  }

  Future<void> deleteList(String listId) async {
    _lists.removeWhere((l) => l.id == listId);
    // جعل الجلسات التابعة لهذه القائمة غير مصنفة
    for (var session in _sessions) {
      if (session.listId == listId) {
        session.listId = null;
      }
    }
    await _storageService.saveLists(_lists);
    await _storageService.saveSessions(_sessions);
    notifyListeners();
  }


  // --- دوال أخرى ---

  void _updateProgress(double value, String message) {
    _progressValue = value;
    _progressMessage = message;
    notifyListeners();
  }

  void resetState() async {
    await _usageService.init(); 
    _state = AppState.idle;
    _errorMessage = '';
    _warningMessage = '';
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

