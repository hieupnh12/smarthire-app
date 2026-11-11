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

    test('Extract production baseUrl from smarthire.top QR JSON', () {
      const qrJson = '''{
  "type": "TENANT_ACCESS",
  "tenantId": "se36",
  "tenantCode": "se36",
  "url": "https://se36.smarthire.top/career?tenantId=se36&source=mobile_app_qr"
}''';

      final access = QrCodeParser.extractTenantAccess(qrJson);
      expect(access.tenantCode, equals('se36'));
      expect(access.suggestedBaseUrl, equals('https://smarthire.top/api/v1'));
    });

    test('Map Vite LAN port 5173 in QR url to backend port 8080', () {
      const lanUrl = 'http://10.12.48.107:5173/career?tenantId=acme';
      final access = QrCodeParser.extractTenantAccess(lanUrl);
      expect(access.tenantCode, equals('acme'));
      expect(access.suggestedBaseUrl, equals('http://10.12.48.107:8080/api/v1'));
    });

    test('Do not override baseUrl to localhost when QR comes from localhost dev web', () {
      const localUrl = 'http://localhost:5173/career?tenantId=acme';
      final access = QrCodeParser.extractTenantAccess(localUrl);
      expect(access.tenantCode, equals('acme'));
      expect(access.suggestedBaseUrl, isNull);
    });
  });
}
