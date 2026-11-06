import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/core/services/cookie_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CookieSettingsService Normalization Tests', () {
    test('normalizeToNetscape handles JSON format from Cookie-Editor extension', () {
      const jsonInput = '''
[
  {
    "domain": ".instagram.com",
    "expirationDate": 1798765432,
    "hostOnly": false,
    "httpOnly": true,
    "name": "sessionid",
    "path": "/",
    "sameSite": "no_restriction",
    "secure": true,
    "session": false,
    "storeId": "0",
    "value": "12345%3AAbCdEf"
  },
  {
    "domain": ".instagram.com",
    "expirationDate": 1798765432,
    "hostOnly": false,
    "httpOnly": false,
    "name": "ds_user_id",
    "path": "/",
    "sameSite": "no_restriction",
    "secure": true,
    "session": false,
    "storeId": "0",
    "value": "987654321"
  }
]
''';

      final result = CookieSettingsService.instance.normalizeToNetscape(
        jsonInput,
        CookiePlatform.instagram,
      );

      expect(result, startsWith('# Netscape HTTP Cookie File'));
      expect(result, contains('.instagram.com\tTRUE\t/\tTRUE\t1798765432\tsessionid\t12345%3AAbCdEf'));
      expect(result, contains('.instagram.com\tTRUE\t/\tTRUE\t1798765432\tds_user_id\t987654321'));
    });

    test('normalizeToNetscape handles raw Netscape tab-separated input', () {
      const netscapeInput =
          '.instagram.com\tTRUE\t/\tTRUE\t1798765432\tsessionid\t12345%3AAbCdEf\n'
          '.instagram.com\tTRUE\t/\tTRUE\t1798765432\tds_user_id\t987654321';

      final result = CookieSettingsService.instance.normalizeToNetscape(
        netscapeInput,
        CookiePlatform.instagram,
      );

      expect(result, startsWith('# Netscape HTTP Cookie File'));
      expect(result, contains('sessionid\t12345%3AAbCdEf'));
      expect(result, contains('ds_user_id\t987654321'));
    });

    test('normalizeToNetscape handles header key=value pairs', () {
      const headerInput = 'sessionid=12345abc; ds_user_id=98765; csrftoken=token123';

      final result = CookieSettingsService.instance.normalizeToNetscape(
        headerInput,
        CookiePlatform.instagram,
      );

      expect(result, startsWith('# Netscape HTTP Cookie File'));
      expect(result, contains('.instagram.com\tTRUE\t/\tTRUE\t2147483647\tsessionid\t12345abc'));
      expect(result, contains('.instagram.com\tTRUE\t/\tTRUE\t2147483647\tds_user_id\t98765'));
      expect(result, contains('.instagram.com\tTRUE\t/\tTRUE\t2147483647\tcsrftoken\ttoken123'));
    });

    test('normalizeToNetscape returns empty string for empty input', () {
      final result = CookieSettingsService.instance.normalizeToNetscape(
        '   ',
        CookiePlatform.instagram,
      );
      expect(result, isEmpty);
    });
  });
}
