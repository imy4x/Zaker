import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:zaker/constants/api_keys.dart';
import 'package:zaker/constants/app_constants.dart';
import 'package:zaker/models/flashcard.dart';
import 'package:zaker/models/quiz_question.dart';

enum ModelType {
  pro,
  flash,
}

class GeminiService {
  int _currentApiKeyIndex = 0;
  final List<String> _validApiKeys;

  GeminiService()
      : _validApiKeys = geminiApiKeys
            .where((key) => key.isNotEmpty && !key.contains('YOUR_API_KEY_HERE'))
            .toList();

  GenerativeModel _getModel(ModelType modelType) {
    final apiKey = _validApiKeys[_currentApiKeyIndex];
    // **تعديل:** استخدام أحدث أسماء الموديلات الموصى بها
    final modelName = switch (modelType) {
      ModelType.pro => 'gemini-2.5-pro',
      ModelType.flash => 'gemini-2.5-flash',
    };

    return GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
            temperature: 0.5, responseMimeType: 'application/json'));
  }

  Future<GenerateContentResponse> _generateContentWithRetry(
    List<Content> prompt,
    ModelType modelType,
    Function(int) onKeyChanged,
  ) async {
    if (_validApiKeys.isEmpty) {
      throw Exception(
          'Please add valid Gemini API keys in constants/api_keys.dart. No valid keys were found.');
    }

    int attempts = 0;
    String lastError = '';

    while (attempts < _validApiKeys.length) {
      try {
        final model = _getModel(modelType);
        final response = await model.generateContent(prompt).timeout(
            const Duration(minutes: 3),
            onTimeout: () => throw Exception('Request timed out'));
        return response;
      } catch (e) {
        lastError = e.toString();
        if (_shouldSwitchApiKey(e.toString())) {
          _currentApiKeyIndex = (_currentApiKeyIndex + 1) % _validApiKeys.length;
          attempts++;
          onKeyChanged(_currentApiKeyIndex);
          await Future.delayed(const Duration(seconds: 1));
        } else {
          throw Exception('A non-recoverable error occurred: $lastError');
        }
      }
    }
    throw Exception('All valid API keys failed. Last error: $lastError');
  }

  bool _shouldSwitchApiKey(String errorMessage) {
    final errorPatterns = [
      'Quota', 'exceeded', 'limit', 'API_KEY_INVALID', 'timed out', '429',
      'server error'
    ];
    return errorPatterns
        .any((p) => errorMessage.toLowerCase().contains(p.toLowerCase()));
  }

  Future<Map<String, dynamic>> validateContent(
      String text, Function(int) onKeyChanged) async {
    final prompt =
        '''Analyze if the text is educational. Respond with JSON: {"is_study_material": true/false, "reason_ar": "..."}
      Text: """${text.substring(0, text.length > 2000 ? 2000 : text.length)}"""''';
    try {
      final response = await _generateContentWithRetry(
          [Content.text(prompt)], ModelType.flash, onKeyChanged);
      final cleanJson =
          response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanJson);
    } catch (e) {
      return {
        "is_study_material": true,
        "reason_ar": "Content accepted by default."
      };
    }
  }

  Future<Map<String, String>> generateSummary(
      String text, String targetLanguage, AnalysisDepth depth,
      Function(int) onKeyChanged, {String? customNotes}) async {
    final customNotesSection =
        customNotes != null && customNotes.isNotEmpty
            ? '\n**User Notes**: $customNotes'
            : '';

    String depthInstructions;
    switch (depth) {
      case AnalysisDepth.deep:
        depthInstructions = '''
        **Depth: Deep**
        1.  **Comprehensive Explanation:** Explain EVERY concept in detail.
        2.  **Mandatory Examples:** Provide a clear "Explanatory Example" AND a "Creative Analogy" for EACH sub-concept to make it memorable.
        3.  **Concept Mapping:** Connect different concepts to show their relationships.
        ''';
        break;
      case AnalysisDepth.medium:
        depthInstructions = '''
        **Depth: Medium**
        1.  **Balanced Explanation:** Clear explanations for main and sub-concepts.
        2.  **Targeted Examples:** Add an "Explanatory Example" for the MOST IMPORTANT concepts.
        3.  **Focus on Core Ideas:** Balance detail and brevity.
        ''';
        break;
      default:
        depthInstructions = '''
        **Depth: Light**
        1.  **Focus on Essentials:** Extract only main points and core concepts.
        2.  **Use Bullet Points:** Heavily rely on lists for quick information delivery.
        3.  **No Frills:** Avoid long explanations and examples.
        ''';
    }

    final prompt = '''
      **Persona:** You are a world-class educator. Your goal is to create exceptionally clear, engaging, and well-structured study summaries.

      **Task:** Analyze the source text and generate a study summary. The summary MUST cover 100% of the source text's information.

      $depthInstructions

      **Formatting Rules (Strictly Enforce):**
      1.  **Main Title:** Start with a single H1 title: `# [Main Topic Title]`.
      2.  **Key Takeaways:** Add an `## 🌟 Key Takeaways` section.
      3.  **Topics:** Use `## 💡 [Topic Name]`.
      4.  **Sub-concepts:** Use `### ✨ [Sub-concept Name]`.
      5.  **Examples:** For explanations, use: `> **Explanatory Example:** ...`. For analogies, use: `> **Creative Analogy:** ...`
      6.  **Output:** Generate the summary in both Arabic and English within a single valid JSON object: `{"ar": "...", "en": "..."}`$customNotesSection

      **Source Text:**
      """$text"""
    ''';

    try {
      final response = await _generateContentWithRetry(
          [Content.text(prompt)], ModelType.pro, onKeyChanged);
      final cleanJson =
          response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final jsonResponse = jsonDecode(cleanJson);
      if(jsonResponse['ar'] == null || jsonResponse['en'] == null) {
        throw Exception("Generated summary is missing language content.");
      }
      return {
        'ar': jsonResponse['ar'],
        'en': jsonResponse['en'],
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<List<QuizQuestion>> generateQuiz(
      String text, String targetLanguage, AnalysisDepth depth,
      Function(int) onKeyChanged, {String? customNotes}) async {
    int questionCount;
    switch (depth) {
      case AnalysisDepth.deep:
        questionCount = 50;
        break;
      case AnalysisDepth.medium:
        questionCount = 30;
        break;
      case AnalysisDepth.light:
        questionCount = 15;
        break;
    }

    final limitedText = text.length > 50000 ? text.substring(0, 50000) + "..." : text;
    
    final customNotesSection = customNotes != null && customNotes.isNotEmpty
        ? '\n      **User Notes**: $customNotes'
        : '';
        
    final prompt = '''
      **Persona:** You are an expert psychometrician. Your task is to create questions that test deep conceptual understanding.

      **Task:** Generate exactly $questionCount high-quality quiz questions.

      **Strict Distribution:**
      * **80% Conceptual Understanding**
      * **20% Factual Recall**
      * **Difficulty:** 15% Very Hard, 35% Hard, 40% Medium, 10% Easy.

      **Requirements:**
      1.  4 plausible, distinct options per question.
      2.  Only one correct answer.
      3.  Generate in both Arabic and English.
      
      **JSON Output Format (Strict):**
      `{"questions": [{"questionAr":"…","optionsAr":["…"],"questionEn":"…","optionsEn":["…"],"correctAnswerIndex":0, "difficulty":"very_hard/hard/medium/easy"}]}`$customNotesSection
      
      **Source Text:**
      """$limitedText"""
    ''';
    try {
      final response = await _generateContentWithRetry([Content.text(prompt)], ModelType.pro, onKeyChanged);
      final cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final jsonResponse = jsonDecode(cleanJson);
      final List<dynamic> jsonList = jsonResponse['questions'];
      if(jsonList.isEmpty) {
        throw Exception("No questions were generated by the model.");
      }
      final questions = jsonList.map((item) => QuizQuestion.fromJson(item)).toList();
      return questions;
    } catch (e) {
      // **تعديل:** إعادة رمي الخطأ بدلاً من إرجاع قائمة فارغة
      rethrow;
    }
  }
  
  Future<List<Flashcard>> generateFlashcards(String text, String targetLanguage, AnalysisDepth depth, Function(int) onKeyChanged, {String? customNotes}) async {
    final customNotesSection = customNotes != null && customNotes.isNotEmpty
        ? '\n      **User Notes**: $customNotes'
        : '';
        
    final prompt = '''
      **Persona:** You are an expert exam creator.

      **Task:** Generate **as many high-value flashcards as possible** to cover all key information.

      **Strict Instructions:**
      1.  **Focus on Exam-Style Questions:** "Define...", "List...", "Explain...".
      2.  **CRITICAL:** For "List..." questions, format the answer as a Markdown list (`- item 1`).
      3.  **Clarity and Conciseness:** Direct questions, accurate answers.
      4.  **Bilingual Output:** Arabic and English.
      5.  **Format:** Return ONLY a valid JSON object: 
          `{"flashcards": [{"questionAr":"...","answerAr":"...","questionEn":"...","answerEn":"..."},...]}`$customNotesSection
          
      **Source Text:**
      """$text"""
    ''';
    try {
      final response = await _generateContentWithRetry([Content.text(prompt)], ModelType.pro, onKeyChanged);
      final cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final jsonResponse = jsonDecode(cleanJson);
      final List<dynamic> jsonList = jsonResponse['flashcards'];
       if(jsonList.isEmpty) {
        throw Exception("No flashcards were generated by the model.");
      }
      return jsonList.map((item) => Flashcard.fromJson(item)).toList();
    } catch (e) {
      // **تعديل:** إعادة رمي الخطأ بدلاً من إرجاع قائمة فارغة
      rethrow;
    }
  }
  
  Future<String> extractTextFromFile(File file, String customPrompt) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.path.split('/').last.toLowerCase();
      
      String mimeType;
      if (fileName.endsWith('.pdf')) {
        mimeType = 'application/pdf';
      } else if (fileName.endsWith('.docx')) {
        mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else if (fileName.endsWith('.pptx')) {
        mimeType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      } else if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else {
        mimeType = 'application/octet-stream';
      }
      
      final prompt = TextPart(customPrompt);
      final filePart = DataPart(mimeType, bytes);
      
      final response = await _generateContentWithRetry(
        [Content.multi([prompt, filePart])], 
        ModelType.flash,
        (index) {}
      );
      
      final extractedText = response.text ?? '';
      if (extractedText.trim().isEmpty) {
        throw Exception('Could not extract any text from the file.');
      }
      return extractedText;
    } catch (e) {
      throw Exception('Failed to analyze the file. It might be too large or corrupted.');
    }
  }
}

