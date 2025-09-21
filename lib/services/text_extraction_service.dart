import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:zaker/api/gemini_service.dart';

enum FileTypeOption { pdf, powerpoint, images }

class TextExtractionService {
  final GeminiService _aiService = GeminiService();
  final ImagePicker _imagePicker = ImagePicker();

  Future<String?> extractTextFromFile(FileTypeOption type) async {
    switch (type) {
      case FileTypeOption.pdf:
        return await _extractTextFromPdf();
      case FileTypeOption.powerpoint:
        throw Exception('ملفات PowerPoint غير مدعومة حالياً، سيتم إضافتها قريباً.');
      case FileTypeOption.images:
        return await _extractTextFromImages();
    }
  }

  Future<String?> _extractTextFromPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      final file = File(result.files.single.path!);
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
        throw Exception('فشل في قراءة ملف الـ PDF. قد يكون الملف محمياً أو تالفاً.');
      }
    }
    return null;
  }

  Future<String?> _extractTextFromImages() async {
    final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      final imageFiles = pickedFiles.map((xfile) => File(xfile.path)).toList();
      return await _aiService.extractTextFromImage(imageFiles);
    }
    return null;
  }
}
