import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/views/widgets/unauthenticated_prompt_view.dart';

class CandidateAssessmentListScreen extends StatelessWidget {
  const CandidateAssessmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài Test & Phỏng Vấn AI'),
      ),
      body: authState is! Authenticated
          ? const UnauthenticatedPromptView(
              icon: Icons.smart_toy_outlined,
              title: 'Đăng nhập để vào phòng phỏng vấn',
              description:
                  'Thực hiện bài kiểm tra trắc nghiệm online và tham gia phỏng vấn thử / phỏng vấn trực tiếp cùng AI.',
              buttonLabel: 'Đăng nhập ngay',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // AI Interview Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.record_voice_over_rounded,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Luyện Phỏng Vấn với AI',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Luyện tập trả lời tình huống & nhận phản hồi từ AI',
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Phòng phỏng vấn AI bằng giọng nói đang khởi động...'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Bắt Đầu Phỏng Vấn Thử'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Technical Assessment Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.quiz_outlined,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bài Test Năng Lực Kỹ Thuật (FE-05)',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Trắc nghiệm tính giờ & chấm điểm tự động',
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Chưa có bài test nào được chỉ định cho bạn.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment_turned_in_outlined),
                          label: const Text('Xem Danh Sách Bài Test'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
