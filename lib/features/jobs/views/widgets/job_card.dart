import 'package:flutter/material.dart';
import '../../models/job_model.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Department
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (job.department != null && job.department!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        job.department!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Location & Employment Type
              Row(
                children: [
                  if (job.location != null && job.location!.isNotEmpty) ...[
                    Icon(Icons.location_on_outlined, size: 15, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      job.location!,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (job.workMode != null && job.workMode!.isNotEmpty) ...[
                    Icon(Icons.apartment_outlined, size: 15, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      job.workMode!,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (job.employmentType != null && job.employmentType!.isNotEmpty) ...[
                    Icon(Icons.access_time_rounded, size: 15, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      job.employmentType!,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Salary & Skills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    job.salary ?? 'Thỏa thuận',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (job.skills.isNotEmpty)
                    Row(
                      children: job.skills.take(2).map((skill) {
                        return Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }).toList(),
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
