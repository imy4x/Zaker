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
    if (geminiApiKeys.isEmpty ||
        geminiApiKeys.first.contains('YOUR_API_KEY_HERE')) {
      throw Exception(
          'Please add valid Gemini API keys in constants/api_keys.dart');
    }
    final apiKey = geminiApiKeys[_currentApiKeyIndex];

    final modelName = switch (modelType) {
      ModelType.pro => 'gemini-2.5-pro',
      ModelType.flash => 'gemini-2.5-flash',
    };

    return GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
            temperature: 0.7, responseMimeType: 'application/json'));
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
        if (e.toString().contains('Quota') ||
            e.toString().contains('exceeded')) {
          _currentApiKeyIndex =
              (_currentApiKeyIndex + 1) % geminiApiKeys.length;
          attempts++;
        } else {
          throw Exception('An error occurred during analysis: ${e.toString()}');
        }

        if (attempts >= geminiApiKeys.length) {
          throw Exception(
              'All API keys have failed or reached their quota. Please try again later.');
        }
      }
    }
    throw Exception('An unexpected error occurred in the AI service.');
  }

  Future<Map<String, dynamic>> validateContent(
      String text, Function(int) onKeyChanged) async {
    final prompt = '''
      Analyze the following text. Determine if it is processable educational content.
      Content is processable if it is not gibberish, unclear, or clearly non-educational (like a food menu).
      The response must be only a valid JSON object in this format: {"is_study_material": true/false, "reason_ar": "Write the reason here in Arabic"}
      Text: """${text.substring(0, text.length > 1500 ? 1500 : text.length)}"""
    ''';
    try {
      final response = await _generateContentWithRetry(
          [Content.text(prompt)], ModelType.flash, onKeyChanged);
      final cleanJson =
          response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanJson);
    } catch (e) {
      print("Error validating content: $e");
      return {
        "is_study_material": false,
        "reason_ar":
            "Failed to analyze content. There might be a connection issue."
      };
    }
  }

  // وظيفة تحليل نوع المحتوى التعليمي
  Future<Map<String, String>> _analyzeContentType(
      String text, Function(int) onKeyChanged) async {
    final analysisPrompt = '''
      Analyze the following educational text and determine its primary academic subject type and characteristics.
      
      **Analysis Task**: Identify the content type and provide specific guidance for optimal educational summarization.
      
      **Instructions**:
      1. Determine the primary subject category from: Scientific, Mathematical, Literary, Historical, Philosophical, Social Sciences, Technical/Engineering, Medical, Business, Arts, Language Learning, Other
      2. Identify key characteristics that should influence the summary approach
      3. Suggest specific elements that should be emphasized in the summary
      
      **Required JSON Format**:
      {
        "type": "[Primary Subject Category]",
        "characteristics": "[Key content characteristics]",
        "summary_focus": "[What should be emphasized in the summary]",
        "examples_needed": "[Type of examples that would be most helpful]",
        "complexity_level": "[Beginner/Intermediate/Advanced]"
      }
      
      **Text to Analyze**: """${text.length > 1000 ? text.substring(0, 1000) : text}..."""
    ''';

    try {
      final response = await _generateContentWithRetry(
          [Content.text(analysisPrompt)], ModelType.flash, onKeyChanged);
      final cleanJson =
          response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final analysisResult = jsonDecode(cleanJson);

      return {
        'type': analysisResult['type'] ?? 'General Academic',
        'characteristics':
            analysisResult['characteristics'] ?? 'Standard educational content',
        'summary_focus': analysisResult['summary_focus'] ??
            'Core concepts and key information',
        'examples_needed':
            analysisResult['examples_needed'] ?? 'Practical examples',
        'complexity_level': analysisResult['complexity_level'] ?? 'Intermediate'
      };
    } catch (e) {
      print("Error analyzing content type: $e");
      // القيم الافتراضية في حالة فشل التحليل
      return {
        'type': 'General Academic',
        'characteristics': 'Educational content requiring structured summary',
        'summary_focus': 'Core concepts and essential information',
        'examples_needed': 'Relevant practical examples',
        'complexity_level': 'Intermediate'
      };
    }
  }

  Future<Map<String, String>> generateSummary(String text,
      String targetLanguage, AnalysisDepth depth, Function(int) onKeyChanged,
      {String? customNotes}) async {
    // أولاً نحلل نوع المحتوى لتخصيص الملخص
    final contentAnalysis = await _analyzeContentType(text, onKeyChanged);

    String prompt;
    final customNotesSection = customNotes != null && customNotes.isNotEmpty
        ? '\n          7.  **Special Instructions**: Pay special attention to the following user requirements: $customNotes'
        : '';

    switch (depth) {
      case AnalysisDepth.deep:
        prompt = '''
          Act as a distinguished university professor and expert educational content creator. Based on the content analysis, this text is identified as: ${contentAnalysis['type']} content.
          **Enhanced Mission**: Create a comprehensive, intellectually enriching summary that transforms complex information into accessible knowledge.
          **Advanced Instructions**:
          1.  **Contextual Understanding**: Begin with contextual background that sets the stage for deeper learning.
          2.  **Multi-Layer Explanation**: 
              - **Foundation Layer**: Essential concepts and definitions with etymological insights where relevant
              - **Connection Layer**: How concepts interrelate and build upon each other
              - **Application Layer**: Real-world applications, case studies, and practical examples
              - **Critical Analysis Layer**: Implications, significance, and potential limitations or controversies
          3.  **Enhanced Examples Strategy**: 
              - Provide 2-3 real-world examples per major concept
              - Include both historical and contemporary examples
              - Use analogies that bridge familiar experiences to complex concepts
              - Add "What if?" scenarios for deeper thinking
          4.  **Perfect Academic Formatting**: 
              - Start with `## 🎯 Overview` (2-3 compelling lines)
              - Use `## 📚 Core Concepts` for fundamental ideas
              - Use `### 🔬 Deep Dive:` [Concept Name] for detailed exploration
              - Use `#### 💡 Key Insight:` for crucial understanding points
              - Use `#### 🌍 Real-World Application:` for practical examples
              - Use `#### 🤔 Critical Thinking:` for analysis and implications
              - Use `**★ Essential Term**:` for critical definitions
              - Use `**🔗 Connection**:` to link concepts
              - Add `---` between major sections
              - End with `## 🎯 Mastery Summary` with 5-7 key mastery points
              - Include `## 📖 Further Exploration` with suggested areas for deeper study
          5.  **Adaptive Content Approach**: Adjust explanation style based on content type (scientific, literary, historical, mathematical, etc.)
          6.  **Bilingual Excellence**: Create parallel high-quality content in both Arabic and English, ensuring cultural and linguistic appropriateness.
          7.  **Output Format**: Return ONLY a valid JSON object: {"ar": "Arabic summary...", "en": "English summary..."}$customNotesSection
          **Source Material**: """$text"""
        ''';
        break;
      case AnalysisDepth.medium:
        prompt = '''
          Act as an expert educator creating balanced educational content. This text is identified as: ${contentAnalysis['type']} content.
          **Enhanced Task**: Create a well-structured, comprehensive yet accessible summary that bridges understanding gaps.
          **Strategic Instructions**:
          1.  **Smart Content Balance**: Provide sufficient detail for understanding without overwhelming complexity.
          2.  **Targeted Examples**: Include 1-2 well-chosen examples per major concept that illuminate rather than complicate.
          3.  **Progressive Structure**:
              - Start with `## 🎯 Introduction` (brief context setting)
              - Use `## 📖 Core Knowledge` for main concepts
              - Use `### 🔑 Key Concept:` [Name] for important ideas
              - Use `#### 💡 Understanding:` for explanations
              - Use `#### 🌟 Example:` for practical illustrations
              - Use `**⚡ Important**:` for critical points
              - Use `**🔗 Note**:` for connecting information
              - Add logical section breaks with `---`
              - End with `## ✅ Essential Takeaways` (4-6 main points)
              - Include `## 🎓 Quick Review` with bullet points for revision
          4.  **Content-Adaptive Approach**: Tailor explanation methods to match the subject type (scientific formulas, historical context, literary analysis, etc.)
          5.  **Bilingual Proficiency**: Ensure both Arabic and English versions maintain equal educational value and cultural relevance.
          6.  **Output Format**: Return ONLY a valid JSON object: {"ar": "Arabic summary...", "en": "English summary..."}$customNotesSection
          **Source Material**: """$text"""
        ''';
        break;
      case AnalysisDepth.light:
        prompt = '''
          Act as a concise educational expert. This content is identified as: ${contentAnalysis['type']} material.
          **Mission**: Create focused, high-impact bullet points that capture essential knowledge for quick learning and review.
          **Precision Instructions**:
          1.  **Strategic Extraction**: Identify and extract only the most crucial concepts that students absolutely must know.
          2.  **Clarity Over Brevity**: Each point should be concise but complete enough to be understood independently.
          3.  **Optimized Quick Format**:
              - Start with `## ⚡ Essential Knowledge`
              - Use `### 🎯 [Topic Area]` for different subject areas
              - Use `• **🔑 [Key Term]**: [Concise but complete explanation]`
              - Use `• **📌 Remember**: [Critical fact or rule]`
              - Use `• **⭐ Important**: [Significant concept or principle]`
              - Keep explanations to 1-2 lines but ensure completeness
              - End with `## 🚀 Quick Mastery Check` (3-5 must-know points)
              - Add `## 📋 Study Tips` with 2-3 memory aids or study strategies
          4.  **Content-Specific Focus**: Adapt the extraction approach based on subject type (formulas for math/science, dates for history, techniques for literature, etc.)
          5.  **Bilingual Efficiency**: Provide equally valuable quick-reference content in both languages.
          6.  **Output Format**: Return ONLY a valid JSON object: {"ar": "Arabic summary...", "en": "English summary..."}$customNotesSection
          **Source Material**: """$text"""
        ''';
        break;
    }
    try {
      final response = await _generateContentWithRetry(
          [Content.text(prompt)], ModelType.pro, onKeyChanged);

      // تنظيف وتحليل الاستجابة مع معالجة أفضل للأخطاء
      String responseText = response.text ?? '';
      responseText = _cleanJsonResponse(responseText);

      final jsonResponse = jsonDecode(responseText);

      // التحقق من جودة المحتوى وإضافة تنويع
      final arSummary = jsonResponse['ar'] ?? '';
      final enSummary = jsonResponse['en'] ?? '';

      // إضافة تحسينات تلقائية للملخص إذا لزم الأمر
      return {
        'ar': _enhanceSummary(arSummary, 'ar', contentAnalysis) ??
            'لم يتمكن الذكاء الاصطناعي من إنشاء ملخص عربي. يرجى المحاولة مرة أخرى.',
        'en': _enhanceSummary(enSummary, 'en', contentAnalysis) ??
            'The AI could not generate an English summary. Please try again.',
      };
    } catch (e) {
      print("Error generating summary: $e");

      // استراتيجية احتياطية لمعالجة الأخطاء
      return _generateFallbackSummary(text, contentAnalysis, depth);
    }
  }

  Future<List<QuizQuestion>> generateQuiz(
      String text, String targetLanguage, Function(int) onKeyChanged,
      {String? customNotes}) async {
    final customNotesSection = customNotes != null && customNotes.isNotEmpty
        ? '\n      5.  **Special Instructions**: Pay special attention to the following user requirements when creating questions: $customNotes'
        : '';

    final prompt = '''
      You are a professional educational test designer. Your task is to create a diverse question bank from the following text to measure different levels of understanding.
      **Task**: Create as many multiple-choice questions as possible (up to 50) in both Arabic and English.
      **Strict Instructions**:
      1.  **Difficulty Distribution**: You must strictly follow this difficulty distribution:
          - **30% easy**: Direct questions testing recall of information.
          - **20% medium**: Questions requiring linking two pieces of information or a simple understanding of relationships.
          - **40% hard**: Application questions requiring the student to apply a concept to a new scenario.
          - **10% very_hard**: Inferential questions testing a very deep understanding of the material and requiring critical thinking.
      2.  **Smart Distractors**: The incorrect options (distractors) must be plausible and convincing, not obviously wrong.
      3.  **Bilingual Output**: Create each question and all options in both Arabic and English with the same content quality.
      4.  **Format**: Return the result only as a valid JSON object with one key "questions" which contains a JSON array. Each question must include a "difficulty" key.
          `{"questions": [{"questionAr":"...","optionsAr":["...","...","...","..."],"questionEn":"...","optionsEn":["...","...","...","..."],"correctAnswerIndex":0, "difficulty":"easy"},...]}`$customNotesSection
      **Source Text**: """$text"""
    ''';
    try {
      final response = await _generateContentWithRetry(
          [Content.text(prompt)], ModelType.pro, onKeyChanged);
      final jsonResponse = jsonDecode(response.text!);
      final List<dynamic> jsonList = jsonResponse['questions'];
      return jsonList.map((item) => QuizQuestion.fromJson(item)).toList();
    } catch (e) {
      print("Error parsing quiz: $e");
      return [];
    }
  }

  Future<String> extractTextFromImage(List<File> imageFiles) async {
    final prompt = TextPart(
        "Extract all text from these images in order. Preserve the original structure, paragraphs, and language. Combine the text from all images into a single continuous block.");
    final imageParts = await Future.wait(imageFiles.map((file) async {
      final bytes = await file.readAsBytes();
      final mimeType =
          file.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      return DataPart(mimeType, bytes);
    }));

    try {
      final response = await _generateContentWithRetry([
        Content.multi([prompt, ...imageParts])
      ], ModelType.flash, (index) {});
      return response.text ?? 'Could not read text from the image.';
    } catch (e) {
      print("Error extracting text from image: $e");
      throw Exception(
          'Failed to analyze the image. It might be too large or corrupted.');
    }
  }

  // --- تعديل: تم تحديث الـ Prompt ليركز على أسئلة الاختبارات الشائعة ---
  Future<List<Flashcard>> generateFlashcards(String text, String targetLanguage,
      AnalysisDepth depth, Function(int) onKeyChanged,
      {String? customNotes}) async {
    final customNotesSection = customNotes != null && customNotes.isNotEmpty
        ? '\n      5.  **Special Instructions**: Pay special attention to the following user requirements when creating flashcards: $customNotes'
        : '';

    final prompt = '''
      You are an expert exam creator. Your task is to analyze the provided educational text and generate flashcards based on questions that are highly likely to appear in an exam.
      **Task**: Create as many relevant flashcards as possible (up to 50) in both Arabic and English.
      **Strict Instructions**:
      1.  **Focus on Exam-Style Questions**: Prioritize creating questions that start with common exam keywords. Specifically look for opportunities to create questions like:
          - "Define..." (عرف...)
          - "List..." or "Enumerate..." (عدد... / اذكر...)
          - "Explain why..." (علل...)
          - "Explain briefly..." (اشرح باختصار...)
      2.  **Direct and Clear**: The question must be direct and unambiguous. The answer must be accurate and concise, directly addressing the question.
      3.  **Bilingual Output**: Create each flashcard in both Arabic and English with the same content quality.
      4.  **Format**: Return the result ONLY as a valid JSON object with one key "flashcards" which contains a JSON array in this format: `{"flashcards": [{"questionAr":"...","answerAr":"...","questionEn":"...","answerEn":"..."},...]}`$customNotesSection
      **Source Text**:
      """$text"""
    ''';
    try {
      final response = await _generateContentWithRetry(
          [Content.text(prompt)], ModelType.pro, onKeyChanged);
      final jsonResponse = jsonDecode(response.text!);
      final List<dynamic> jsonList = jsonResponse['flashcards'];
      return jsonList.map((item) => Flashcard.fromJson(item)).toList();
    } catch (e) {
      print("Error parsing flashcards: $e");
      return [];
    }
  }

  // وظائف مساعدة لتحسين جودة الملخصات
  String _cleanJsonResponse(String response) {
    return response
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .replaceAll('\n```', '')
        .replaceAll('```\n', '')
        .trim();
  }

  String? _enhanceSummary(
      String summary, String language, Map<String, String> contentAnalysis) {
    if (summary.isEmpty || summary.length < 50) {
      return null; // إرجاع null إذا كان الملخص قصير جداً أو فارغ
    }

    // إضافة تحسينات بسيطة وفقاً لنوع المحتوى
    String enhancedSummary = summary;

    // إضافة رأس توضيحي بناءً على نوع المحتوى إذا لم يكن موجوداً
    if (!summary.contains('##') && !summary.contains('#')) {
      final typeTitle = language == 'ar'
          ? _getArabicSubjectTitle(
              contentAnalysis['type'] ?? 'General Academic')
          : '## 📚 ${contentAnalysis['type']} Summary';
      enhancedSummary = '$typeTitle\n\n$summary';
    }

    return enhancedSummary;
  }

  String _getArabicSubjectTitle(String type) {
    switch (type.toLowerCase()) {
      case 'scientific':
        return '## 🔬 ملخص علمي';
      case 'mathematical':
        return '## 📐 ملخص رياضي';
      case 'literary':
        return '## 📖 ملخص أدبي';
      case 'historical':
        return '## 🏛️ ملخص تاريخي';
      case 'philosophical':
        return '## 💭 ملخص فلسفي';
      case 'social sciences':
        return '## 🏫 ملخص علوم اجتماعية';
      case 'technical/engineering':
        return '## ⚙️ ملخص تقني';
      case 'medical':
        return '## ⚕️ ملخص طبي';
      case 'business':
        return '## 💼 ملخص إداري';
      case 'arts':
        return '## 🎨 ملخص فني';
      case 'language learning':
        return '## 🗣️ ملخص لغوي';
      default:
        return '## 📚 ملخص تعليمي';
    }
  }

  Map<String, String> _generateFallbackSummary(
      String text, Map<String, String> contentAnalysis, AnalysisDepth depth) {
    final textPreview =
        text.length > 200 ? '${text.substring(0, 200)}...' : text;

    final fallbackAr = '''
## ⚠️ ملخص احتياطي

### 📋 محتوى النص
نوع المحتوى: ${contentAnalysis['type']}

### 📝 المعلومات المتوفرة
$textPreview

### 💡 ملاحظة
حدث خطأ تقني أثناء إنشاء الملخص الكامل. يرجى المحاولة مرة أخرى أو تقسيم النص إلى أجزاء أصغر.

### 🔄 اقتراحات
• تأكد من وضوح النص وخلوه من الأخطاء
• جرب تقسيم النص إلى فقرات أصغر
• تحقق من اتصال الإنترنت
    ''';

    final fallbackEn = '''
## ⚠️ Fallback Summary

### 📋 Content Information
Content Type: ${contentAnalysis['type']}

### 📝 Available Information
$textPreview

### 💡 Note
A technical error occurred while generating the complete summary. Please try again or split the text into smaller parts.

### 🔄 Suggestions
• Ensure the text is clear and error-free
• Try splitting the text into smaller paragraphs
• Check your internet connection
    ''';

    return {
      'ar': fallbackAr,
      'en': fallbackEn,
    };
  }
}
