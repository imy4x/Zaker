import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:zaker/api/gemini_service.dart';

class TextExtractionService {
  final GeminiService _aiService = GeminiService();

  // --- تعديل: دالة جديدة لاستخراج النصوص من ملفات متعددة ---
  Future<String> extractTextFromMultipleFiles(List<PlatformFile> files) async {
    final StringBuffer combinedText = StringBuffer();

    for (final file in files) {
      final extension = file.extension?.toLowerCase();
      File actualFile = File(file.path!);

      if (extension == 'pdf') {
        final text = await _extractTextFromSinglePdf(actualFile);
        combinedText.writeln(text);
      } else if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        // بما أن Gemini يمكنه التعامل مع صور متعددة، نجمعها ونرسلها دفعة واحدة
        // لكن للتبسيط هنا، سنعالج كل صورة على حدة لضمان استهلاك الرصيد بشكل صحيح
        final text = await _aiService.extractTextFromImage([actualFile]);
        combinedText.writeln(text);
      }
      combinedText.writeln("\n--- نهاية المستند ---\n");
    }
    return combinedText.toString();
  }

  Future<String> _extractTextFromSinglePdf(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();

      if (text.trim().isEmpty) {
        throw Exception('ملف الـ PDF فارغ أو لا يمكن قراءة النص منه.');
      }
      return text;
    } catch (e) {
      print("Error extracting PDF text: $e");
      throw Exception(
          'فشل في قراءة ملف الـ PDF. قد يكون الملف محمياً أو تالفاً.');
    }
  }

  // --- تعديل: يمكن استخدام هذه الدالة لاختيار الصور ---
  Future<List<File>> pickImages() async {
    final ImagePicker imagePicker = ImagePicker();
    final List<XFile> pickedFiles = await imagePicker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      return pickedFiles.map((xfile) => File(xfile.path)).toList();
    }
    return [];
  }
}
