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

  GenerativeModel _getModel(ModelType modelType) {
    if (geminiApiKeys.isEmpty || geminiApiKeys.first.contains('YOUR_API_KEY_HERE')) {
       throw Exception('Please add valid Gemini API keys in constants/api_keys.dart');
    }
    final apiKey = geminiApiKeys[_currentApiKeyIndex];
    
    final modelName = switch (modelType) {
      ModelType.pro   => 'gemini-2.5-pro',
      ModelType.flash => 'gemini-2.5-flash',
    };

    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.7, responseMimeType: 'application/json')
    );
  }

  Future<GenerateContentResponse> _generateContentWithRetry(
    List<Content> prompt,
    ModelType modelType,
    Function(int) onKeyChanged,
  ) async {
    int attempts = 0;
    while (attempts < geminiApiKeys.length) {
      try {
        onKeyChanged(_currentApiKeyIndex);
        final model = _getModel(modelType);
        final response = await model.generateContent(prompt);
        return response;
      } catch (e) {
        print("API Key #$_currentApiKeyIndex failed: $e");
        if (e.toString().contains('Quota') || e.toString().contains('exceeded')) {
           _currentApiKeyIndex = (_currentApiKeyIndex + 1) % geminiApiKeys.length;
           attempts++;
        } else {
          throw Exception('An error occurred during analysis: ${e.toString()}');
        }
       
        if (attempts >= geminiApiKeys.length) {
          throw Exception('All API keys have failed or reached their quota. Please try again later.');
        }
      }
    }
    throw Exception('An unexpected error occurred in the AI service.');
  }

  Future<Map<String, dynamic>> validateContent(String text, Function(int) onKeyChanged) async {
    final prompt = '''
      Analyze the following text. Determine if it is processable educational content.
      Content is processable if it is not gibberish, unclear, or clearly non-educational (like a food menu).
      The response must be only a valid JSON object in this format: {"is_study_material": true/false, "reason_ar": "Write the reason here in Arabic"}
      Text: """${text.substring(0, text.length > 1500 ? 1500 : text.length)}"""
    ''';
    try {
      final response = await _generateContentWithRetry([Content.text(prompt)], ModelType.flash, onKeyChanged);
      final cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanJson);
    } catch (e) {
      print("Error validating content: $e");
      return {"is_study_material": false, "reason_ar": "Failed to analyze content. There might be a connection issue."};
    }
  }

  Future<String> generateSummary(String text, String targetLanguage, AnalysisDepth depth, Function(int) onKeyChanged, {String? customNotes}) async {
    String prompt;
    final customNotesSection = customNotes != null && customNotes.isNotEmpty
        ? '\n          6.  **Special Instructions**: Pay special attention to the following user requirements: $customNotes'
        : '';
    
    switch (depth) {
      case AnalysisDepth.deep:
        prompt = '''
          Act as a university professor and an expert in simplifying science. Your goal is to explain the following material to a student in great depth and in an easy-to-read format.
          **Task**: Create an analytical, deep, and comprehensive summary.
          **Strict Instructions**:
          1.  **Deep Explanation**: Don't just provide definitions. Explain the "why" and "how" of each concept.
          2.  **Examples and Analogies**: For each main concept, provide a clear real-world example and an innovative analogy to solidify understanding.
          3.  **Clear Formatting**: Use Markdown effectively. Utilize headings (`## Main Title`, `### Subtitle`), bullet points (`- point`), and **bold text** for key terms to make the summary easy to read and study.
          4.  **Language**: The final summary must be exclusively in **$targetLanguage**.
          5.  **Output Format**: The entire output MUST be a single JSON object with one key "summary" containing the markdown string. Example: {"summary": "## Title\\n- Point 1..."}$customNotesSection
          **Text to summarize**: """$text"""
        ''';
        break;
      case AnalysisDepth.medium:
         prompt = '''
          **Task**: Create a balanced and well-formatted summary of the following text.
          **Instructions**:
          1.  Focus on explaining the core concepts clearly.
          2.  Use a simple example where necessary to clarify complex points.
          3.  Use a clear structure with headings (`##`), bullet points, and **bold text** for terms.
          4.  **Language**: The final summary must be exclusively in **$targetLanguage**.
          5.  **Output Format**: The entire output MUST be a single JSON object with one key "summary" containing the markdown string.$customNotesSection
          **Text to summarize**: """$text"""
        ''';
        break;
      case AnalysisDepth.light:
        prompt = '''
          **Task**: Create a quick and concise summary of the following text in the form of key points.
          **Instructions**:
          1.  Extract only the essential points and concepts.
          2.  Avoid long explanations or examples.
          3.  Use a structured bulleted list (`-`). Make key terms **bold**.
          4.  **Language**: The final summary must be exclusively in **$targetLanguage**.
          5.  **Output Format**: The entire output MUST be a single JSON object with one key "summary" containing the markdown string.$customNotesSection
          **Text to summarize**: """$text"""
        ''';
        break;
    }
     try {
      final response = await _generateContentWithRetry([Content.text(prompt)], ModelType.pro, onKeyChanged);
      final jsonResponse = jsonDecode(response.text!);
      return jsonResponse['summary'] ?? 'The AI could not generate a summary.';
    } catch (e) {
      rethrow;
    }
  }

  Future<List<QuizQuestion>> generateQuiz(String text, String targetLanguage, Function(int) onKeyChanged, {String? customNotes}) async {
    final customNotesSection = customNotes != null && customNotes.isNotEmpty
        ? '\n      5.  **Special Instructions**: Pay special attention to the following user requirements when creating questions: $customNotes'
        : '';
        
    final prompt = '''
      You are a professional educational test designer. Your task is to create a diverse question bank from the following text to measure different levels of understanding.
      **Task**: Create as many multiple-choice questions as possible (up to 50).
      **Strict Instructions**:
      1.  **Difficulty Distribution**: You must strictly follow this difficulty distribution:
          - **30% easy**: Direct questions testing recall of information.
          - **20% medium**: Questions requiring linking two pieces of information or a simple understanding of relationships.
          - **40% hard**: Application questions requiring the student to apply a concept to a new scenario.
          - **10% very_hard**: Inferential questions testing a very deep understanding of the material and requiring critical thinking.
      2.  **Smart Distractors**: The incorrect options (distractors) must be plausible and convincing, not obviously wrong.
      3.  **Language**: The test must be exclusively in **$targetLanguage**.
      4.  **Format**: Return the result only as a valid JSON object with one key "questions" which contains a JSON array. Each question must include a "difficulty" key with the value "easy", "medium", "hard", or "very_hard".
          `{"questions": [{"question":"...","options":["...","...","...","..."],"correctAnswerIndex":0, "difficulty":"easy"},...]}`$customNotesSection
      **Source Text**: """$text"""
    ''';
    try {
      final response = await _generateContentWithRetry([Content.text(prompt)], ModelType.pro, onKeyChanged);
      final jsonResponse = jsonDecode(response.text!);
      final List<dynamic> jsonList = jsonResponse['questions'];
      return jsonList.map((item) => QuizQuestion.fromJson(item)).toList();
    } catch (e) {
      print("Error parsing quiz: $e");
      return [];
    }
  }
  
  Future<String> extractTextFromImage(List<File> imageFiles) async {
    final prompt = TextPart("Extract all text from these images in order. Preserve the original structure, paragraphs, and language. Combine the text from all images into a single continuous block.");
    final imageParts = await Future.wait(imageFiles.map((file) async {
      final bytes = await file.readAsBytes();
      final mimeType = file.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      return DataPart(mimeType, bytes);
    }));
    
    try {
      final response = await _generateContentWithRetry(
        [Content.multi([prompt, ...imageParts])], 
        ModelType.flash, 
        (index) {}
      );
      return response.text ?? 'Could not read text from the image.';
    } catch (e) {
      print("Error extracting text from image: $e");
      throw Exception('Failed to analyze the image. It might be too large or corrupted.');
    }
  }
  
  // --- تعديل: تم تحديث الـ Prompt ليركز على أسئلة الاختبارات الشائعة ---
  Future<List<Flashcard>> generateFlashcards(String text, String targetLanguage, AnalysisDepth depth, Function(int) onKeyChanged, {String? customNotes}) async {
    final customNotesSection = customNotes != null && customNotes.isNotEmpty
        ? '\n      5.  **Special Instructions**: Pay special attention to the following user requirements when creating flashcards: $customNotes'
        : '';
        
    final prompt = '''
      You are an expert exam creator. Your task is to analyze the provided educational text and generate flashcards based on questions that are highly likely to appear in an exam.
      **Task**: Create as many relevant flashcards as possible (up to 50).
      **Strict Instructions**:
      1.  **Focus on Exam-Style Questions**: Prioritize creating questions that start with common exam keywords. Specifically look for opportunities to create questions like:
          - "Define..." (عرف...)
          - "List..." or "Enumerate..." (عدد... / اذكر...)
          - "Explain why..." (علل...)
          - "Explain briefly..." (اشرح باختصار...)
      2.  **Direct and Clear**: The question must be direct and unambiguous. The answer must be accurate and concise, directly addressing the question.
      3.  **Language**: The flashcards must be exclusively in **$targetLanguage**.
      4.  **Format**: Return the result ONLY as a valid JSON object with one key "flashcards" which contains a JSON array in this format: `{"flashcards": [{"question":"...","answer":"..."},...]}`$customNotesSection
      **Source Text**:
      """$text"""
    ''';
    try {
      final response = await _generateContentWithRetry([Content.text(prompt)], ModelType.pro, onKeyChanged);
      final jsonResponse = jsonDecode(response.text!);
      final List<dynamic> jsonList = jsonResponse['flashcards'];
      return jsonList.map((item) => Flashcard.fromJson(item)).toList();
    } catch (e) {
      print("Error parsing flashcards: $e");
      return [];
    }
  }
}

