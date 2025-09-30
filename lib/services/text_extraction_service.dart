import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:zaker/api/simple_gemini_service.dart';

class TextExtractionService {
  final GeminiService _aiService = GeminiService();
  
  // حدود معالجة النصوص (بالأحرف)
  static const int maxChunkSize = 800000; // 800K حرف لضمان عدم تجاوز حدود Gemini
  static const int minChunkSize = 50000;  // 50K حرف لضمان كفاءة المعالجة

  /// استخراج متطور للنصوص مع نظام التحليل المزدوج (صفحات + شامل)
  Future<Map<String, String>> extractTextFromMultipleFilesAdvanced(List<PlatformFile> files) async {
    final StringBuffer pageBasedText = StringBuffer();  // للملخصات
    final StringBuffer comprehensiveText = StringBuffer(); // للبطاقات والاختبارات
    
    int fileIndex = 0;
    final bool isMultipleFiles = files.length > 1;

    for (final file in files) {
      fileIndex++;
      try {
        final extension = file.extension?.toLowerCase();
        File actualFile = File(file.path!);
        
        print('معالجة الملف $fileIndex: ${file.name} (نظام مزدوج)');

        if (extension == 'pdf') {
          // استخراج نوعين من النص من PDF
          final pageBasedResult = await _extractAndProcessPdfWithPages(actualFile, file.name, fileIndex, isMultipleFiles);
          final comprehensiveResult = await _extractAndProcessPdf(actualFile);
          
          if (pageBasedResult.trim().isNotEmpty) {
            pageBasedText.writeln(pageBasedResult);
            if (fileIndex < files.length) {
              pageBasedText.writeln('\n---\n');
            }
          }
          
          if (comprehensiveResult.trim().isNotEmpty) {
            if (isMultipleFiles) {
              comprehensiveText.writeln('=== الملف $fileIndex: ${file.name} ===\n');
            }
            comprehensiveText.writeln(comprehensiveResult);
            if (fileIndex < files.length) {
              comprehensiveText.writeln('\n---\n');
            }
          }
          
        } else if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
          // للصور، استخدم نفس الطريقة للنوعين
          final extractedText = await _extractAndProcessImageWithDetails(actualFile, file.name, fileIndex, isMultipleFiles);
          
          if (extractedText.trim().isNotEmpty) {
            pageBasedText.writeln(extractedText);
            comprehensiveText.writeln(extractedText);
            
            if (fileIndex < files.length) {
              pageBasedText.writeln('\n---\n');
              comprehensiveText.writeln('\n---\n');
            }
          }
        } else {
          print('تخطي نوع ملف غير مدعوم: $extension');
          continue;
        }
        
      } catch (e) {
        print('خطأ في معالجة الملف ${file.name}: $e');
        final filePrefix = isMultipleFiles ? 'الملف ${fileIndex}: ' : '';
        final errorMsg = '\n**${filePrefix}خطأ في معالجة ${file.name}**: لم يتمكن من استخراج النص من هذا الملف.\n';
        pageBasedText.writeln(errorMsg);
        comprehensiveText.writeln(errorMsg);
      }
    }
    
    final pageResult = pageBasedText.toString();
    final compResult = comprehensiveText.toString();
    
    print('تم استخراج نص بالصفحات: ${pageResult.length} حرف');
    print('تم استخراج نص شامل: ${compResult.length} حرف');
    
