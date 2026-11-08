import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/storage_service.dart';
import '../bloc/tenant_bloc.dart';
import '../bloc/tenant_event.dart';
import '../bloc/tenant_state.dart';
import 'qr_scanner_screen.dart';

class TenantSelectionScreen extends StatefulWidget {
  const TenantSelectionScreen({super.key});

  @override
  State<TenantSelectionScreen> createState() => _TenantSelectionScreenState();
}

class _TenantSelectionScreenState extends State<TenantSelectionScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submitCode(String code) {
    if (code.trim().isEmpty) return;
    context.read<TenantBloc>().add(LookupTenantEvent(code.trim()));
  }

  Future<void> _scanQrCode() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (scannedCode != null && scannedCode.isNotEmpty) {
      _codeController.text = scannedCode;
      _submitCode(scannedCode);
    }
  }

  void _showServerSettingsDialog() {
    final storage = getIt<StorageService>();
    final dioClient = getIt<DioClient>();
    final urlController = TextEditingController(
      text: storage.getCustomBaseUrl() ?? ApiConstants.defaultBaseUrl,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cấu hình Máy chủ API', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa chỉ Backend API của hệ thống SmartHire:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:8080/api/v1',
                prefixIcon: Icon(Icons.dns_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('USB Cáp (localhost)'),
                  onPressed: () => urlController.text = 'http://localhost:8080/api/v1',
                ),
                ActionChip(
                  label: const Text('Wi-Fi LAN (172.20.10.3)'),
                  onPressed: () => urlController.text = 'http://172.20.10.3:8080/api/v1',
                ),
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)'),
                  onPressed: () => urlController.text = 'http://10.0.2.2:8080/api/v1',
                ),
                ActionChip(
                  label: const Text('Production'),
                  onPressed: () => urlController.text = ApiConstants.productionBaseUrl,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                await storage.saveCustomBaseUrl(newUrl);
                dioClient.updateBaseUrl(newUrl);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã cập nhật máy chủ: $newUrl')),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Doanh Nghiệp'),
        actions: [
          IconButton(
            tooltip: 'Cài đặt kết nối máy chủ',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showServerSettingsDialog,
          ),
        ],
      ),
      body: BlocConsumer<TenantBloc, TenantState>(
        listener: (context, state) {
          if (state is TenantSelected) {
            // Khi tenant được chọn thành công, chuyển hướng vào trang việc làm
            context.go('/jobs');
          } else if (state is TenantError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is TenantLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Illustration / Logo
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.apartment_rounded,
                          size: 38,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'SmartHire Ứng Viên',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhập mã công ty hoặc quét mã QR tuyển dụng để bắt đầu khám phá cơ hội nghề nghiệp',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Input Box with QR action button
                      TextFormField(
                        controller: _codeController,
                        enabled: !isLoading,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        decoration: InputDecoration(
                          labelText: 'Mã công ty (Company Subdomain)',
                          hintText: 'ví dụ: fpt, viettel, vng',
                          prefixIcon: const Icon(Icons.business_rounded),
                          suffixIcon: IconButton(
                            tooltip: 'Quét mã QR tuyển dụng',
                            icon: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: isLoading ? null : _scanQrCode,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mã công ty';
                          }
                          return null;
                        },
                        onFieldSubmitted: (val) {
                          if (_formKey.currentState?.validate() ?? false) {
                            _submitCode(val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Suggestion Chips
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Gợi ý:',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          ActionChip(
                            label: const Text('fpt'),
                            onPressed: isLoading
                                ? null
                                : () {
                                    _codeController.text = 'fpt';
                                    _submitCode('fpt');
                                  },
                          ),
                          ActionChip(
                            label: const Text('vng'),
                            onPressed: isLoading
                                ? null
                                : () {
                                    _codeController.text = 'vng';
                                    _submitCode('vng');
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Submit button
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ?? false) {
                                  _submitCode(_codeController.text);
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Khám Phá Việc Làm'),
                      ),
                      const SizedBox(height: 16),

                      // QR Scan secondary action
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : _scanQrCode,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('Quét Mã QR Công Ty'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
