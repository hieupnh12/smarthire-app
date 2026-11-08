import 'dart:convert';

class QrCodeParser {
  QrCodeParser._();

  static String extractTenantCode(String raw) {
    var text = raw.trim();

    // 1. Trường hợp QR chứa JSON chuẩn từ web SmartHire:
    // {
    //   "type": "TENANT_ACCESS",
    //   "tenantId": "acme",
    //   "tenantCode": "acme",
    //   "tenantName": "Acme Corp",
    //   ...
    // }
    if (text.startsWith('{') && text.endsWith('}')) {
      try {
        final Map<String, dynamic> data = jsonDecode(text) as Map<String, dynamic>;
        final code = data['tenantId'] ?? data['tenantCode'] ?? data['tenant'] ?? data['code'];
        if (code != null && code.toString().trim().isNotEmpty) {
          return code.toString().trim().toLowerCase();
        }
      } catch (_) {}
    }

    // 2. Trường hợp QR là URL: https://acme.smarthire.top hoặc http://localhost:5173/career?tenantId=acme
    try {
      final uri = Uri.parse(text);

      // Query param: ?tenantId=acme
      if (uri.queryParameters.containsKey('tenantId')) {
        final param = uri.queryParameters['tenantId'];
        if (param != null && param.trim().isNotEmpty) {
          return param.trim().toLowerCase();
        }
      }

      // Subdomain: acme.smarthire.top
      if (uri.hasAuthority) {
        final host = uri.host;
        final parts = host.split('.');
        if (parts.length >= 3 && parts.first != 'www' && parts.first != 'app' && parts.first != 'api') {
          return parts.first.toLowerCase();
        }
      }

      // Path: /tenant/acme
      if (uri.pathSegments.contains('tenant')) {
        final index = uri.pathSegments.indexOf('tenant');
        if (index + 1 < uri.pathSegments.length) {
          return uri.pathSegments[index + 1].toLowerCase();
        }
      }
    } catch (_) {}

    // 3. Trường hợp text thuần: "acme"
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '').toLowerCase();
  }
}
