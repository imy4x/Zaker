import 'dart:io';
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
import 'package:file_picker/file_picker.dart';

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

  // --- إضافة: حالة خاصة بالقوائم ---
  List<StudyList> _lists = [];
  List<StudyList> get lists => _lists;

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
    await _loadLists(); // تحميل القوائم عند بدء التشغيل
  }

  UsageService get usageService => _usageService;

  Future<void> _loadSessions() async {
    _sessions = await _storageService.getSessions();
    _sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> _loadLists() async {
    _lists = await _storageService.getLists();
    _lists.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  // --- إضافة: دوال إدارة القوائم ---
  Future<void> createList(String name) async {
    final newList = StudyList(
        id: DateTime.now().millisecondsSinceEpoch.toString(), name: name);
    _lists.add(newList);
    await _storageService.saveLists(_lists);
    notifyListeners();
  }

  Future<void> deleteList(String listId, {bool deleteSessions = false}) async {
    if (deleteSessions) {
      _sessions.removeWhere((s) => s.listId == listId);
    } else {
      for (var session in _sessions) {
        if (session.listId == listId) {
          session.listId = null; // نقل الجلسات إلى "غير مصنف"
        }
      }
    }
    _lists.removeWhere((l) => l.id == listId);
    await _storageService.saveLists(_lists);
    await _storageService.saveSessions(_sessions);
    notifyListeners();
  }
  
  Future<void> updateList(StudyList list) async {
    final index = _lists.indexWhere((element) => element.id == list.id);
    if(index != -1) {
      _lists[index] = list;
      await _storageService.saveLists(_lists);
      notifyListeners();
    }
  }

  Future<void> moveSessionToList(String sessionId, String? listId) async {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    session.listId = listId;
    await _storageService.saveSessions(_sessions);
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    await _storageService.saveSessions(_sessions);
    notifyListeners();
  }

  // --- تعديل: دالة جديدة لتحليل ملفات متعددة ---
  Future<StudySession?> createSessionFromFiles(
    List<PlatformFile> files,
    String targetLanguage,
    String title,
    AnalysisDepth depth,
  ) async {
    if (files.isEmpty) {
      _errorMessage = 'الرجاء اختيار ملف واحد على الأقل.';
      _state = AppState.error;
      notifyListeners();
      return null;
    }

    if (_usageService.getRemainingUses() < files.length) {
      _errorMessage =
          'ليس لديك رصيد كافٍ. تحتاج إلى ${files.length} محاولات، والمتبقي لديك ${_usageService.getRemainingUses()} فقط.';
      _state = AppState.error;
      notifyListeners();
      return null;
    }

    _state = AppState.loading;
    _updateProgress(0.0, 'جاري تحليل ${files.length} ملفات...');
    notifyListeners();

    try {
      void updateKeyIndex(int index) {
        _currentApiKeyIndex = index;
        notifyListeners();
      }

      _updateProgress(0.1, 'الخطوة 1/5: استخراج النصوص...');
      final combinedText = await _textExtractionService.extractTextFromMultipleFiles(files);
      if (combinedText.trim().isEmpty) {
        throw Exception('لم يتم العثور على أي نص في الملفات المحددة.');
      }

      _updateProgress(0.25, 'الخطوة 2/5: التحقق من المحتوى...');
      final validationResult = await _aiService.validateContent(combinedText, updateKeyIndex);
      if (validationResult['is_study_material'] == false) {
        final reason = validationResult['reason_ar'] ?? 'السبب غير معروف.';
        throw Exception('هذا المستند لا يبدو كمادة دراسية.\nالسبب: $reason');
      }

      _updateProgress(0.5, 'الخطوة 3/5: إنشاء الملخص والبطاقات...');
      final summaryFuture = _aiService.generateSummary(
          combinedText, targetLanguage, depth, updateKeyIndex);
      final flashcardsFuture = _aiService.generateFlashcards(
          combinedText, targetLanguage, depth, updateKeyIndex);

      _updateProgress(0.75, 'الخطوة 4/5: بناء بنك الأسئلة...');
      final quizFuture =
          _aiService.generateQuiz(combinedText, targetLanguage, updateKeyIndex);

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

      _updateProgress(0.95, 'الخطوة 5/5: تسجيل الاستخدام...');
      for (int i = 0; i < files.length; i++) {
        await _usageService.recordUsage();
      }

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

  Future<void> recordQuizResult(
      String sessionId, List<QuizQuestion> correctlyAnswered) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      for (var question in correctlyAnswered) {
        _sessions[sessionIndex].correctlyAnsweredQuestions.add(question.question);
      }
      await _storageService.saveSessions(_sessions);
      notifyListeners();
    }
  }
}
