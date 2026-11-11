import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../tenant/bloc/tenant_bloc.dart';
import '../../tenant/bloc/tenant_state.dart';
import '../../tenant/utils/tenant_switch.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _authErrorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tenantState = context.watch<TenantBloc>().state;
    final tenant = tenantState is TenantSelected ? tenantState.tenant : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Nhập Ứng Viên'),
        actions: [
          TextButton.icon(
            onPressed: () => switchTenantWorkspace(context),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Đổi công ty', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            if (_authErrorMessage != null) {
              setState(() => _authErrorMessage = null);
            }
          } else if (state is Authenticated) {
            if (_authErrorMessage != null) {
              setState(() => _authErrorMessage = null);
            }
            if (context.canPop()) {
              context.pop(true);
            } else {
              context.go('/jobs');
            }
          } else if (state is AuthError) {
            setState(() => _authErrorMessage = state.message);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 6),
                ),
              );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tenant Branding Header
                    Center(
                      child: tenant?.logoUrl != null && tenant!.logoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: tenant.logoUrl!,
                              height: 64,
                              placeholder: (context, url) => const SizedBox(
                                height: 64,
                                width: 64,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) => _buildDefaultLogo(theme),
                            )
                          : _buildDefaultLogo(theme),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tenant?.name ?? 'SmartHire Portal',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (tenant?.slogan != null && tenant!.slogan!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        tenant.slogan!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 36),

                    // Card giới thiệu tính năng ứng viên
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Không gian dành cho Ứng viên',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildBenefitItem(
                              Icons.description_outlined,
                              'Ứng tuyển nhanh chóng & quản lý hồ sơ CV',
                              theme,
                            ),
                            const SizedBox(height: 12),
                            _buildBenefitItem(
                              Icons.auto_awesome_rounded,
                              'Xem kết quả AI chấm điểm CV & độ phù hợp',
                              theme,
                            ),
                            const SizedBox(height: 12),
                            _buildBenefitItem(
                              Icons.smart_toy_outlined,
                              'Tham gia làm bài test kỹ thuật và phỏng vấn AI',
                              theme,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_authErrorMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.error.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Đăng nhập chưa thành công (vẫn ở chế độ Khách)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _authErrorMessage!,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    // Google Sign-In Primary Button
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<AuthBloc>().add(GoogleLoginEvent());
                            },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDADCE0), width: 1.2),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 1,
                        shadowColor: Colors.black.withValues(alpha: 0.08),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildGoogleIcon(),
                                const SizedBox(width: 14),
                                const Text(
                                  'Tiếp tục với Google',
                                  style: TextStyle(
                                    color: Color(0xFF3C4043),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Guest Browse Option
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              context.go('/jobs');
                            },
                      child: const Text('Tiếp tục duyệt việc làm dưới quyền Khách'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }

  Widget _buildDefaultLogo(ThemeData theme) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Image.asset(
        'assets/images/logo_smarthire_icon.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paintBlue = Paint()..color = const Color(0xFF4285F4);
    final paintRed = Paint()..color = const Color(0xFFEA4335);
    final paintYellow = Paint()..color = const Color(0xFFFBBC05);
    final paintGreen = Paint()..color = const Color(0xFF34A853);

    final rect = Rect.fromLTWH(0, 0, w, h);

    // Blue section (Right bar & Top-Right)
    canvas.drawArc(rect, -0.4, 1.2, true, paintBlue);

    // Green section (Bottom)
    canvas.drawArc(rect, 0.8, 1.4, true, paintGreen);

    // Yellow section (Bottom-Left)
    canvas.drawArc(rect, 2.2, 1.2, true, paintYellow);

    // Red section (Top-Left)
    canvas.drawArc(rect, 3.4, 1.3, true, paintRed);

    // Inner hole
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.32, innerPaint);

    // Right crossbar (Blue)
    final barRect = Rect.fromLTWH(w * 0.45, h * 0.38, w * 0.55, h * 0.24);
    canvas.drawRect(barRect, paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
