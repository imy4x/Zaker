import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfParserService {
  static Future<String> extractText(File file) async {
    try {
      // تحميل ملف PDF من البايتس
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      // استخراج النصوص
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();

      // إغلاق المستند لتفادي التسريب
      document.dispose();

      return text;
    } catch (e) {
      print("Error extracting text from PDF: $e");
      return '';
    }
  }
}
