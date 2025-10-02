import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:zaker/api/simple_gemini_service.dart';

class TextExtractionService {
  final GeminiService _aiService = GeminiService();
  
  /// **(جديد ومبسط)** استخراج النص الخام بسرعة - Fast Raw Text Extraction
  /// هذه الدالة تجمع النصوص من مختلف أنواع الملفات بدون أي معالجة مسبقة.
  Future<String> extractRawText(List<PlatformFile> files) async {
    final StringBuffer rawTextBuffer = StringBuffer();
    bool isMultipleFiles = files.length > 1;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        if (isMultipleFiles) {
          rawTextBuffer.writeln('\n\n--- START OF FILE: ${file.name} ---\n\n');
        }
        
        final extension = file.extension?.toLowerCase() ?? '';
        final actualFile = File(file.path!);
        String extractedChunk = '';

        if (extension == 'pdf') {
          extractedChunk = await _extractTextFromPdf(actualFile);
        } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
          extractedChunk = await _extractTextFromImage(actualFile);
        } else if (['docx', 'pptx'].contains(extension)) {
          extractedChunk = await _extractTextFromOffice(actualFile, extension);
        } else {
          // Unsupported file type
          continue;
        }
        
        rawTextBuffer.writeln(extractedChunk);

        if (isMultipleFiles) {
          rawTextBuffer.writeln('\n\n--- END OF FILE: ${file.name} ---\n\n');
        }

      } catch (e) {
        // Error processing file ...
        rawTextBuffer.writeln('\n\n[ERROR PROCESSING FILE: ${file.name}]\n\n');
      }
    }
    
    final rawText = rawTextBuffer.toString();
    if (rawText.trim().isEmpty) {
      // Initial extraction yielded no text.
      return '';
    }
    
    // Initial extraction complete. Size: ...
    return rawText;
  }

  /// استخراج النص من ملف PDF
  Future<String> _extractTextFromPdf(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      // Error extracting PDF text: ...
      throw Exception('فشل في قراءة ملف PDF: ${file.path.split('/').last}');
    }
  }

  /// استخراج النص من الصور
  Future<String> _extractTextFromImage(File file) async {
    try {
      // Prompt for simple, clean text extraction
      const prompt = "Extract all text from this image. Preserve original paragraphs and structure. Do not add any comments or summaries, return only the extracted text.";
      return await _aiService.extractTextFromFile(file, prompt);
    } catch (e) {
      throw Exception('فشل في قراءة النص من الصورة: ${file.path.split('/').last}');
    }
  }

  /// استخراج النص من ملفات Office (Word, PowerPoint)
  Future<String> _extractTextFromOffice(File file, String extension) async {
    try {
      final docType = extension == 'docx' ? 'Word document' : 'PowerPoint presentation';
      final prompt = '''
        Extract all text from this $docType.
        - For PowerPoint, indicate slide breaks with "--- Slide X ---".
        - Preserve all headings, lists, and paragraph content.
        - Do not add commentary, just the text.
      ''';
      return await _aiService.extractTextFromFile(file, prompt);
    } catch (e) {
      throw Exception('فشل في قراءة ملف $extension: ${file.path.split('/').last}');
    }
  }
}


