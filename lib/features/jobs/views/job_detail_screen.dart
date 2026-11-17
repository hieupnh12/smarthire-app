import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/injection.dart';
import '../../../core/storage/storage_service.dart';
import '../models/job_model.dart';
import '../repositories/job_repository.dart';

class JobDetailScreen extends StatefulWidget {
  final int jobId;
  final JobModel? initialJob;

  const JobDetailScreen({
    super.key,
    required this.jobId,
    this.initialJob,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late JobModel? _job = widget.initialJob;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (_job == null) {
      _loadJobDetail();
    }
  }

  Future<void> _loadJobDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final job = await getIt<JobRepository>().getJobDetail(widget.jobId);
      setState(() {
        _job = job;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openCareerWebsite() async {
    final tenantCode = getIt<StorageService>().getTenantCode();
    final baseUrl = (tenantCode != null && tenantCode.isNotEmpty)
        ? 'https://$tenantCode.smarthire.top'
        : 'https://smarthire.top';
    final urlString = '$baseUrl/jobs/${widget.jobId}';
    final uri = Uri.parse(urlString);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở trình duyệt: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _job == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(_errorMessage ?? 'Không tìm thấy công việc'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadJobDetail,
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
      );
    }

    final job = _job!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Việc Làm'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: SafeArea(
          child: job.acceptingApplications
              ? SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _openCareerWebsite,
                    icon: const Icon(Icons.open_in_browser_rounded, size: 20),
                    label: const Text(
                      'Ứng Tuyển Ngay Trên Website',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E60EC),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              : Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_clock_rounded, size: 18, color: Color(0xFF64748B)),
                      SizedBox(width: 8),
                      Text(
                        'Vị trí này đã dừng nhận hồ sơ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card với Header đầy đủ chiều rộng
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      height: 1.35,
                      letterSpacing: -0.2,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mức lương trải rộng nổi bật
                  Builder(
                    builder: (context) {
                      final hasSalary = job.salary != null && job.salary!.trim().isNotEmpty;
                      final salaryText = hasSalary ? job.salary!.trim() : 'Thỏa thuận';
                      final isNegotiable = !hasSalary ||
                          salaryText.toLowerCase().contains('thỏa thuận') ||
                          salaryText.toLowerCase().contains('thương lượng');

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isNegotiable ? const Color(0xFFF8FAFC) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isNegotiable ? const Color(0xFFCBD5E1) : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isNegotiable ? const Color(0xFFE2E8F0) : const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isNegotiable ? Icons.handshake_outlined : Icons.monetization_on_outlined,
                                size: 18,
                                color: isNegotiable ? const Color(0xFF475569) : const Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MỨC LƯƠNG',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: isNegotiable ? const Color(0xFF64748B) : const Color(0xFF047857),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    salaryText,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: isNegotiable ? const Color(0xFF1E293B) : const Color(0xFF047857),
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Lưới thẻ thông tin cân xứng full width (2 cột x 2 hàng)
                  Row(
                    children: [
                      Expanded(
                        child: _buildGridMetaCard(
                          icon: Icons.location_on_outlined,
                          iconColor: const Color(0xFFEF4444),
                          label: 'ĐỊA ĐIỂM',
                          value: job.location != null && job.location!.trim().isNotEmpty
                              ? job.location!.trim()
                              : 'Toàn quốc / Văn phòng',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildGridMetaCard(
                          icon: Icons.apartment_rounded,
                          iconColor: const Color(0xFF2563EB),
                          label: 'HÌNH THỨC',
                          value: job.workMode != null && job.workMode!.trim().isNotEmpty
                              ? job.workMode!.trim()
                              : (job.employmentType ?? 'Toàn thời gian'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGridMetaCard(
                          icon: Icons.work_history_outlined,
                          iconColor: const Color(0xFF9333EA),
                          label: 'KINH NGHIỆM',
                          value: job.minYearsExperience != null && job.minYearsExperience! > 0
                              ? '${job.minYearsExperience!.toStringAsFixed(0)} năm kinh nghiệm'
                              : 'Không yêu cầu kinh nghiệm',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildGridMetaCard(
                          icon: Icons.event_outlined,
                          iconColor: const Color(0xFFD97706),
                          label: 'HẠN NỘP HỒ SƠ',
                          value: job.deadline != null
                              ? DateFormat('dd/MM/yyyy').format(job.deadline!)
                              : 'Đang mở tuyển dụng',
                        ),
                      ),
                    ],
                  ),
                  if (job.department != null && job.department!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildGridMetaCard(
                      icon: Icons.domain_rounded,
                      iconColor: const Color(0xFF0D9488),
                      label: 'PHÒNG BAN',
                      value: job.department!.trim(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Skills Section
            if (job.skills.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.psychology_outlined, size: 18, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Kỹ năng yêu cầu',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: job.skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Mô tả công việc với bullet points
            if (job.description != null && job.description!.trim().isNotEmpty)
              _buildFormattedContentSection(
                title: 'Mô tả công việc',
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF2563EB),
                content: job.description!,
                theme: theme,
              ),

            // Trách nhiệm công việc với bullet points
            if (job.responsibilities != null && job.responsibilities!.trim().isNotEmpty)
              _buildFormattedContentSection(
                title: 'Trách nhiệm công việc',
                icon: Icons.assignment_outlined,
                iconColor: const Color(0xFF0D9488),
                content: job.responsibilities!,
                theme: theme,
              ),

            // Quyền lợi được hưởng với bullet points
            if (job.benefits != null && job.benefits!.trim().isNotEmpty)
              _buildFormattedContentSection(
                title: 'Quyền lợi được hưởng',
                icon: Icons.card_giftcard_rounded,
                iconColor: const Color(0xFFE11D48),
                content: job.benefits!,
                theme: theme,
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGridMetaCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedContentSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
    required ThemeData theme,
  }) {
    final lines = content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...lines.map((rawLine) {
            // Loại bỏ các ký tự gạch đầu dòng có sẵn nếu có
            final cleanLine = rawLine
                .replaceFirst(RegExp(r'^[\-\*•\+\–]\s*'), '')
                .replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');

            // Nếu là dòng tiêu đề phụ (kết thúc bằng dấu hai chấm hoặc ngắn)
            final isHeaderLike = rawLine.endsWith(':') && rawLine.length < 50;

            if (isHeaderLike) {
              return Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Text(
                  cleanLine,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 10),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      cleanLine,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
