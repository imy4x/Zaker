import 'package:flutter/material.dart';
import 'package:zaker/models/study_session.dart';
import 'package:intl/intl.dart' as intl;
import 'package:percent_indicator/circular_percent_indicator.dart';

class SessionListItem extends StatelessWidget {
  final StudySession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onMove;
  final VoidCallback onRename;

  const SessionListItem({
    super.key,
    required this.session,
    required this.onTap,
    required this.onDelete,
    required this.onMove,
    required this.onRename,
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
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3))
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 30.0,
                lineWidth: 6.0,
                percent: progress,
                center: Text(
                  "${(progress * 100).toInt()}%",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                progressColor: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surfaceVariant,
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
                            size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
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
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'rename') {
                    onRename();
                  } else if (value == 'move') {
                    onMove();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'rename', child: Text('إعادة تسمية')),
                  const PopupMenuItem(value: 'move', child: Text('نقل إلى...')),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete', 
                    child: Text('حذف', style: TextStyle(color: Colors.red.shade700)),
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

