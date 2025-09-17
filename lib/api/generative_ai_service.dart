import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:zaker/constants/api_keys.dart';
import 'package:zaker/models/flashcard.dart';
import 'package:zaker/models/quiz_question.dart';

class GenerativeAiService {
  final GenerativeModel _model;

  GenerativeAiService()
      : _model = GenerativeModel(
          model: 'gemini-2.5-pro',
          apiKey: geminiApiKey,
        );

  Future<Map<String, dynamic>> validateContent(String text) async {
    final prompt = '''
      حلل النص التالي. هل هو مناسب للدراسة الأكاديمية أو التعليمية؟
      أجب بصيغة JSON فقط بهذا الشكل: {"is_study_material": true/false, "reason": "..."}
      النص: """${text.substring(0, text.length > 1000 ? 1000 : text.length)}"""
    ''';
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanJson);
    } catch (e) {
      return {"is_study_material": false, "reason": "فشل في تحليل المحتوى."};
    }
  }

  Future<String> generateSummary(String text, String targetLanguage) async {
    // --- تحديث الطلب للحصول على ملخص منسق ---
    final prompt =
        'لخص النص التالي بشكل احترافي ومنظم لمساعدة طالب على المذاكرة. استخدم عناوين رئيسية (باستخدام # أو ##) للنقاط الأساسية، واستخدم نقاط (باستخدام - أو *) للتفاصيل الهامة. اجعل الملخص سهل القراءة والفهم وتجنب استخدام ** للنصوص العريضة. **اللغة المطلوبة للملخص هي: $targetLanguage**. النص: """$text"""';
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'لم يتمكن الذكاء الاصطناعي من إنشاء ملخص.';
  }

  Future<List<Flashcard>> generateFlashcards(String text, String targetLanguage) async {
    // --- تحديث: طلب أكبر عدد ممكن من البطاقات ---
    final prompt = '''
      من النص التالي، قم بإنشاء أكبر عدد ممكن من البطاقات التعليمية (flashcards) على شكل سؤال وجواب (بحد أقصى 50 بطاقة).
      يجب أن تكون الإجابة مباشرة ومختصرة.
      **اللغة المطلوبة للبطاقات هي: $targetLanguage**.
      قم بإرجاع النتيجة على هيئة قائمة JSON صالحة بهذا الشكل: `[{"question":"...","answer":"..."},{"question":"...","answer":"..."}]`
      النص: """$text"""
    ''';
    final response = await _model.generateContent([Content.text(prompt)]);
    
    try {
      final cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> jsonList = jsonDecode(cleanJson);
      return jsonList.map((item) => Flashcard.fromJson(item)).toList();
    } catch (e) {
      print("Error parsing flashcards: $e");
      return [];
    }
  }

  Future<List<QuizQuestion>> generateQuiz(String text, String targetLanguage) async {
    // --- تحديث: طلب أكبر عدد ممكن من الأسئلة ---
    final prompt = '''
      من النص التالي، قم بإنشاء أكبر عدد ممكن من أسئلة الاختيار من متعدد (بحد أقصى 50 سؤالاً).
      كل سؤال يجب أن يحتوي على 4 خيارات، واحد منها فقط صحيح.
      **اللغة المطلوبة للاختبار هي: $targetLanguage**.
      قم بإرجاع النتيجة على هيئة قائمة JSON صالحة بهذا الشكل: `[{"question":"...","options":["...","...","...","..."],"correctAnswerIndex":0}]`
      النص: """$text"""
    ''';
    final response = await _model.generateContent([Content.text(prompt)]);
    
    try {
      final cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> jsonList = jsonDecode(cleanJson);
      return jsonList.map((item) => QuizQuestion.fromJson(item)).toList();
    } catch (e) {
      print("Error parsing quiz: $e");
      return [];
    }
  }
}