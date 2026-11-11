import 'dart:convert';
import '../../../core/constants/api_constants.dart';

class QrTenantAccess {
  final String tenantCode;
  final String? suggestedBaseUrl;

  const QrTenantAccess({
    required this.tenantCode,
    this.suggestedBaseUrl,
  });
}

class QrCodeParser {
  QrCodeParser._();

  static String extractTenantCode(String raw) {
    return extractTenantAccess(raw).tenantCode;
  }

  static QrTenantAccess extractTenantAccess(String raw) {
    final text = raw.trim();
    String? extractedCode;
    String? embeddedUrl;

    // 1. Trường hợp QR chứa JSON chuẩn từ web SmartHire
    if (text.startsWith('{') && text.endsWith('}')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          final code =
              decoded['tenantId'] ?? decoded['tenantCode'] ?? decoded['tenant'] ?? decoded['code'];
          if (code != null && code.toString().trim().isNotEmpty) {
            extractedCode = code.toString().trim().toLowerCase();
          }
          final url = decoded['url'];
          if (url is String && url.trim().isNotEmpty) {
            embeddedUrl = url.trim();
          }
        }
      } catch (_) {}
    }

    // 2. Phân tích URL (từ field url trong JSON hoặc chính chuỗi QR là URL)
    final urlCandidate = embeddedUrl ?? text;
    String? suggestedBaseUrl;
    final parsedUri = Uri.tryParse(urlCandidate);

    if (parsedUri != null && (parsedUri.hasScheme || parsedUri.hasAuthority)) {
      if (extractedCode == null && parsedUri.queryParameters.containsKey('tenantId')) {
        final param = parsedUri.queryParameters['tenantId'];
        if (param != null && param.trim().isNotEmpty) {
          extractedCode = param.trim().toLowerCase();
        }
      }

      if (parsedUri.hasAuthority) {
        final host = parsedUri.host.toLowerCase();
        if (extractedCode == null) {
          final parts = host.split('.');
          if (parts.length >= 3 &&
              parts.first != 'www' &&
              parts.first != 'app' &&
              parts.first != 'api') {
            extractedCode = parts.first;
          }
        }
        suggestedBaseUrl = _resolveApiBaseUrl(parsedUri);
      }

      if (extractedCode == null && parsedUri.pathSegments.contains('tenant')) {
        final index = parsedUri.pathSegments.indexOf('tenant');
        if (index + 1 < parsedUri.pathSegments.length) {
          extractedCode = parsedUri.pathSegments[index + 1].toLowerCase();
        }
      }
    }

    // 3. Fallback: text thuần
    extractedCode ??= text.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '').toLowerCase();

    return QrTenantAccess(
      tenantCode: extractedCode,
      suggestedBaseUrl: suggestedBaseUrl,
    );
  }

  static String? _resolveApiBaseUrl(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    if (host.isEmpty || (scheme != 'http' && scheme != 'https')) {
      return null;
    }

    // Production domain (smarthire.top hoặc subdomain.smarthire.top)
    if (host == 'smarthire.top' || host.endsWith('.smarthire.top')) {
      return ApiConstants.productionBaseUrl;
    }

    // Không tự ghi đè sang localhost vì trên điện thoại thật localhost không trỏ tới PC
    if (host == 'localhost' || host == '127.0.0.1') {
      return null;
    }

    if (scheme == 'https') {
      final portPart = uri.hasPort && uri.port != 443 ? ':${uri.port}' : '';
      return 'https://$host$portPart/api/v1';
    }

    // HTTP LAN: nếu QR lấy từ Vite dev server (:5173) thì trỏ sang backend (:8080)
    final port = uri.hasPort ? (uri.port == 5173 ? 8080 : uri.port) : null;
    final portPart = (port != null && port != 80) ? ':$port' : '';
    return 'http://$host$portPart/api/v1';
  }
}
