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
import '../utils/qr_code_parser.dart';
import 'qr_scanner_screen.dart';

class TenantSelectionScreen extends StatefulWidget {
  const TenantSelectionScreen({super.key});

  @override
  State<TenantSelectionScreen> createState() => _TenantSelectionScreenState();
}

class _TenantSelectionScreenState extends State<TenantSelectionScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String get _activeBaseUrl => getIt<DioClient>().dio.options.baseUrl;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submitCode(String code) {
    if (code.trim().isEmpty) return;
    context.read<TenantBloc>().add(LookupTenantEvent(code.trim()));
  }

  Future<void> _applyBaseUrl(String newUrl) async {
    final trimmed = newUrl.trim();
    if (trimmed.isEmpty) return;
    await getIt<StorageService>().saveCustomBaseUrl(trimmed);
    getIt<DioClient>().updateBaseUrl(trimmed);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _scanQrCode() async {
    final scanned = await Navigator.of(context).push<QrTenantAccess>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (scanned == null || scanned.tenantCode.isEmpty || !mounted) return;

    if (scanned.suggestedBaseUrl != null &&
        scanned.suggestedBaseUrl != _activeBaseUrl) {
      await _applyBaseUrl(scanned.suggestedBaseUrl!);
      if (!mounted) return;
    }

    _codeController.text = scanned.tenantCode;
    _submitCode(scanned.tenantCode);
  }

  Future<void> _showServerSettingsDialog() async {
    final saved = await showDialog<String>(
      context: context,
      builder: (_) => _ServerSettingsDialog(
        initialUrl:
            getIt<StorageService>().getCustomBaseUrl() ?? _activeBaseUrl,
      ),
    );
    if (saved != null && saved.isNotEmpty) {
      await _applyBaseUrl(saved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật máy chủ: $saved')),
        );
      }
    }
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
            context.go('/jobs');
          } else if (state is TenantError) {
            final isUsingLocalServer = _activeBaseUrl != ApiConstants.productionBaseUrl;
            final currentCode = _codeController.text.trim();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                duration: const Duration(seconds: 6),
                action: isUsingLocalServer
                    ? SnackBarAction(
                        label: 'Dùng smarthire.top',
                        textColor: Colors.white,
                        onPressed: () async {
                          await _applyBaseUrl(ApiConstants.productionBaseUrl);
                          if (currentCode.isNotEmpty && mounted) {
                            _submitCode(currentCode);
                          }
                        },
                      )
                    : null,
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
                      // Header Brand Logo
                      Center(
                        child: Image.asset(
                          'assets/images/logo_smarthire.png',
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cổng Ứng Viên',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
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
                      const SizedBox(height: 16),

                      // Active Server Indicator
                      Center(
                        child: TextButton.icon(
                          onPressed: isLoading ? null : _showServerSettingsDialog,
                          icon: Icon(
                            Icons.dns_outlined,
                            size: 16,
                            color: theme.colorScheme.outline,
                          ),
                          label: Text(
                            'Máy chủ: $_activeBaseUrl',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
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

class _ServerSettingsDialog extends StatefulWidget {
  final String initialUrl;

  const _ServerSettingsDialog({required this.initialUrl});

  @override
  State<_ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<_ServerSettingsDialog> {
  late final TextEditingController _urlController =
      TextEditingController(text: widget.initialUrl);

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Cấu hình Máy chủ API',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa chỉ Backend API của hệ thống SmartHire:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: ApiConstants.productionBaseUrl,
                prefixIcon: Icon(Icons.dns_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Production (smarthire.top)'),
                  onPressed: () =>
                      _urlController.text = ApiConstants.productionBaseUrl,
                ),
                ActionChip(
                  label: const Text('USB Cáp (localhost)'),
                  onPressed: () =>
                      _urlController.text = ApiConstants.localReverseBaseUrl,
                ),
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)'),
                  onPressed: () =>
                      _urlController.text = ApiConstants.emulatorBaseUrl,
                ),
                ActionChip(
                  label: const Text('Wi-Fi LAN'),
                  onPressed: () => _urlController.text = ApiConstants.lanBaseUrl,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            final newUrl = _urlController.text.trim();
            if (newUrl.isNotEmpty) {
              Navigator.pop(context, newUrl);
            }
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
