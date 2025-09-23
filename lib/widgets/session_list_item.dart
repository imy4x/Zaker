import 'package:flutter/material.dart';
import 'package:zaker/models/study_session.dart';
import 'package:intl/intl.dart' as intl;
import 'package:percent_indicator/circular_percent_indicator.dart';

class SessionListItem extends StatelessWidget {
  final StudySession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onMove; // --- إضافة: دالة جديدة للنقل ---

  const SessionListItem({
    super.key,
    required this.session,
    required this.onTap,
    required this.onDelete,
    required this.onMove, // --- إضافة: دالة جديدة للنقل ---
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = session.quizQuestions.isNotEmpty
        ? (session.correctlyAnsweredQuestions.length /
                session.quizQuestions.length)
            .clamp(0.0, 1.0)
        : 0.0;
    final formattedDate =
        intl.DateFormat('d MMMM yyyy', 'ar').format(session.createdAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200)
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 28.0,
                lineWidth: 6.0,
                percent: progress,
                center: Text(
                  "${(progress * 100).toInt()}%",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                progressColor: theme.primaryColor,
                backgroundColor: Colors.grey.shade200,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // --- تعديل: استخدام قائمة منبثقة للإجراءات ---
              PopupMenuButton<String>(
                onSelected: (value) {
                  if(value == 'move') onMove();
                  if(value == 'delete') onDelete();
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'move',
                    child: ListTile(
                      leading: Icon(Icons.drive_file_move_outline),
                      title: Text('نقل إلى...'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                      title: Text('حذف', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
