import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:dio_redirect_interceptor/src/internal/parse_http_location.dart';
import 'package:test/test.dart';

import 'package:test/test.dart';

void main() {
  group('parseHttpLocation', () {
    test('should return the absolute URL if location contains "://"', () {
      final rawUri = 'https://example.com/page';
      final location = 'https://other.com/path';

      final result = parseHttpLocation(rawUri, location);

      expect(result, 'https://other.com/path');
    });

    test('should return location with "http://" if it starts with "://"', () {
      final rawUri = 'https://example.com/page';
      final location = '://other.com/path';

      final result = parseHttpLocation(rawUri, location);

      expect(result, 'https://other.com/path');
    });

    test('should resolve relative path starting with "/"', () {
      final rawUri = 'https://example.com/page';
      final location = '/newpath';

      final result = parseHttpLocation(rawUri, location);

      expect(result, 'https://example.com/newpath');
    });

    test('should resolve relative path without "/"', () {
      final rawUri = 'https://example.com/page';
      final location = 'anotherpath';

      final result = parseHttpLocation(rawUri, location);

      expect(result, 'https://example.com/anotherpath');
    });

    test('should resolve relative path with query parameters', () {
      final rawUri = 'https://example.com/page';
      final location = 'search?query=flutter';

      final result = parseHttpLocation(rawUri, location);

      expect(result, 'https://example.com/search?query=flutter');
    });

    test('should resolve relative path with query parameters and / suffix', () {
      final rawUri = 'https://example.com/page/';
      final location = 'search?query=flutter';

      final result = parseHttpLocation(rawUri, location);

      expect(result, 'https://example.com/page/search?query=flutter');
    });

    test('should resolve relative path with fragment', () {
      final rawUri = 'https://example.com/page';
      final location = 'section#header';

      final result = parseHttpLocation(rawUri, location);

      expect(result, 'https://example.com/section#header');
    });

    test('should resolve relative path with / suffix', () {
      final rawUri = 'https://example.com/page/';
      final location = 'section#header';

      final result = parseHttpLocation(rawUri, location);

      expect(result, 'https://example.com/page/section#header');
    });
  });
}
