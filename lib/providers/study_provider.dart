import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:zaker/constants/app_constants.dart';
import 'package:zaker/models/study_list.dart';
import 'package:zaker/models/study_session.dart';
import 'package:zaker/services/enhanced_service_manager.dart';

import 'package:zaker/services/storage_service.dart';
import 'package:zaker/services/text_extraction_service.dart';
import 'package:zaker/services/usage_service.dart';
import 'package:zaker/models/flashcard.dart';
import 'package:zaker/models/quiz_question.dart';
import 'package:uuid/uuid.dart';

enum AppState { idle, loading, success, error }

class StudyProvider extends ChangeNotifier {
  final EnhancedServiceManager _serviceManager = EnhancedServiceManager.instance;
  final StorageService _storageService = StorageService();
  final TextExtractionService _textExtractionService = TextExtractionService();
  // تعديل: سيتم الآن استقبال الخدمة من الخارج بدلاً من إنشائها هنا
  final UsageService _usageService;
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

  // تعديل: الدالة الإنشائية الآن تستقبل خدمة تتبع الاستخدام
  StudyProvider(this._usageService) {
    _init();
  }

  Future<void> _init() async {
    // تعديل: تم حذف تهيئة الخدمة من هنا لأنها تتم في ملف main.dart
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
    if (sessionIndex != -1) {
      _sessions[sessionIndex].listId = listId;
      await _storageService.saveSessions(_sessions);
      notifyListeners();
    }
  }

  Future<void> renameSession(String sessionId, String newName) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      _sessions[sessionIndex].title = newName;
      await _storageService.saveSessions(_sessions);
      notifyListeners();
    }
  }

  Future<StudySession?> createSessionFromFiles(List<PlatformFile> files,
      String targetLanguage, String title, AnalysisDepth depth,
      {String? customNotes, String? listId}) async {
    if (!_usageService.canUse(count: files.length)) {
      _errorMessage = 'رصيدك اليومي لا يكفي لتحليل هذا العدد من الملفات.';
      _state = AppState.error;
      notifyListeners();
      return null;
    }

    _state = AppState.loading;
    _updateProgress(0.0, 'جاري تهيئة التحليل...');
    notifyListeners();

    try {
      void updateKeyIndex(int index) {
        _currentApiKeyIndex = index;
      }

      _updateProgress(0.1, 'المرحلة 1/4: استخراج النصوص...');
      final rawText = await _textExtractionService.extractRawText(files);
      if (rawText.trim().isEmpty) {
        throw Exception('لم يتم استخلاص أي نص من الملفات المحددة.');
      }

      _updateProgress(0.25, 'المرحلة 2/4: التحقق من جودة المحتوى...');
      final validationResult = await _serviceManager.validateContent(rawText, updateKeyIndex);
      if (!validationResult.isValid) {
        throw Exception('هذا المستند لا يبدو كمادة دراسية.\nالسبب: ${validationResult.reason}');
      }

      _updateProgress(0.4, 'المرحلة 3/4: إنشاء الملخص والبطاقات...');
      final summaryFuture = _serviceManager.generateSummary(
          text: rawText,
          targetLanguage: targetLanguage,
          depth: depth,
          onKeyChanged: updateKeyIndex,
          customNotes: customNotes);

      final flashcardsFuture = _serviceManager.generateFlashcards(
          text: rawText,
          targetLanguage: targetLanguage,
          depth: depth,
          onKeyChanged: updateKeyIndex,
          customNotes: customNotes);

      _updateProgress(0.7, 'المرحلة 4/4: بناء بنك الأسئلة...');
      final quizFuture = _serviceManager.generateQuiz(
          text: rawText,
          targetLanguage: targetLanguage,
          depth: depth,
          onKeyChanged: updateKeyIndex,
          customNotes: customNotes);

      final results = await Future.wait([summaryFuture, flashcardsFuture, quizFuture]);

      final summaryResult = results[0] as SummaryResult;
      final flashcardResult = results[1] as FlashcardResult;
      final quizResult = results[2] as QuizResult;

      if (!summaryResult.isSuccess || !flashcardResult.isSuccess || !quizResult.isSuccess) {
        final errors = [
          if (!summaryResult.isSuccess) 'الملخص: ${summaryResult.errorMessage}',
          if (!flashcardResult.isSuccess) 'البطاقات: ${flashcardResult.errorMessage}',
          if (!quizResult.isSuccess) 'الأسئلة: ${quizResult.errorMessage}',
        ].join('\n');
        throw Exception('فشل في أحد مراحل التحليل:\n$errors');
      }

      _updateProgress(1.0, 'اكتمل التحليل بنجاح!');

      final newSession = StudySession(
        id: _uuid.v4(),
        title: title,
        createdAt: DateTime.now(),
        languageCode: targetLanguage == 'العربية' ? 'ar' : 'en',
        summaryAr: summaryResult.arabicSummary,
        summaryEn: summaryResult.englishSummary,
        flashcards: flashcardResult.flashcards,
        quizQuestions: quizResult.questions,
        listId: listId,
      );

      _sessions.insert(0, newSession);
      await _storageService.saveSessions(_sessions);
      await _usageService.recordUsage(count: files.length);

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

  // --- دوال إدارة القوائم ---

  Future<void> createList(String name) async {
    if (name.trim().isEmpty) return;
    final newList = StudyList(id: _uuid.v4(), name: name.trim());
    _lists.add(newList);
    _lists.sort((a, b) => a.name.compareTo(b.name));
    await _storageService.saveLists(_lists);
    notifyListeners();
  }

  Future<void> renameList(String listId, String newName) async {
    if (newName.trim().isEmpty) return;
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      _lists[listIndex].name = newName.trim();
      _lists.sort((a, b) => a.name.compareTo(b.name));
      await _storageService.saveLists(_lists);
      notifyListeners();
    }
  }

  Future<void> deleteList(String listId) async {
    _lists.removeWhere((l) => l.id == listId);
    bool sessionsModified = false;
    for (var session in _sessions) {
      if (session.listId == listId) {
        session.listId = null;
        sessionsModified = true;
      }
    }
    await _storageService.saveLists(_lists);
    if (sessionsModified) {
      await _storageService.saveSessions(_sessions);
    }
    notifyListeners();
  }

  // --- دوال أخرى ---

  void _updateProgress(double value, String message) {
    _progressValue = value;
    _progressMessage = message;
    notifyListeners();
  }

  void resetState() {
    _state = AppState.idle;
    _errorMessage = '';
    _warningMessage = '';
    _progressValue = 0.0;
    _progressMessage = '';
    notifyListeners();
  }

  Future<void> recordQuizResult(
      String sessionId, List<QuizQuestion> correctlyAnswered) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final session = _sessions[sessionIndex];
      final correctIds = correctlyAnswered.map((q) => q.question).toSet();
      session.correctlyAnsweredQuestions.addAll(correctIds);
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
