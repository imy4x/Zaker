import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zaker/api/generative_ai_service.dart';
import 'package:zaker/models/flashcard.dart';
import 'package:zaker/models/quiz_question.dart';
import 'package:zaker/models/study_session.dart';
import 'package:zaker/services/pdf_parser_service.dart';
import 'package:zaker/services/storage_service.dart';

enum AppState { initial, loading, success, error }

class StudyProvider extends ChangeNotifier {
  final _aiService = GenerativeAiService();
  final _supabase = Supabase.instance.client;
  final _storageService = StorageService();

  AppState _state = AppState.initial;
  AppState get state => _state;

  List<StudySession?> _sessions = List.filled(3, null);
  List<StudySession?> get sessions => _sessions;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;
  
  double _progressValue = 0.0;
  double get progressValue => _progressValue;
  String _progressMessage = '';
  String get progressMessage => _progressMessage;

  StudyProvider() {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    for (int i = 0; i < 3; i++) {
      _sessions[i] = await _storageService.getSession(i);
    }
    notifyListeners();
  }

  Future<void> deleteSession(int slotIndex) async {
    await _storageService.deleteSession(slotIndex);
    _sessions[slotIndex] = null;
    notifyListeners();
  }

  Future<bool> processPdf(File pdfFile, int slotIndex, String targetLanguage) async {
    _state = AppState.loading;
    _updateProgress(0.0, 'جاري البدء...');
    notifyListeners();

    try {
      _updateProgress(0.1, 'الخطوة 1/6: استخراج النص من الملف...');
      final text = await PdfParserService.extractText(pdfFile);
      if (text.isEmpty) throw Exception('الملف فارغ أو لا يمكن قراءة النص منه.');

      _updateProgress(0.25, 'الخطوة 2/6: تحليل نوع المحتوى...');
      final validationResult = await _aiService.validateContent(text);
      if (validationResult['is_study_material'] == false) {
        throw Exception('المستند الذي تم رفعه ليس مادة دراسية. ${validationResult['reason']}');
      }

      _updateProgress(0.4, 'الخطوة 3/6: رفع نسخة احتياطية...');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.pdf';
      await _supabase.storage.from('pdfs').upload(fileName, pdfFile);

      _updateProgress(0.55, 'الخطوة 4/6: إنشاء الملخص...');
      final summaryFuture = _aiService.generateSummary(text, targetLanguage);
      
      _updateProgress(0.7, 'الخطوة 5/6: تصميم البطاقات التعليمية...');
      final flashcardsFuture = _aiService.generateFlashcards(text, targetLanguage);
      
      _updateProgress(0.85, 'الخطوة 6/6: بناء بنك الأسئلة...');
      final quizFuture = _aiService.generateQuiz(text, targetLanguage);

      final results = await Future.wait([summaryFuture, flashcardsFuture, quizFuture]);
      
      final session = StudySession(
        title: pdfFile.path.split('/').last,
        languageCode: targetLanguage == 'Arabic' ? 'ar' : 'en',
        summary: results[0] as String,
        flashcards: results[1] as List<Flashcard>,
        quizQuestions: results[2] as List<QuizQuestion>,
      );

      await _storageService.saveSession(slotIndex, session);
      _sessions[slotIndex] = session;

      _state = AppState.success;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = e.toString();
      _state = AppState.error;
      notifyListeners();
      return false;
    }
  }

  // --- دالة جديدة لتحديث سجل الاختبارات ---
  Future<void> updateQuizHistory(int slotIndex, int score, int totalQuestions) async {
    final session = _sessions[slotIndex];
    if (session != null) {
      session.totalCorrectAnswers += score;
      session.totalQuestionsAnswered += totalQuestions;
      await _storageService.saveSession(slotIndex, session);
      notifyListeners();
    }
  }

  void _updateProgress(double value, String message) {
    _progressValue = value;
    _progressMessage = message;
    notifyListeners();
  }

  void resetState() {
    _state = AppState.initial;
    _errorMessage = '';
    _progressValue = 0.0;
    _progressMessage = '';
    notifyListeners();
  }
}
