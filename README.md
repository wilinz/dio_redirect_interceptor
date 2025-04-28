# Dio Redirect Interceptor

[中文简体](README_zh-CN.md)

## Background

`Dio` is a powerful HTTP client library, but its default redirect handling is done by the `http` library. This means that when a redirect occurs, the `http` library handles it automatically and returns the final response, and `Dio` interceptors (such as `CookieManager` or other custom interceptors) do not get a chance to run. As a result, many features that need to operate during the redirect process (such as saving cookies, modifying request headers, etc.) may not function correctly.

To solve this problem, we provide a custom `RedirectInterceptor` that can manually handle redirects, ensuring that all custom interceptors (such as `CookieManager` or others) can function properly during the redirect process.

## Features

- **Custom Redirect Handling**: By disabling Dio's default redirect behavior, the redirect process is manually handled by the `RedirectInterceptor`.
- **Works with CookieManager**: Ensures that cookies are correctly saved and managed during redirects.
- **Supports Other Custom Interceptors**: Not only supports `CookieManager`, but also works with any other interceptors that need to operate during the redirect process.
- **Redirect Count and URI Tracking**: Easily get redirect count, original request URI, and redirect URI through extension methods.

## Installation

Add the following dependencies to your `pubspec.yaml` file:

```yaml
dependencies:
  dio: ^5.8.0+1
  dio_redirect_interceptor: ^1.0.0
  dio_cookie_manager: ^3.2.0
  cookie_jar: ^4.0.8
```

Then run the following command to install the dependencies:

```bash
flutter pub get
```

## Setup Example

### Create Dio Instance and Use the Interceptors

```dart
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';

Future<void> main() async {
  // Create a CookieJar instance to store cookies
  final cookieJar = CookieJar();

  // Create a Dio instance and disable the default redirect handling
  final dio = Dio(
    BaseOptions(
      validateStatus: (status) => status != null && status < 400,
      followRedirects: false,  // Disable Dio's default redirect handling
    ),
  );

  // Add interceptors: CookieManager and RedirectInterceptor
  dio.interceptors.addAll([
    CookieManager(cookieJar),  // Manage cookies
    RedirectInterceptor(() => dio),  // Handle redirects
  ]);

  // Perform a request and automatically handle redirects
  final response = await dio.get('http://facebook.com');
  print("statusCode: ${response.statusCode}");
  print("rawRequestOption uri: ${response.rawRequestOption?.uri}");
  print("redirectCount: ${response.redirectCount}");
  print("uri: ${response.requestOptions.uri}");
  print("rawUri: ${response.rawUri}");

  // Get cookies
  final cookies = await cookieJar.loadForRequest(Uri.parse('http://facebook.com'));
  print("Cookies: $cookies");
}
```

### Code Explanation

- **CookieManager**: Used to save and load cookies. The `CookieJar` persists cookies between requests and responses.
- **RedirectInterceptor**: A custom interceptor that manually handles HTTP redirects. It disables Dio's default redirect handling, ensuring that `CookieManager` can properly save cookies.
- **followRedirects**: By setting `followRedirects` to `false`, we disable Dio's default redirect handling. All redirects are manually handled by the `RedirectInterceptor`.

### Output Example

If you request `http://facebook.com`, which redirects (e.g., to `https://www.facebook.com`), the output will be:

```
statusCode: 200
rawRequestOption uri: http://facebook.com
redirectCount: 2
uri: https://www.facebook.com/
rawUri: http://facebook.com
Cookies: [...]
```

## Using Extension Methods to Get Redirect Information

This library provides extension methods on `Response` to easily access detailed redirect information:

### `RedirectInterceptorResponseExtension` Extension

```dart
import 'package:dio/dio.dart';
import 'package:dio_redirect_interceptor/src/extension.dart';

extension RedirectInterceptorResponseExtension on Response {
  /// Get the original request options
  RequestOptions? get rawRequestOption {
    return requestOptions.extra[RedirectInterceptor.rawRequestOption] as RequestOptions?;
  }

  /// Get the redirect count
  int get redirectCount {
    return requestOptions.extra[RedirectInterceptor.redirectCount] as int? ?? 0;
  }

  /// Get the original URI
  Uri? get rawUri {
    return requestOptions.extra[RedirectInterceptor.rawUri] as Uri?;
  }
}
```

### Example Code: Get Redirect Information

```dart
import 'package:dio/dio.dart';
import 'package:dio_redirect_interceptor/src/extension.dart';
import 'package:dio_redirect_interceptor/src/redirect_interceptor.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      validateStatus: (status) => status != null && status < 400,
      followRedirects: false,  // Disable Dio's default redirect handling
    ),
  );
  dio.interceptors.addAll([
    RedirectInterceptor(() => dio),  // Use the RedirectInterceptor
  ]);

  // Perform a request and automatically handle redirects
  final response = await dio.get('http://facebook.com');
  print("statusCode: ${response.statusCode}");
  print("rawRequestOption uri: ${response.rawRequestOption?.uri}");
  print("redirectCount: ${response.redirectCount}");
  print("uri: ${response.requestOptions.uri}");
  print("rawUri: ${response.rawUri}");

  print("-" * 50);

  // Disable redirect
  final response1 = await dio.get(
    'http://facebook.com',
    options: Options(extra: {RedirectInterceptor.followRedirects: false}),
  );
  print("statusCode: ${response1.statusCode}");
  print("rawRequestOption uri: ${response1.rawRequestOption?.uri}");
  print("redirectCount: ${response1.redirectCount}");
  print("uri: ${response1.requestOptions.uri}");
  print("rawUri: ${response1.rawUri}");
}
```

### Example Output

```text
statusCode: 200
rawRequestOption uri: http://facebook.com
redirectCount: 2
uri: https://www.facebook.com/
rawUri: http://facebook.com
--------------------------------------------------
statusCode: 301
rawRequestOption uri: null
redirectCount: 0
uri: http://facebook.com
rawUri: null
```

## Solved Issues

### Dio's Default Redirect Handling

Dio's default redirect behavior is handled by the `http` library, meaning that when a redirect occurs, the `http` library automatically handles the request and returns the final response. Dio's interceptors do not get a chance to process the redirected request. This behavior causes issues with interceptors that need to perform actions during the redirect, such as `CookieManager` or any custom interceptors that handle headers, cookies, or other data.

### Solution: Disable Default Redirect Handling

By setting the `followRedirects` option to `false`, we disable Dio's default redirect behavior. Then, the `RedirectInterceptor` manually handles redirects, ensuring that interceptors such as `CookieManager` can function properly during the redirect process. This allows you to control the redirect process more finely and ensures that custom interceptors can work as expected.

## Conclusion

The `RedirectInterceptor` provided by this library effectively solves the issue of Dio's default redirect handling. By disabling Dio's default redirect behavior, you gain full control over the redirect process, ensuring that interceptors like `CookieManager` and other custom interceptors can function properly during the redirect process. This approach allows for more precise request handling and management, including cookie management, custom header handling, and more.

## License
MIT License. See LICENSE for details.

Now the README.md includes the MIT License section at the end. You can also include a separate LICENSE file with the MIT License text.

---