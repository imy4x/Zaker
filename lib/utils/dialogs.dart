import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppDialogs {
  static void showErrorDialog(BuildContext context, String message,
      {String title = 'حدث خطأ'}) {
    final theme = Theme.of(context);
    final isWarning = title == 'تنبيه';
    final isSuccess = title == 'نجح' || title == 'تم';

    // **تعديل:** استخدام ألوان من الثيم لضمان التوافق مع الوضع الداكن
    Color iconColor = isWarning
        ? const Color(0xFFF59E0B) // Amber
        : isSuccess
            ? const Color(0xFF10B981) // Emerald
            : theme.colorScheme.error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        // **تعديل:** الاعتماد على ألوان الثيم الافتراضية للخلفية
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWarning
                  ? Icons.warning_amber_rounded
                  : isSuccess
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
              color: iconColor,
              size: 48,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineLarge?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              // **تعديل:** تطبيق لون مخصص للزر مع الحفاظ على التوافق
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('حسنًا'),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      ),
    );
  }

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    String title = 'تأكيد الحذف',
    String content =
        'هل أنت متأكد من رغبتك في الحذف؟ لا يمكن التراجع عن هذا الإجراء.',
  }) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.help_rounded,
              color: theme.colorScheme.error,
              size: 48,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  // **تعديل:** استخدام تصميم الثيم الافتراضي للزر
                  style: theme.outlinedButtonTheme.style,
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  // **تعديل:** استخدام تصميم الثيم مع لون مخصص للخطر
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  child: const Text('حذف'),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      ),
    );
    return result ?? false;
  }

  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Lottie.asset('assets/animations/processing.json',
                    fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }
}
