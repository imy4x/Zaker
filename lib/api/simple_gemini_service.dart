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
      ModelType.pro   => 'gemini-1.5-pro', // Pro للعمليات المعقدة
      ModelType.flash => 'gemini-1.5-flash', // Flash للعمليات السريعة والرخيصة
    };

    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.5, responseMimeType: 'application/json') // Adjusted temperature for more factual output
    );
  }

  Future<GenerateContentResponse> _generateContentWithRetry(
    List<Content> prompt,
    ModelType modelType,
    Function(int) onKeyChanged,
  ) async {
    int attempts = 0;
    String lastError = '';
    
    while (attempts < geminiApiKeys.length) {
      try {
        onKeyChanged(_currentApiKeyIndex);
        final model = _getModel(modelType);
        
        // timeout قصير للاستجابة السريعة
        final response = await model.generateContent(prompt)
            .timeout(Duration(minutes: 2), onTimeout: () {
          throw Exception('انتهت مهلة الانتظار - تجربة مفتاح آخر');
        });
        
        print("نجحت العملية باستخدام API Key #$_currentApiKeyIndex");
        return response;
        
      } catch (e) {
        lastError = e.toString();
        print("API Key #$_currentApiKeyIndex فشل: $e");
        
        // فحص أنواع الأخطاء وتبديل المفاتيح حسب الحاجة
        if (_shouldSwitchApiKey(e.toString())) {
          print("تبديل إلى API Key التالي...");
          _currentApiKeyIndex = (_currentApiKeyIndex + 1) % geminiApiKeys.length;
          attempts++;
          
          // انتظار قصير قبل إعادة المحاولة
          await Future.delayed(Duration(milliseconds: 500));
          
        } else {
          // إذا لم يكن خطأ في المفتاح، ارمي الخطأ مباشرة
          throw Exception('خطأ في عملية التحليل: $lastError');
        }
      }
      
      // فحص إذا تم تجربة جميع المفاتيح
      if (attempts >= geminiApiKeys.length) {
        throw Exception('فشلت جميع مفاتيح API المتاحة. يرجى المحاولة لاحقاً. آخر خطأ: $lastError');
      }
    }
    
    throw Exception('حدث خطأ غير متوقع في خدمة الذكاء الاصطناعي.');
  }
  
  /// تحديد ما إذا كان يجب تبديل مفتاح API
  bool _shouldSwitchApiKey(String errorMessage) {
    final errorPatterns = [
      'Quota',
      'exceeded',
      'limit',
      'QUOTA_EXCEEDED',
      'RATE_LIMIT_EXCEEDED',
      'API_KEY_INVALID',
      'انتهت مهلة الانتظار',
      'timeout',
      '429',
      '403',
      '401'
    ];
    
    return errorPatterns.any((pattern) => 
        errorMessage.toLowerCase().contains(pattern.toLowerCase()));
  }

  /// تحقق من جودة المحتوى باستخدام Flash - محدث وأكثر مرونة
  Future<Map<String, dynamic>> validateContent(String text, Function(int) onKeyChanged) async {
    final prompt = '''
      تحليل هذا النص وتحديد ما إذا كان محتوى تعليمي قابل للمعالجة.
      
      **المحتوى المقبول:**
      • النصوص الأكاديمية والتعليمية
      • المحاضرات والملاحظات
      • النصوص التي تحتوي على رموز رياضية (مثل ''' + r"$" + ''', £, €, +, -, =, %, ÷)
      • النصوص التي تحتوي على معادلات وأرقام
      • المحتوى العلمي والتقني
      
      **المحتوى غير المقبول فقط:**
      • قوائم الطعام فقط
      • نصوص عشوائية بحتة
      • نصوص فارغة أو غير مترابطة
      • رسائل خطأ فقط
      
      يجب أن يكون الرد عبارة عن JSON صالح فقط: 
      {"is_study_material": true/false, "reason_ar": "السبب بالعربية"}
      
      **النص المراد تحليله:**
      """${text.substring(0, text.length > 2000 ? 2000 : text.length)}"""
    ''';
    try {
      final response = await _generateContentWithRetry([Content.text(prompt)], ModelType.flash, onKeyChanged);
      final cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanJson);
    } catch (e) {
      print("خطأ في تحليل المحتوى: $e");
      // في حالة الفشل، اقبل المحتوى افتراضياً
      return {"is_study_material": true, "reason_ar": "تم قبول المحتوى افتراضياً بعد فشل التحليل."};
    }
  }
  
  /// تنظيف وتحسين النصوص باستخدام Flash (أسرع وأرخص من Pro)
  Future<String> cleanTextWithAI(String rawText, Function(int) onKeyChanged) async {
    final prompt = '''
      أنت خبير تنظيف النصوص. مهمتك هي تنظيف هذا النص وإزالة العناصر غير الضرورية.
      
      **ما يجب حذفه:**
      • الرموز الغريبة وعلامات JSON
      • الأرقام المنفردة بدون سياق
      • التكرار والجمل غير المفيدة
      • علامات الترقيم الزائدة
      
      **ما يجب الاحتفاظ به:**
      • جميع المعلومات التعليمية
      • الشروح والتفاسير
      • الأرقام ذات المعنى
      • العناوين والتقسيمات
      
      **تعليمات مهمة:**
      - لا تغير المعنى أبداً
      - لا تلخص أو تختصر
      - احتفظ بجميع المعلومات المفيدة
      - فقط نظف ورتب النص
      
      **النص المطلوب تنظيفه:**
      """$rawText"""
      
      ارجع فقط النص النظيف بدون أي تعليق أو شرح.
    ''';
    
    try {
      final response = await _generateContentWithRetry([Content.text(prompt)], ModelType.flash, onKeyChanged);
      final cleanedText = response.text?.trim() ?? rawText;
      
      print('تم تنظيف النص باستخدام Flash - من ${rawText.length} إلى ${cleanedText.length} حرف');
      return cleanedText;
      
    } catch (e) {
      print('خطأ في تنظيف النص باستخدام Flash: $e');
      return rawText; // إرجاع النص الأصلي في حالة الفشل
    }
  }

  Future<Map<String, String>> generateSummary(String text, String targetLanguage, AnalysisDepth depth, Function(int) onKeyChanged, {String? customNotes}) async {
    String prompt;
    final customNotesSection = customNotes != null && customNotes.isNotEmpty
        ? '\n          **Special Instructions**: Pay special attention to the following user requirements: $customNotes'
        : '';
    
    switch (depth) {
      // --- START: NEW DEEP PROMPT ---
      case AnalysisDepth.deep:
        prompt = '''
          أنت مُحلل تعليمي خبير ومُدرس جامعي متخصص في تحليل المحتوى التعليمي بطريقة شاملة ومفصلة. مهمتك تحويل أي نص تعليمي إلى تحليل عميق يشرح كل صفحة وكل ملف بشكل منفصل ومترابط.

          --- **🎯 المهمة الأساسية: التحليل التفصيلي صفحة بصفحة** ---
          
          **القاعدة الذهبية**: عليك أن تتعامل مع النص كأنه رحلة تعليمية تأخذ الطالب من صفحة لأخرى، تشرح له ما يحدث في كل صفحة وكيف تتصل بما قبلها وما بعدها.

          **أسلوب التحليل المطلوب:**
          - إذا كان النص يحتوي على إشارات للصفحات (مثل "--- الصفحة 1 ---" أو "الصفحة الثانية")، فأشر إليها بوضوح
          - إذا كان هناك عدة ملفات، فاذكر اسم كل ملف ومحتوياته
          - استخدم عبارات مثل:
            * "في الصفحة الأولى، نجد أن..."
            * "تستمر الصفحة الثانية في شرح..."
            * "في الصفحة الثالثة، يبدأ موضوع جديد وهو..."
            * "الملف الأول يتناول..."
            * "في الملف الثاني، نلاحظ التطرق إلى..."

          --- **🔧 أدواتك للتحليل المتقدم** ---
          
          * **العناوين التدرجية (`#`, `##`, `###`)**: لتنظيم المحتوى حسب الصفحات والمواضيع
          * **التأكيد (`**عريض**`, `_مائل_`)**: للمصطلحات الهامة والتعريفات الأساسية
          * **القوائم (النقطية `-` والمرقمة `1.`)**: لترتيب التفاصيل والخطوات
          * **الاقتباسات المهمة (`>`)**: للنقاط الجوهرية والمبادئ الأساسية
          * **الجداول**: لمقارنة وتنظيم البيانات بشكل واضح
          * **التشبيهات والأمثلة الإبداعية**: اخترع تشبيهات بسيطة وأمثلة واقعية لتبسيط المفاهيم المعقدة
          * **التدفق السردي**: لا تكتفِ بسرد الحقائق، بل اربطها ببعضها واشرح لماذا هي مهمة

          --- **📋 التعليمات النهائية** ---
          1. **التحليل المفصل**: هدفك الأساسي هو الشمولية والوضوح، وليس الاختصار
          2. **البساطة مع التفصيل**: إذا كان المفهوم معقداً، فكّكه واشرحه بمصطلحات أبسط مع التشبيهات
          3. **الإشارة للمصادر**: اذكر بوضوح من أي صفحة أو ملف تأتي كل معلومة
          4. **الترابط**: اشرح كيف تتصل المعلومات في الصفحات ببعضها البعض
          5. **ثنائي اللغة**: أنتج التحليل الكامل بالعربية والإنجليزية بنفس جودة المحتوى والتنسيق
          6. **تنسيق JSON**: يجب أن يكون الناتج النهائي كائن JSON واحد صالح: `{"ar": "...", "en": "..."}`$customNotesSection

          **مثال على الأسلوب المطلوب:**
          "في الصفحة الأولى من هذا المادة، تم التطرق إلى مفهوم... حيث يُعرّف بأنه... وفي الصفحة الثانية، نلاحظ أن المؤلف قد أكمل الحديث عن... مضيفاً معلومات حول... أما في الصفحة الثالثة، فقد بدأ فصل جديد بعنوان... والذي يركز على..."

          **النص المصدري للتحليل**: """$text"""
        ''';
        break;
      // --- END: NEW DEEP PROMPT ---
      
      case AnalysisDepth.medium:
         prompt = '''
          You are an AI **Information Designer**. Your mission is to create a clear, structured, and visually organized summary. Focus on clarity and readability using predefined modules.

          --- **Information Design Toolkit** ---

          **1. Core Idea Module (For main topics)**
          Use this for the primary concepts in the text.
          `## [Concept Title]`
          `- **الجوهر:** A concise, one-sentence explanation of the concept.`
          `- **مثال توضيحي:** A simple, clear example to aid understanding.`
          
          **2. Key Points Module (For important details)**
          Use this to list supporting facts or important details.
          `### نقاط رئيسية`
          `- **[Point 1]:** [Brief detail]`
          `- **[Point 2]:** [Brief detail]`

          --- **Final Directives** ---
          - **Intelligent Selection**: Analyze the text and use the most appropriate modules to structure the information effectively.
          - **Clarity First**: Prioritize clear headings, bold text for key terms, and bullet points.
          - **Bilingual Output**: Produce the summary in both Arabic and English with the same high-quality formatting.
          - **JSON Format**: The entire output MUST be a single, valid JSON object with two keys: {"ar": "...", "en": "..."}$customNotesSection

          **Source Text**: """$text"""
        ''';
        break;
      
      case AnalysisDepth.light:
        prompt = '''
          You are an AI **Content Synthesizer**. Your task is to extract only the most critical bullet points and key takeaways from the text and present them in a clean, scannable, and visually appealing format.

          --- **Required Format: The "At-a-Glance" Module** ---
          You MUST use the following structure.

          `## أبرز النقاط (At-a-Glance)`
          `* A brief, impactful bullet point summarizing a key idea.`
          * Another essential point.`
          `* And another...`
          `---`
          `> **الخلاصة الأهم:** A single, powerful sentence that represents the absolute most critical takeaway from the entire text.`

          --- **Final Directives** ---
          - **Be Extremely Concise**: Only include the absolute essentials.
          - **Clean Professional Format**: Use clear formatting without emojis. The horizontal rule (`---`) and the blockquote (`>`) are mandatory.
          - **Bilingual Output**: Produce the summary in both Arabic and English, strictly following the specified format.
          - **JSON Format**: The entire output MUST be a single, valid JSON object: {"ar": "...", "en": "..."}$customNotesSection

          **Source Text**: """$text"""
        ''';
        break;
    }
     try {
      final response = await _generateContentWithRetry([Content.text(prompt)], ModelType.pro, onKeyChanged);
      final cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final jsonResponse = jsonDecode(cleanJson);
      
      // تحسين التنسيق للنصين العربي والإنجليزي
      final arabicSummary = _enhanceBilingualFormatting(jsonResponse['ar'] ?? 'لم يتمكن الذكاء الاصطناعي من إنشاء ملخص.', true);
      final englishSummary = _enhanceBilingualFormatting(jsonResponse['en'] ?? 'The AI could not generate a summary.', false);
      
      return {
        'ar': arabicSummary,
        'en': englishSummary,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<List<QuizQuestion>> generateQuiz(String text, String targetLanguage, Function(int) onKeyChanged, {String? customNotes}) async {
    // تقليل الحد إلى 10000 حرف لتسريع المعالجة
    if (text.length > 10000) {
      print('نص طويل: ${text.length} حرف - استخدام المعالجة السريعة');
      return await _generateQuizInChunks(text, targetLanguage, onKeyChanged, customNotes: customNotes);
    }
    
    print('نص قصير: ${text.length} حرف - معالجة مباشرة');
    return await _generateQuizSingle(text, targetLanguage, onKeyChanged, customNotes: customNotes);
  }
  
  /// إنشاء بنك أسئلة من نص واحد - محسن للسرعة مع Flash
  Future<List<QuizQuestion>> _generateQuizSingle(String text, String targetLanguage, Function(int) onKeyChanged, {String? customNotes}) async {
    // تقليل النص إلى 8000 حرف للسرعة
    final limitedText = text.length > 8000 ? text.substring(0, 8000) + "..." : text;
    
    final customNotesSection = customNotes != null && customNotes.isNotEmpty
        ? '\n      5.  **ملاحظات خاصة**: $customNotes'
        : '';
        
    final prompt = '''
      أنت مصمم اختبارات محترف. إنشاء أسئلة اختيار متعدد من النص التالي.
      **المهمة**: إنشاء 15 سؤال اختيار متعدد (بدلاً من 25 للسرعة)
      **التعليمات المبسطة**:
      1. **التنويع**: 40% أسئلة سهلة، 35% متوسطة، 25% صعبة
      2. **الخيارات**: 4 خيارات لكل سؤال، واحد صحيح و3 خاطئة معقولة
      3. **اللغتان**: كل سؤال بالعربية والإنجليزية
      4. **التنسيق**: JSON فقط بهذا الشكل:
          {"questions": [{"questionAr":"...","optionsAr":["...","...","...","..."],"questionEn":"...","optionsEn":["...","...","...","..."],"correctAnswerIndex":0, "difficulty":"easy"}]}$customNotesSection
      
      **النص المصدر (أول 8000 حرف)**: """$limitedText"""
    ''';
    try {
      print('إنشاء بنك أسئلة باستخدام Flash للسرعة (15 سؤال)');
      final response = await _generateContentWithRetry([Content.text(prompt)], ModelType.flash, onKeyChanged);
      final cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final jsonResponse = jsonDecode(cleanJson);
      final List<dynamic> jsonList = jsonResponse['questions'];
      final questions = jsonList.map((item) => QuizQuestion.fromJson(item)).toList();
      print('تم إنشاء ${questions.length} سؤال بنجاح');
      return questions;
    } catch (e) {
      print("خطأ في معالجة بنك الأسئلة: $e");
      return [];
    }
  }
  
  /// إنشاء بنك أسئلة من نص طويل بالتقسيم للتسريع
  Future<List<QuizQuestion>> _generateQuizInChunks(String text, String targetLanguage, Function(int) onKeyChanged, {String? customNotes}) async {
    print('بدء إنشاء بنك أسئلة بطريقة متطورة (نص طويل)');
    
    // تقسيم النص إلى أجزاء ذكية مع حد أقصى للسرعة
    final allChunks = _splitTextForQuiz(text);
    final chunks = allChunks.length > 3 ? allChunks.take(3).toList() : allChunks; // حد أقصى 3 أجزاء
    print('استخدام ${chunks.length} جزء من أصل ${allChunks.length} للسرعة');
    
    final List<QuizQuestion> allQuestions = [];
    final List<Future<List<QuizQuestion>>> futures = [];
    
    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final questionsPerChunk = (15 / chunks.length).ceil(); // تقليل عدد الأسئلة للسرعة 15 بدلاً من 25
      
      final customNotesSection = customNotes != null && customNotes.isNotEmpty
          ? '\n      5.  **Special Instructions**: Pay special attention to the following user requirements when creating questions: $customNotes'
          : '';
      
      final prompt = '''
        إنشاء $questionsPerChunk سؤال اختيار متعدد من هذا النص.
        **التعليمات المبسطة**:
        1. 4 خيارات لكل سؤال (واحد صحيح)
        2. بالعربية والإنجليزية
        3. JSON فقط: {"questions": [{"questionAr":"...","optionsAr":["","","",""],"questionEn":"...","optionsEn":["","","",""],"correctAnswerIndex":0}]}$customNotesSection
        
        **القسم ${i + 1} (مقلم للسرعة)**: """${chunk.length > 4000 ? chunk.substring(0, 4000) + "..." : chunk}"""
      ''';
      
      futures.add(_generateQuizFromPrompt(prompt, onKeyChanged));
    }
    
    try {
      // تنفيذ متوازي لجميع الأجزاء
      final List<List<QuizQuestion>> results = await Future.wait(futures);
      
      // جمع جميع الأسئلة
      for (final chunkQuestions in results) {
        allQuestions.addAll(chunkQuestions);
      }
      
      print('تم إنشاء ${allQuestions.length} سؤال من ${chunks.length} قسم');
      
      // خلط الأسئلة لتنويع الترتيب
      allQuestions.shuffle();
      
      return allQuestions;
      
    } catch (e) {
      print('خطأ في المعالجة المتوازية: $e');
      // في حالة الفشل، ارجع للطريقة البطيئة
      return await _generateQuizSequentially(chunks, targetLanguage, onKeyChanged, customNotes: customNotes);
    }
  }
  
  /// تقسيم النص لبنك الأسئلة - محسن للسرعة
  List<String> _splitTextForQuiz(String text) {
    final chunks = <String>[];
    final maxChunkSize = 5000; // تقليل الحجم للسرعة من 8000 إلى 5000
    
    if (text.length <= maxChunkSize) {
      return [text];
    }
    
    // تقسيم بناءً على الفقرات
    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    final StringBuffer currentChunk = StringBuffer();
    
    for (final paragraph in paragraphs) {
      if ((currentChunk.length + paragraph.length) < maxChunkSize) {
        if (currentChunk.isNotEmpty) {
          currentChunk.writeln('\n');
        }
        currentChunk.writeln(paragraph);
      } else {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.toString());
          currentChunk.clear();
        }
        currentChunk.writeln(paragraph);
      }
    }
    
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.toString());
    }
    
    print('تم تقسيم النص إلى ${chunks.length} قسم لبنك الأسئلة');
    return chunks;
  }
  
  /// إنشاء أسئلة من prompt محدد
  Future<List<QuizQuestion>> _generateQuizFromPrompt(String prompt, Function(int) onKeyChanged) async {
    try {
      final response = await _generateContentWithRetry([Content.text(prompt)], ModelType.flash, onKeyChanged);
      final cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final jsonResponse = jsonDecode(cleanJson);
      final List<dynamic> jsonList = jsonResponse['questions'];
      return jsonList.map((item) => QuizQuestion.fromJson(item)).toList();
    } catch (e) {
      print('خطأ في إنشاء أسئلة من قسم: $e');
      return [];
    }
  }
  
  /// معالجة تتابعية للعودة في حالة فشل المعالجة المتوازية
  Future<List<QuizQuestion>> _generateQuizSequentially(List<String> chunks, String targetLanguage, Function(int) onKeyChanged, {String? customNotes}) async {
    print('العودة للمعالجة التتابعية لبنك الأسئلة');
    final List<QuizQuestion> allQuestions = [];
    
    for (int i = 0; i < chunks.length && i < 3; i++) { // حدد ب 3 أجزاء لتجنب البطء
      final questions = await _generateQuizSingle(chunks[i], targetLanguage, onKeyChanged, customNotes: customNotes);
      allQuestions.addAll(questions);
    }
    
    return allQuestions;
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
  
  Future<List<Flashcard>> generateFlashcards(String text, String targetLanguage, AnalysisDepth depth, Function(int) onKeyChanged, {String? customNotes}) async {
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
      final response = await _generateContentWithRetry([Content.text(prompt)], ModelType.pro, onKeyChanged);
      final jsonResponse = jsonDecode(response.text!);
      final List<dynamic> jsonList = jsonResponse['flashcards'];
      return jsonList.map((item) => Flashcard.fromJson(item)).toList();
    } catch (e) {
      print("Error parsing flashcards: $e");
      return [];
    }
  }
  
  /// تحسين التنسيق للنصوص ثنائية اللغة
  String _enhanceBilingualFormatting(String text, bool isArabic) {
    if (text.trim().isEmpty) return text;
    
    String enhanced = text;
    
    // إزالة الإيموجي بالكامل
    enhanced = _removeEmojis(enhanced);
    
    // تنظيف علامات الترقيم والمسافات
    enhanced = _cleanPunctuationAndSpaces(enhanced, isArabic);
    
    // تحسين تنسيق Markdown
    enhanced = _improveMarkdownFormatting(enhanced);
    
    // تنظيف نهائي
    enhanced = _finalCleanup(enhanced);
    
    return enhanced;
  }
  
  /// إزالة جميع الإيموجي
  String _removeEmojis(String text) {
    // إزالة الإيموجي الأساسية
    return text.replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true), '') // وجوه تعبيرية
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F5FF}]', unicode: true), '') // رموز وأشياء
        .replaceAll(RegExp(r'[\u{1F680}-\u{1F6FF}]', unicode: true), '') // وسائل نقل ورموز
        .replaceAll(RegExp(r'[\u{1F700}-\u{1F77F}]', unicode: true), '') // رموز الكيمياء
        .replaceAll(RegExp(r'[\u{1F780}-\u{1F7FF}]', unicode: true), '') // رموز جغرافية
        .replaceAll(RegExp(r'[\u{1F800}-\u{1F8FF}]', unicode: true), '') // رموز إضافية
        .replaceAll(RegExp(r'[\u{1F900}-\u{1F9FF}]', unicode: true), '') // رموز تعبيرية وأشياء
        .replaceAll(RegExp(r'[\u{1FA00}-\u{1FA6F}]', unicode: true), '') // رموز رياضية
        .replaceAll(RegExp(r'[\u{1FA70}-\u{1FAFF}]', unicode: true), '') // رموز تعبيرية ممتدة
        .replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '') // رموز متنوعة
        .replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), '') // رموز Dingbats
        .replaceAll(RegExp(r'[⚡⭐✨❤️✍️🎯💡💪🔥🚀🎆]'), '') // رموز شائعة
        .trim();
  }
  
  /// تنظيف علامات الترقيم والمسافات
  String _cleanPunctuationAndSpaces(String text, bool isArabic) {
    String cleaned = text;
    
    if (isArabic) {
      // علامات الترقيم العربية
      cleaned = cleaned
          // تصحيح الفواصل وعلامات الاستفهام
          .replaceAll(',', '،')  // فاصلة عربية
          .replaceAll('?', '؟')  // علامة استفهام عربية
          .replaceAll(';', '؛')  // فاصلة منقوطة عربية
          // إزالة مسافة قبل علامات الترقيم العربية
          .replaceAll(RegExp(r'\s+([،؟؛۔])'), r'$1')
          // إضافة مسافة بعد علامات الترقيم إذا لزم الأمر
          .replaceAll(RegExp(r'([،؟؛۔])([^ \s])'), r'$1 $2');
    } else {
      // علامات الترقيم الإنجليزية
      cleaned = cleaned
          // إزالة مسافة قبل علامات الترقيم الإنجليزية
          .replaceAll(RegExp(r'\s+([,.!?;:])'), r'$1')
          // إضافة مسافة بعد علامات الترقيم إذا لزم الأمر
          .replaceAll(RegExp(r'([,.!?;:])([^\s])'), r'$1 $2');
    }
    
    return cleaned;
  }
  
  /// تحسين تنسيق Markdown
  String _improveMarkdownFormatting(String text) {
    return text
        // تصحيح العناوين - إزالة مسافة زائدة بعد #
        .replaceAll(RegExp(r'(#{1,6})\s+'), r'$1 ')
        
        // تصحيح النص العريض - إزالة مسافات زائدة حول **
        .replaceAll(RegExp(r'\s*\*\*\s*([^*]+?)\s*\*\*\s*'), r' **$1** ')
        
        // تصحيح القوائم - ضمان وجود مسافة واحدة بعد -
        .replaceAll(RegExp(r'^(\s*)-\s+', multiLine: true), r'$1- ')
        
        // تصحيح الاقتباسات - ضمان وجود مسافة واحدة بعد >
        .replaceAll(RegExp(r'^(\s*)>\s+', multiLine: true), r'$1> ');
  }
  
  /// تنظيف نهائي
  String _finalCleanup(String text) {
    return text
        // إزالة مسافات زائدة في بداية ونهاية الأسطر
        .replaceAll(RegExp(r'^\s+|\s+$', multiLine: true), '')
        
        // إزالة مسافات متعددة في وسط النص
        .replaceAll(RegExp(r' {2,}'), ' ')
        
        // إزالة أسطر فارغة زائدة
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        
        .trim();
  }
}
