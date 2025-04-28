import 'package:dio/dio.dart';
import 'package:dio_redirect_interceptor/src/extension.dart';
import 'package:dio_redirect_interceptor/src/redirect_interceptor.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      validateStatus: (status) => status != null && status < 400,
      followRedirects: false,
    ),
  );
  dio.interceptors.addAll([
    // CookieManager(_cookieJar),
    RedirectInterceptor(() => dio),
  ]);
  final response = await dio.get(
    'http://facebook.com',
  ); // auto redirect to https://www.facebook.com
  print("statusCode: ${response.statusCode}");
  print("rawRequestOption uri: ${response.rawRequestOption?.uri}");
  print("redirectCount: ${response.redirectCount}");
  print("uri: ${response.requestOptions.uri}");
  print("rawUri: ${response.rawUri}"); // eq response.rawRequestOption?.uri

  print("-" * 50);
  // disable redirect
  final response1 = await dio.get(
    'http://facebook.com',
    options: Options(extra: {RedirectInterceptor.followRedirects: false}),
  ); // auto redirect to https://www.facebook.com
  print("statusCode: ${response1.statusCode}");
  print("rawRequestOption uri: ${response1.rawRequestOption?.uri}");
  print("redirectCount: ${response1.redirectCount}");
  print("uri: ${response1.requestOptions.uri}");
  print("rawUri: ${response1.rawUri}"); // eq response.rawRequestOption?.uri
}

// output:
//
// statusCode: 200
// rawRequestOption uri: http://facebook.com
// redirectCount: 2
// uri: https://www.facebook.com/
// rawUri: http://facebook.com
// --------------------------------------------------
// statusCode: 301
// rawRequestOption uri: null
// redirectCount: 0
// uri: http://facebook.com
// rawUri: null

