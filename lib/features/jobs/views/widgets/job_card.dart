import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/job_model.dart';

class JobCard extends StatefulWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  LinearGradient _getAvatarGradient(String? dept, String title) {
    final text = '${dept ?? ''} $title'.toLowerCase();
    if (text.contains('kỹ thuật') ||
        text.contains('tech') ||
        text.contains('dev') ||
        text.contains('it') ||
        text.contains('phần mềm') ||
        text.contains('lập trình')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      );
    } else if (text.contains('sản phẩm') ||
        text.contains('product') ||
        text.contains('thiết kế') ||
        text.contains('design') ||
        text.contains('ui')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
      );
    } else if (text.contains('kinh doanh') ||
        text.contains('sales') ||
        text.contains('marketing') ||
        text.contains('truyền thông')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
      );
    } else if (text.contains('nhân sự') || text.contains('hr') || text.contains('tuyển dụng')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF059669), Color(0xFF047857)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1E60EC), Color(0xFF0D47A1)],
    );
  }

  IconData _getAvatarIcon(String? dept, String title) {
    final text = '${dept ?? ''} $title'.toLowerCase();
    if (text.contains('kỹ thuật') ||
        text.contains('tech') ||
        text.contains('dev') ||
        text.contains('it') ||
        text.contains('phần mềm') ||
        text.contains('lập trình')) {
      return Icons.code_rounded;
    } else if (text.contains('sản phẩm') ||
        text.contains('product') ||
        text.contains('thiết kế') ||
        text.contains('design') ||
        text.contains('ui')) {
      return Icons.palette_outlined;
    } else if (text.contains('kinh doanh') || text.contains('sales') || text.contains('marketing')) {
      return Icons.trending_up_rounded;
    } else if (text.contains('nhân sự') || text.contains('hr')) {
      return Icons.people_outline_rounded;
    }
    return Icons.business_center_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final job = widget.job;
    final hasSalary = job.salary != null && job.salary!.trim().isNotEmpty;
    final salaryText = hasSalary ? job.salary!.trim() : 'Thỏa thuận';
    final isNegotiable = !hasSalary ||
        salaryText.toLowerCase().contains('thỏa thuận') ||
        salaryText.toLowerCase().contains('thương lượng');

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isPressed
                  ? theme.colorScheme.primary.withValues(alpha: 0.45)
                  : const Color(0xFFE2E8F0),
              width: _isPressed ? 1.2 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? theme.colorScheme.primary.withValues(alpha: 0.08)
                    : const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: _isPressed ? 14 : 10,
                offset: _isPressed ? const Offset(0, 4) : const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Gradient Avatar + Title & Dept + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Gradient Squircle Avatar
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: _getAvatarGradient(job.department, job.title),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _getAvatarIcon(job.department, job.title),
                          size: 21,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Job Title & Department
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.apartment_outlined,
                                size: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  (job.department != null && job.department!.trim().isNotEmpty)
                                      ? job.department!.trim()
                                      : 'Vị trí tuyển dụng',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Live Pulsing Status Badge
                    _buildStatusBadge(job.acceptingApplications),
                  ],
                ),

                const SizedBox(height: 12),

                // Middle: Prominent Salary & Key Info Chips
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxChipWidth = constraints.maxWidth;
                    return Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Emerald / Slate High-contrast Salary Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isNegotiable
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isNegotiable
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFFA7F3D0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isNegotiable
                                    ? Icons.handshake_outlined
                                    : Icons.monetization_on_outlined,
                                size: 14,
                                color: isNegotiable
                                    ? const Color(0xFF475569)
                                    : const Color(0xFF059669),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                salaryText,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isNegotiable
                                      ? const Color(0xFF334155)
                                      : const Color(0xFF047857),
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Location Chip
                        if (job.location != null && job.location!.trim().isNotEmpty)
                          _buildInfoChip(
                            icon: Icons.location_on_outlined,
                            label: job.location!.trim(),
                            iconColor: const Color(0xFF2563EB),
                            maxWidth: maxChipWidth,
                          ),

                        // Work Mode Chip
                        if (job.workMode != null && job.workMode!.trim().isNotEmpty)
                          _buildInfoChip(
                            icon: Icons.domain_rounded,
                            label: job.workMode!.trim(),
                            iconColor: const Color(0xFFD97706),
                            maxWidth: maxChipWidth,
                          )
                        else if (job.employmentType != null &&
                            job.employmentType!.trim().isNotEmpty)
                          _buildInfoChip(
                            icon: Icons.access_time_rounded,
                            label: job.employmentType!.trim(),
                            iconColor: const Color(0xFF7C3AED),
                            maxWidth: maxChipWidth,
                          ),

                        // Experience Chip
                        if (job.minYearsExperience != null && job.minYearsExperience! > 0)
                          _buildInfoChip(
                            icon: Icons.workspace_premium_outlined,
                            label: '${job.minYearsExperience!.toInt()}+ năm KN',
                            iconColor: const Color(0xFF0891B2),
                            maxWidth: maxChipWidth,
                          ),
                      ],
                    );
                  },
                ),

                // Skills & Footer Row
                if (job.skills.isNotEmpty || job.deadline != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Skills List with +N overflow count
                      Expanded(
                        child: _buildSkillsList(job.skills),
                      ),

                      // Deadline status or info
                      if (job.deadline != null) ...[
                        const SizedBox(width: 8),
                        _buildDeadlineWidget(job.deadline!),
                      ],

                      const SizedBox(width: 8),
                      // Arrow indicator button
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool accepting) {
    if (!accepting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 4.5),
            const Text(
              'Đã dừng',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981)
                          .withValues(alpha: 0.28 * _pulseAnimation.value),
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 4.5),
          const Text(
            'Đang tuyển',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineWidget(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;

    if (difference < 0) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_off_outlined, size: 12, color: Color(0xFF94A3B8)),
          SizedBox(width: 3),
          Text(
            'Hết hạn',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      );
    } else if (difference <= 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alarm_rounded, size: 11, color: Color(0xFFDC2626)),
            const SizedBox(width: 3),
            Text(
              difference == 0 ? 'Hết hạn hôm nay' : 'Còn $difference ngày',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      );
    } else if (difference <= 7) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFFD97706)),
            const SizedBox(width: 3),
            Text(
              'Còn $difference ngày',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
              ),
            ),
          ],
        ),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_outlined, size: 12, color: Color(0xFF94A3B8)),
          const SizedBox(width: 3),
          Text(
            'Hạn: ${DateFormat('dd/MM').format(deadline)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSkillsList(List<String> skills) {
    if (skills.isEmpty) return const SizedBox.shrink();
    final displaySkills = skills.take(3).toList();
    final remaining = skills.length - displaySkills.length;

    return Wrap(
      spacing: 5,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...displaySkills.map((skill) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              skill,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          );
        }),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              '+$remaining',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color iconColor,
    double? maxWidth,
  }) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: iconColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
