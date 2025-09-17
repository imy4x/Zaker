import 'package:flutter/material.dart';
import 'package:zaker/models/study_session.dart';

// واجهة جديدة لعرض خانات الجلسات في الصفحة الرئيسية
class SessionSlotWidget extends StatelessWidget {
  final StudySession? session;
  final bool isLocked;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SessionSlotWidget({
    super.key,
    this.session,
    required this.isLocked,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          height: 90,
          child: Row(
            children: [
              Icon(
                isLocked
                    ? Icons.lock_outline
                    : session != null
                        ? Icons.description_outlined
                        : Icons.add_circle_outline,
                size: 32,
                color: isLocked ? Colors.grey : Colors.indigo,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLocked
                          ? 'خانة إضافية'
                          : session?.title ?? 'خانة فارغة',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      isLocked
                          ? 'متوفرة قريباً'
                          : session != null
                              ? 'اضغط لعرض الملخص'
                              : 'اضغط لرفع ملف جديد',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (session != null && !isLocked)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}