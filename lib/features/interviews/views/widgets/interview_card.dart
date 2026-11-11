import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/human_interview_model.dart';
import '../../utils/interview_labels.dart';

class InterviewCard extends StatelessWidget {
  final HumanInterviewModel interview;
  final VoidCallback? onTap;
  final bool compact;

  const InterviewCard({
    super.key,
    required this.interview,
    this.onTap,
    this.compact = false,
  });

  String _weekdayShort(DateTime dt) {
    const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return names[(dt.weekday - 1).clamp(0, 6)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = InterviewLabels.statusColor(interview.status, theme);
    final isOnline = interview.mode.toUpperCase() == 'ONLINE';
    final timeText =
        '${DateFormat('HH:mm').format(interview.start)} – ${DateFormat('HH:mm').format(interview.end)} · ${interview.durationMinutes} phút';

    final placeText = isOnline
        ? InterviewLabels.providerLabel(interview.configuration.provider, interview.mode)
        : (interview.location?.isNotEmpty == true
            ? interview.location!
            : 'Địa điểm sẽ được thông báo sau');

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 10 : 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Badge
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _weekdayShort(interview.start),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${interview.start.day}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      DateFormat('MM/yyyy').format(interview.start),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            InterviewLabels.statusLabel(interview.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            InterviewLabels.roundLabel(interview.round),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      interview.jobTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            timeText,
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isOnline ? Icons.videocam_outlined : Icons.location_on_outlined,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            placeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    if (!compact && interview.participants.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.groups_outlined, size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              interview.participants.map((p) => p.name).join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