    return {
      'page_based': pageResult.isEmpty ? 'لم يتمكن من استخراج أي نص من الملفات.' : pageResult,
      'comprehensive': compResult.isEmpty ? 'لم يتمكن من استخراج أي نص من الملفات.' : compResult,
    };
  }
  
  /// طريقة قديمة للتوافق مع الكود الحالي
  Future<String> extractTextFromMultipleFiles(List<PlatformFile> files) async {
    final results = await extractTextFromMultipleFilesAdvanced(files);
    return results['page_based']!; // استخدام النص بالصفحات افتراضياً
  }

  /// معالجة PDF محسنة بدفعات للسرعة - جديد ومحسن
  Future<String> _extractAndProcessPdfWithPages(File file, String fileName, int fileIndex, bool isMultipleFiles) async {
    try {
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final int totalPages = document.pages.count;
      
      print('بدء استخراج النص من $totalPages صفحة بطريقة محسنة');
      
      final StringBuffer pagesText = StringBuffer();
      
      // إضافة عنوان الملف إذا كان هناك ملفات متعددة
      if (isMultipleFiles) {
        pagesText.writeln('=== الملف $fileIndex: $fileName ===\n');
      }
      
      // تحديد حجم الدفعة بناءً على عدد الصفحات
      int batchSize = _calculateOptimalBatchSize(totalPages);
      
      // استخدام طريقة المعالجة المتوازية للملفات الكبيرة
      if (totalPages > 20) {
        pagesText.writeln(await _extractPagesInParallel(document, totalPages, batchSize));
      } else {
        // معالجة تتابعية للملفات الصغيرة
        for (int startPage = 0; startPage < totalPages; startPage += batchSize) {
          int endPage = (startPage + batchSize - 1).clamp(0, totalPages - 1);
          
          try {
            // استخراج دفعة من الصفحات
            final batchText = _extractPagesBatch(document, startPage, endPage);
            
            if (batchText.trim().isNotEmpty) {
              // إضافة رقم الدفعة للوضوح
              if (batchSize > 1) {
                pagesText.writeln('--- الصفحات ${startPage + 1} إلى ${endPage + 1} ---');
              } else {
                pagesText.writeln('--- الصفحة ${startPage + 1} ---');
              }
              
              // تنظيف سريع للدفعة
              final cleanedBatchText = _basicTextCleanup(batchText);
              pagesText.writeln(cleanedBatchText);
              pagesText.writeln(); // مسافة بين الدفعات
            }
            
            print('تم معالجة الصفحات ${startPage + 1}-${endPage + 1}/$totalPages');
            
          } catch (e) {
            print('خطأ في معالجة الصفحات ${startPage + 1}-${endPage + 1}: $e');
            pagesText.writeln('--- خطأ في الصفحات ${startPage + 1}-${endPage + 1} ---');
            pagesText.writeln('لم يتمكن من قراءة هذه الصفحات');
            pagesText.writeln();
          }
        }
      }
      
      document.dispose();
      
      final result = pagesText.toString();
      if (result.trim().isEmpty) {
        throw Exception('لم يتمكن من استخراج أي نص من الملف');
      }
      
      print('تم استخراج نص بحجم ${result.length} حرف من $totalPages صفحة');
      return result;
      
    } catch (e) {
      print("Error extracting PDF text: $e");
      throw Exception('فشل في قراءة ملف PDF: $fileName');
    }
  }
  
  /// حساب حجم الدفعة المثلى بناءً على عدد الصفحات
  int _calculateOptimalBatchSize(int totalPages) {
    if (totalPages <= 5) return 1;      // ملفات صغيرة: صفحة واحدة
    if (totalPages <= 20) return 3;     // ملفات متوسطة: 3 صفحات
    if (totalPages <= 50) return 5;     // ملفات كبيرة: 5 صفحات
    return 8;                           // ملفات كبيرة جداً: 8 صفحات
  }
  
  /// استخراج الصفحات بطريقة متوازية للملفات الكبيرة
  Future<String> _extractPagesInParallel(PdfDocument document, int totalPages, int batchSize) async {
    print('بدء المعالجة المتوازية لـ $totalPages صفحة');
    
    // تقسيم الصفحات إلى مجموعات
    final List<Future<String>> futures = [];
    
    for (int startPage = 0; startPage < totalPages; startPage += batchSize) {
      int endPage = (startPage + batchSize - 1).clamp(0, totalPages - 1);
      
      // إضافة مهمة معالجة متوازية
      futures.add(_extractBatchAsync(document, startPage, endPage));
    }
    
    try {
      // تنفيذ جميع المهام بطريقة متوازية
      final List<String> results = await Future.wait(futures);
      
      print('تمت المعالجة المتوازية بنجاح');
      return results.join('\n');
      
    } catch (e) {
      print('خطأ في المعالجة المتوازية: $e');
      // في حالة الفشل، ارجع للمعالجة التتابعية
      return _extractPagesSequentially(document, totalPages, batchSize);
    }
  }
  
  /// استخراج دفعة بشكل غير متزامن (متوازي)
  Future<String> _extractBatchAsync(PdfDocument document, int startPage, int endPage) async {
    try {
      final batchText = _extractPagesBatch(document, startPage, endPage);
      
      if (batchText.trim().isNotEmpty) {
        final cleanedBatchText = _basicTextCleanup(batchText);
        final header = (endPage > startPage) 
            ? '--- الصفحات ${startPage + 1} إلى ${endPage + 1} ---'
            : '--- الصفحة ${startPage + 1} ---';
            
        print('تمت معالجة ${startPage + 1}-${endPage + 1}');
        return '$header\n$cleanedBatchText\n';
      }
      
      return '';
    } catch (e) {
      print('خطأ في معالجة الصفحات ${startPage + 1}-${endPage + 1}: $e');
      return '--- خطأ في الصفحات ${startPage + 1}-${endPage + 1} ---\nلم يتمكن من قراءة هذه الصفحات\n';
    }
  }
  
  /// معالجة تتابعية للعودة في حالة فشل المعالجة المتوازية
  String _extractPagesSequentially(PdfDocument document, int totalPages, int batchSize) {
    print('العودة للمعالجة التتابعية');
    final StringBuffer result = StringBuffer();
    
    for (int startPage = 0; startPage < totalPages; startPage += batchSize) {
      int endPage = (startPage + batchSize - 1).clamp(0, totalPages - 1);
      
      try {
        final batchText = _extractPagesBatch(document, startPage, endPage);
        
        if (batchText.trim().isNotEmpty) {
          final header = (endPage > startPage) 
              ? '--- الصفحات ${startPage + 1} إلى ${endPage + 1} ---'
              : '--- الصفحة ${startPage + 1} ---';
              
          final cleanedBatchText = _basicTextCleanup(batchText);
          result.writeln(header);
          result.writeln(cleanedBatchText);
          result.writeln();
        }
        
        print('تمت معالجة ${startPage + 1}-${endPage + 1}/$totalPages');
        
      } catch (e) {
        print('خطأ في معالجة الصفحات ${startPage + 1}-${endPage + 1}: $e');
        result.writeln('--- خطأ في الصفحات ${startPage + 1}-${endPage + 1} ---');
        result.writeln('لم يتمكن من قراءة هذه الصفحات');
        result.writeln();
      }
    }
    
    return result.toString();
  }
  
  /// استخراج دفعة من الصفحات
  String _extractPagesBatch(PdfDocument document, int startPage, int endPage) {
    final StringBuffer batchText = StringBuffer();
    
    for (int pageNumber = startPage; pageNumber <= endPage; pageNumber++) {
      try {
        final String pageText = PdfTextExtractor(document).extractText(
          startPageIndex: pageNumber, 
          endPageIndex: pageNumber
        );
        
        if (pageText.trim().isNotEmpty) {
          // إضافة النص مع فاصل خفيف
          if (endPage > startPage) {
            batchText.writeln('\n[ص${pageNumber + 1}]\n$pageText');
          } else {
            batchText.writeln(pageText);
          }
        }
      } catch (e) {
        print('خطأ في الصفحة ${pageNumber + 1}: $e');
        batchText.writeln('\n[ص${pageNumber + 1}: خطأ في القراءة]\n');
      }
    }
    
    return batchText.toString();
  }
  
  /// معالجة متقدمة لملفات PDF (نظام قديم - للتوافق)
  Future<String> _extractAndProcessPdf(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String rawText = PdfTextExtractor(document).extractText();
      document.dispose();

      if (rawText.trim().isEmpty) {
        throw Exception('ملف الـ PDF فارغ أو لا يمكن قراءة النص منه.');
      }
      
      // تنظيف وتحسين النص المستخرج
      final processedText = await _cleanAndEnhanceText(rawText);
      
      return processedText;
    } catch (e) {
      print("Error extracting PDF text: $e");
      throw Exception(
          'فشل في قراءة ملف الـ PDF. قد يكون الملف محمياً أو تالفاً.');
    }
  }
  
  /// معالجة متقدمة للصور - مُفعلة بالكامل مع تحسينات متقدمة
  Future<String> _extractAndProcessImage(File file) async {
    try {
      print('بدء معالجة الصورة: ${file.path}');
      
      // فحص حجم الصورة
      final fileSize = await file.length();
      print('حجم الصورة: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      if (fileSize > 20 * 1024 * 1024) { // 20MB حد أقصى
        throw Exception('حجم الصورة كبير جداً. ارجع استخدام صورة أقل من 20MB.');
      }
      
      // استخراج النص من الصورة باستخدام Gemini
      print('بدء استخراج النص باستخدام ذكاء اصطناعي...');
      final rawText = await _extractTextFromImageWithRetry(file);
      
      if (_isExtractedTextValid(rawText)) {
        print('تم استخراج ${rawText.length} حرف من الصورة');
        
        // تنظيف وتحسين النص المستخرج
        final processedText = await _cleanAndEnhanceText(rawText);
        
        print('تم تحسين النص بنجاح');
        return processedText;
      } else {
        throw Exception('لم يتمكن من استخراج نص مفيد من هذه الصورة.');
      }
      
    } catch (e) {
      print("Error extracting image text: $e");
      
      // في حالة فشل استخراج النص، أعط رسالة واضحة
      if (e.toString().contains('لم يتمكن من استخراج')) {
        return 'لم يتمكن من استخراج نص من هذه الصورة. قد تكون:\n- الصورة غير واضحة\n- لا تحتوي على نص\n- جودة الصورة منخفضة';
      }
      
      throw Exception('فشل في قراءة النص من الصورة. تأكد من:\n- جودة ووضوح الصورة\n- وجود نص في الصورة\n- حجم الصورة معقول');
    }
  }
  
  /// معالجة الصور مع إضافة تفاصيل الملف - جديد
  Future<String> _extractAndProcessImageWithDetails(File file, String fileName, int fileIndex, bool isMultipleFiles) async {
    try {
      print('بدء معالجة الصورة: $fileName');
      
      // فحص حجم الصورة
      final fileSize = await file.length();
      print('حجم الصورة: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      if (fileSize > 20 * 1024 * 1024) { // 20MB حد أقصى
        throw Exception('حجم الصورة كبير جداً');
      }
      
      // استخراج النص من الصورة
      final rawText = await _extractTextFromImageWithRetry(file);
      
      if (!_isExtractedTextValid(rawText)) {
        throw Exception('لم يتمكن من استخراج نص مفيد من هذه الصورة');
      }
      
      // تنظيف النص
      final cleanedText = _basicTextCleanup(rawText);
      
      // تنسيق النص مع معلومات الملف
      final StringBuffer formattedText = StringBuffer();
      
      if (isMultipleFiles) {
        formattedText.writeln('=== الملف $fileIndex: $fileName ===\n');
      }
      
      formattedText.writeln('--- محتوى الصورة ---');
      formattedText.writeln(cleanedText);
      formattedText.writeln();
      
      final result = formattedText.toString();
      print('تم استخراج نص بحجم ${result.length} حرف من الصورة');
      return result;
      
    } catch (e) {
      print("Error extracting image text: $e");
      
      final filePrefix = isMultipleFiles ? 'الملف $fileIndex: ' : '';
      if (e.toString().contains('لم يتمكن من استخراج')) {
        return '**${filePrefix}معلومات عن $fileName**: لم يتمكن من استخراج نص من هذه الصورة. قد تكون غير واضحة أو لا تحتوي على نص.';
      }
      
      throw Exception('فشل في قراءة الصورة: $fileName');
    }
  }
  
  /// تنظيف وتحسين النص باستخدام Gemini 2.5 Pro
  Future<String> _cleanAndEnhanceText(String rawText) async {
    // إذا كان النص أكبر من الحد الأقصى، عالجه بأجزاء
    if (rawText.length > maxChunkSize) {
      return await _processLargeText(rawText);
    }
    
    // إذا كان النص صغيراً، عالجه مباشرة
    return await _enhanceTextWithAI(rawText);
  }
  
  /// معالجة النصوص الكبيرة بتقسيمها لأجزاء
  Future<String> _processLargeText(String largeText) async {
    print('معالجة نص كبير (${largeText.length} حرف) بتقسيمه لأجزاء');
    
    final chunks = _splitTextIntoChunks(largeText);
    final StringBuffer processedText = StringBuffer();
    
    for (int i = 0; i < chunks.length; i++) {
      try {
        print('معالجة الجزء ${i + 1} من ${chunks.length}');
        final enhancedChunk = await _enhanceTextWithAI(chunks[i]);
        processedText.writeln(enhancedChunk);
        processedText.writeln(); // مسافة بين الأجزاء
      } catch (e) {
        print('خطأ في معالجة الجزء ${i + 1}: $e');
        // في حالة الخطأ، استخدم النص الأصلي مع تنظيف بسيط
        processedText.writeln(_basicTextCleanup(chunks[i]));
        processedText.writeln();
      }
    }
    
    return processedText.toString();
  }
  
  /// تقسيم النص لأجزاء بطريقة ذكية
  List<String> _splitTextIntoChunks(String text) {
    final List<String> chunks = [];
    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    
    StringBuffer currentChunk = StringBuffer();
    
    for (final paragraph in paragraphs) {
      // إضافة الفقرة إذا لم تتجاوز الحد الأقصى
      if ((currentChunk.length + paragraph.length) < maxChunkSize) {
        if (currentChunk.isNotEmpty) {
          currentChunk.writeln('\n');
        }
        currentChunk.writeln(paragraph);
      } else {
        // حفظ الجزء الحالي وبدء جزء جديد
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.toString());
          currentChunk.clear();
        }
        
        // إذا كانت الفقرة نفسها كبيرة جداً، قسمها
        if (paragraph.length > maxChunkSize) {
          final subChunks = _splitLongParagraph(paragraph);
          chunks.addAll(subChunks);
        } else {
          currentChunk.writeln(paragraph);
        }
      }
    }
    
    // إضافة الجزء الأخير إذا لم يكن فارغاً
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.toString());
    }
    
    print('تم تقسيم النص إلى ${chunks.length} جزء');
    return chunks;
  }
  
  /// تقسيم الفقرات الطويلة
  List<String> _splitLongParagraph(String paragraph) {
    final List<String> chunks = [];
    final sentences = paragraph.split(RegExp(r'[.!?؟؛]\s*'));
    
    StringBuffer currentChunk = StringBuffer();
    
    for (final sentence in sentences) {
      if ((currentChunk.length + sentence.length) < maxChunkSize) {
        if (currentChunk.isNotEmpty) {
          currentChunk.write(' ');
        }
        currentChunk.write(sentence);
      } else {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.toString());
          currentChunk.clear();
        }
        currentChunk.write(sentence);
      }
    }
    
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.toString());
    }
    
    return chunks;
  }

  /// تحسين النص باستخدام Gemini 2.5 Pro - محدث لضمان الشمولية الكاملة
  Future<String> _enhanceTextWithAI(String rawText) async {
    try {
      final enhancePrompt = '''
      أنت خبير في تنظيف النصوص التعليمية وإزالة العناصر الغير ضرورية مع الحفاظ على المعلومات المهمة.

      **مهمتك:** تنظيف هذا النص من كل العناصر المزعجة والغير مفيدة، وترك المحتوى المفيد فقط.

      **احذف هذه العناصر فوراً:**
      • أي أرقام منفردة بدون سياق مثل "15" أو "1 دولار"
      • أي رموز غريبة مثل brackets أو JSON symbols
      • أي تكرار مثل "15 - 15" أو "Wi-Fi - Wi-Fi"
      • أي عبارات تقنية مثل "type:" أو "content:"
      • أي جمل مشوشة أو غير مفهومة
      • أي علامات ترقيم زائدة أو متكررة
      • أي معلومات متاداتا مثل أرقام الصفحات

      **احتفظ بهذه العناصر:**
      • المعلومات التعليمية والعلمية
      • الشروحات والتفاسير
      • الأمثلة والتطبيقات
      • القوانين والمعادلات
      • التواريخ والأسماء المهمة

      **تعليمات صارمة:**
      1. لا تغير المعنى أبداً
      2. لا تلخص أو تختصر
      3. فقط نظف ورتب
      4. أزل فقط العناصر المزعجة

      **النص المطلوب تنظيفه:**
      """$rawText"""

      أرجع فقط النص النظيف بدون أي تعليق أو شرح.
      ''';
      
      // استخدام دالة عامة للحصول على الرد من Gemini
      final response = await _enhanceTextDirectly(enhancePrompt);
      
      final enhancedText = response?.trim() ?? rawText;
      
      // فحص جودة النتيجة بشكل أكثر تساهلاً لضمان عدم فقدان المعلومات
      if (enhancedText.length < (rawText.length * 0.4)) {
        print('تحذير: النص المحسن أقصر من المتوقع، استخدام التنظيف البسيط');
        return _basicTextCleanup(rawText);
      }
      
      // التحقق من وجود كلمات مفتاحية مهمة من النص الأصلي
      if (_isContentPreserved(rawText, enhancedText)) {
        return enhancedText;
      } else {
        print('تحذير: تم فقدان محتوى مهم، استخدام التنظيف البسيط');
        return _basicTextCleanup(rawText);
      }
      
    } catch (e) {
      print('خطأ في تحسين النص بالذكاء الاصطناعي: $e');
      return _basicTextCleanup(rawText);
    }
  }
  
  /// تنظيف جذري وشامل للنص - محدث بالكامل
  String _basicTextCleanup(String text) {
    if (text.trim().isEmpty) return text;
    
    String cleaned = text;
    
    // المرحلة 1: إزالة الرموز والعلامات التقنية
    cleaned = cleaned
        // إزالة أحرف تحكم غير مرئية
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        
        // إزالة رموز JSON وعلامات تقنية
        .replaceAll(RegExp(r'[{}"\[\]:,]'), ' ')
        .replaceAll(RegExp(r'[\(\)\<\>]'), ' ')
        
        // إزالة رموز غريبة وموازين
        .replaceAll(RegExp(r'[\$#@%^&*+=|\\`~]'), ' ')
        .replaceAll(RegExp(r'[_]{2,}'), ' ')
        .replaceAll(RegExp(r'[-]{3,}'), ' ');
    
    // المرحلة 2: إزالة كلمات وعبارات تقنية
    cleaned = cleaned
        // عبارات JSON شائعة
        .replaceAll(RegExp(r'\b(type|text|content|value|data|id|class|style)\s*[:=]?\s*', caseSensitive: false), '')
        
        // عبارات HTML/CSS
        .replaceAll(RegExp(r'\b(div|span|p|br|img|src|alt|href|link)\b\s*', caseSensitive: false), '')
        
        // عبارات برمجة عامة
        .replaceAll(RegExp(r'\b(function|class|var|let|const|return|if|else|for|while)\b\s*', caseSensitive: false), '')
        
        // عبارات متاداتا شائعة
        .replaceAll(RegExp(r'\b(page|document|window|element|object|array|string|number)\b\s*', caseSensitive: false), '');
    
    // المرحلة 3: تنظيف الأرقام والعلامات الغريبة
    cleaned = _cleanupNumbersAndSymbols(cleaned);
    
    // المرحلة 4: تنظيف المسافات والأسطر
    cleaned = cleaned
        // تقليل المسافات الزائدة
        .replaceAll(RegExp(r'\s+'), ' ')
        
        // تنظيف الأسطر الفارغة
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
        
        // إزالة مسافات بداية ونهاية الأسطر
        .replaceAll(RegExp(r'^\s+|\s+$', multiLine: true), '');
    
    // المرحلة 5: تصحيح علامات الترقيم
    cleaned = _fixPunctuation(cleaned);
    
    // المرحلة 6: إزالة التكرار والجمل الفارغة
    cleaned = _removeDuplicatesAndEmptyLines(cleaned);
    
    return cleaned.trim();
  }
  
  /// تحقق من جودة النص المستخرج
  bool _isTextQualityGood(String text) {
    // فحوصات أساسية لجودة النص
    if (text.trim().length < 50) return false;
    
    // فحص وجود نسبة عالية من الرموز غير المعتادة
    final specialCharsCount = RegExp(r'[{}\[\]",:=]').allMatches(text).length;
    if (specialCharsCount > (text.length * 0.1)) return false;
    
    // فحص وجود كلمات مفيدة
    final wordCount = text.split(RegExp(r'\s+')).length;
    if (wordCount < 10) return false;
    
    return true;
  }
  
  /// فحص إذا كان المحتوى المهم محفوظ في النص المحسن
  bool _isContentPreserved(String originalText, String enhancedText) {
    if (originalText.isEmpty || enhancedText.isEmpty) return false;
    
    // استخراج الكلمات المهمة من النص الأصلي
    final originalWords = originalText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s؀-ۿ]'), ' ')  // الحفاظ على العربية والإنجليزية
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3)  // الكلمات المهمة فقط
        .toSet();
    
    final enhancedWords = enhancedText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s؀-ۿ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3)
        .toSet();
    
    // حساب نسبة الكلمات المحفوظة
    if (originalWords.isEmpty) return true;
    
    final preservedWords = originalWords.intersection(enhancedWords);
    final preservationRate = preservedWords.length / originalWords.length;
    
    // يجب أن تكون 70% على الأقل من الكلمات المهمة محفوظة
    final isPreserved = preservationRate >= 0.7;
    
    if (!isPreserved) {
      print('تحذير: نسبة حفظ المحتوى: ${(preservationRate * 100).toStringAsFixed(1)}%');
    }
    
    return isPreserved;
  }
  
  /// استخراج النص من الصورة مع إعادة المحاولة
  Future<String> _extractTextFromImageWithRetry(File file, {int maxRetries = 2}) async {
    int attempts = 0;
    String? lastError;
    
    while (attempts < maxRetries) {
      try {
        attempts++;
        print('محاولة استخراج رقم $attempts');
        
        final rawText = await _aiService.extractTextFromImage([file]);
        return rawText;
        
      } catch (e) {
        lastError = e.toString();
        print('فشلت المحاولة $attempts: $e');
        
        if (attempts < maxRetries) {
          print('انتظار قبل إعادة المحاولة...');
          await Future.delayed(Duration(seconds: 2));
        }
      }
    }
    
    throw Exception('فشل في جميع محاولات استخراج النص: $lastError');
  }
  
  /// فحص صحة وجودة النص المستخرج
  bool _isExtractedTextValid(String text) {
    if (text.trim().isEmpty) {
      print('فشل الفحص: نص فارغ');
      return false;
    }
    
    // فحص رسائل الفشل الشائعة
    final failureMessages = [
      'لم يتمكن من قراءة',
      'Could not read text',
      'Unable to extract',
      'لا يوجد نص',
      'No text found',
      'Failed to',
      'Error:'
    ];
    
    for (final message in failureMessages) {
      if (text.toLowerCase().contains(message.toLowerCase())) {
        print('فشل الفحص: وجدت رسالة فشل: $message');
        return false;
      }
    }
    
    // فحص أن النص يحتوي على كلمات مفيدة
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length < 3) {
      print('فشل الفحص: عدد قليل من الكلمات (${words.length})');
      return false;
    }
    
    print('نجح الفحص: النص صالح ويحتوي على ${words.length} كلمة');
    return true;
  }
  
  /// تحسين النص باستخدام التنظيف المحلي السريع
  Future<String?> _enhanceTextDirectly(String rawText) async {
    try {
      print('تحسين النص باستخدام التنظيف المحلي (أسرع)');
      
      // استخدام التنظيف المحلي المتطور بدلاً من AI للسرعة
      final cleanedText = _basicTextCleanup(rawText);
      
      // فحص جودة النتيجة
      if (cleanedText.length >= (rawText.length * 0.3)) {
        print('تم تنظيف النص بنجاح محلياً');
        return cleanedText;
      } else {
        print('تحذير: النص المنظف قصير جداً، استخدام النص الأصلي');
        return rawText;
      }
      
    } catch (e) {
      print('خطأ في تنظيف النص: $e');
      return rawText; // إرجاع النص الأصلي في حالة الفشل
    }
  }
  
  /// تنظيف متخصص للأرقام والرموز الغريبة
  String _cleanupNumbersAndSymbols(String text) {
    return text
        // إزالة أرقام منفردة غريبة مثل "1$" أو "15 - 15"
        .replaceAll(RegExp(r'\b\d+\s*[-+*/=]\s*\d+\b'), ' ')  // أرقام بعمليات حسابية
        .replaceAll(RegExp(r'\b\d+\s*\$\b'), ' ')  // أرقام بعلامة دولار
        .replaceAll(RegExp(r'\$\s*\d+'), ' ')  // علامة دولار قبل رقم
        
        // إزالة أرقام مكررة بشكل غريب
        .replaceAll(RegExp(r'\b(\d+)\s*-\s*\1\b'), ' ')  // أرقام مكررة مثل "15 - 15"
        .replaceAll(RegExp(r'\b(\d+)\s*\1\b'), r'$1')  // أرقام متتالية مكررة
        
        // إزالة أرقام منفردة بدون سياق (أقل من 3 أرقام)
        .replaceAll(RegExp(r'\s\b\d{1,2}\b\s'), ' ')  // أرقام 1-2 منفردة
        
        // إزالة رموز غريبة متبقية
        .replaceAll(RegExp(r'[\u2190-\u21FF]'), ' ')  // أسهم ورموز اتجاه
        .replaceAll(RegExp(r'[\u2600-\u26FF]'), ' ')  // رموز متنوعة
        .replaceAll(RegExp(r'[\u2700-\u27BF]'), ' '); // رموز زخرفية
  }
  
  /// تصحيح علامات الترقيم والمسافات
  String _fixPunctuation(String text) {
    return text
        // إزالة علامات ترقيم متكررة
        .replaceAll(RegExp(r'\.{2,}'), '.')  // نقاط متعددة
        .replaceAll(RegExp(r'\,{2,}'), '،')  // فواصل متعددة
        .replaceAll(RegExp(r'\?{2,}'), '؟')  // علامات استفهام متعددة
        .replaceAll(RegExp(r'!{2,}'), '!')  // علامات تعجب متعددة
        
        // تصحيح المسافات حول علامات الترقيم
        .replaceAll(RegExp(r'\s+([.!?،؟؛])'), r'$1')  // إزالة مسافة قبل علامات الترقيم
        .replaceAll(RegExp(r'([.!?،؟؛])([\w؀-ۿ])'), r'$1 $2'); // إضافة مسافة بعد علامات الترقيم
  }
  
  /// إزالة التكرار والجمل الفارغة
  String _removeDuplicatesAndEmptyLines(String text) {
    // تقسيم النص لأسطر
    final lines = text.split('\n');
    final cleanedLines = <String>[];
    final seenLines = <String>{};
    
    for (final line in lines) {
      final cleanedLine = line.trim();
      
      // تجاهل الأسطر الفارغة أو القصيرة جداً
      if (cleanedLine.isEmpty || cleanedLine.length < 3) {
        continue;
      }
      
      // تجاهل الأسطر التي تحتوي على أرقام فقط أو رموز فقط
      if (RegExp(r'^[\d\s\-+*/=.,$%،؟؛]+$').hasMatch(cleanedLine)) {
        continue;
      }
      
      // تجاهل الأسطر المكررة
      if (!seenLines.contains(cleanedLine.toLowerCase())) {
        seenLines.add(cleanedLine.toLowerCase());
        cleanedLines.add(cleanedLine);
      }
    }
    
    return cleanedLines.join('\n');
  }
  
  /// الحصول على النص الشامل للبطاقات والاختبارات
  Future<String> getComprehensiveTextFromFiles(List<PlatformFile> files) async {
    final results = await extractTextFromMultipleFilesAdvanced(files);
    return results['comprehensive']!;
  }
  
  /// الحصول على النص بالصفحات للملخصات
  Future<String> getPageBasedTextFromFiles(List<PlatformFile> files) async {
    final results = await extractTextFromMultipleFilesAdvanced(files);
    return results['page_based']!;
  }
  
  // --- تعديل: يمكن استخدام هـه الدالة لاختيار الصور ---
  Future<List<File>> pickImages() async {
    final ImagePicker imagePicker = ImagePicker();
    final List<XFile> pickedFiles = await imagePicker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      return pickedFiles.map((xfile) => File(xfile.path)).toList();
    }
    return [];
  }
}
