import 'package:flutter/material.dart';
import 'package:zaker/services/text_extraction_service.dart';

class FileTypePickerSheet extends StatelessWidget {
  const FileTypePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إنشاء جلسة جديدة', style: theme.textTheme.displayLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text('اختر نوع الملف الذي تريد مذاكرته', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          _buildOption(
            context,
            icon: Icons.picture_as_pdf_outlined,
            title: 'ملف PDF',
            subtitle: 'استخراج النصوص من ملفات PDF',
            onTap: () => Navigator.of(context).pop(FileTypeOption.pdf),
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.image_outlined,
            title: 'صور',
            subtitle: 'استخراج النصوص من صور من المعرض',
            onTap: () => Navigator.of(context).pop(FileTypeOption.images),
          ),
          const SizedBox(height: 12),
           _buildOption(
            context,
            icon: Icons.slideshow_outlined,
            title: 'ملف PowerPoint',
            subtitle: 'غير مدعوم حالياً',
            onTap: () {}, // Prevent popping an unsupported option
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300)
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: theme.primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
