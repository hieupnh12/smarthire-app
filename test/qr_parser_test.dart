import 'package:flutter_test/flutter_test.dart';
import 'package:smarthire_app/features/tenant/utils/qr_code_parser.dart';

void main() {
  group('QrCodeParser Tests', () {
    test('Parse exact JSON from SmartHire Web QR', () {
      const qrJson = '''{
  "type": "TENANT_ACCESS",
  "tenantId": "acme",
  "tenantCode": "acme",
  "tenantName": "Acme Corp",
  "action": "SELECT_TENANT",
  "url": "http://localhost:5173/career?tenantId=acme&source=mobile_app_qr",
  "deepLink": "smarthire://tenant?tenantId=acme"
}''';

      final code = QrCodeParser.extractTenantCode(qrJson);
      expect(code, equals('acme'));
    });

    test('Parse URL with query parameter', () {
      const url = 'http://localhost:5173/career?tenantId=acme&source=mobile_app_qr';
      final code = QrCodeParser.extractTenantCode(url);
      expect(code, equals('acme'));
    });

    test('Parse Subdomain URL', () {
      const url = 'https://acme.smarthire.top';
      final code = QrCodeParser.extractTenantCode(url);
      expect(code, equals('acme'));
    });

    test('Parse plain text tenant code', () {
      const plain = 'acme';
      final code = QrCodeParser.extractTenantCode(plain);
      expect(code, equals('acme'));
    });
  });
}
