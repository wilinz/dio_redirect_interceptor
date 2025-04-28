# Dio 重定向拦截器

[English](README.md)

## 背景

`Dio` 是一个功能强大的 HTTP 客户端库，但其默认的重定向处理由 `http` 库完成。这意味着当发生重定向时，`http` 库会自动处理这些请求并返回最终响应，`Dio` 的拦截器（如 `CookieManager` 或其他自定义拦截器）无法在重定向过程中执行。由于此行为，许多需要在重定向过程中进行处理的功能（例如，保存 cookies、修改请求头等）可能会失效。

为了解决这个问题，我们提供了一个自定义的 `RedirectInterceptor`，该拦截器可以手动处理重定向，从而确保所有自定义拦截器（如 `CookieManager` 或其他）能够在重定向过程中正常工作。

## 特性

- **自定义重定向处理**：通过禁用 `Dio` 默认的重定向行为，重定向过程将由 `RedirectInterceptor` 拦截器手动处理。
- **与 CookieManager 配合使用**：确保在重定向过程中能够正确保存和管理 cookies。
- **支持其他自定义拦截器**：不仅支持 `CookieManager`，还可以与其他任何需要在请求重定向过程中执行的拦截器配合使用。
- **重定向计数和 URI 路径**：通过扩展方法，轻松获取重定向次数、原始请求 URI 和重定向后的 URI。

## 安装

首先，在 `pubspec.yaml` 文件中添加以下依赖：

```yaml
dependencies:
  dio: ^5.8.0+1
  dio_redirect_interceptor: ^1.0.0
  dio_cookie_manager: ^3.2.0
  cookie_jar: ^4.0.8
```

然后运行以下命令安装依赖：

```bash
flutter pub get
```

## 配置示例

### 创建 `Dio` 实例并使用拦截器

```dart
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';

Future<void> main() async {
  // 创建 CookieJar 实例，用于保存 cookies
  final cookieJar = CookieJar();

  // 创建 Dio 实例，禁用默认重定向处理
  final dio = Dio(
    BaseOptions(
      validateStatus: (status) => status != null && status < 400,
      followRedirects: false,  // 禁用 Dio 默认的重定向处理
    ),
  );

  // 添加拦截器：CookieManager 和 RedirectInterceptor
  dio.interceptors.addAll([
    CookieManager(cookieJar),  // 管理 cookies
    RedirectInterceptor(() => dio),  // 处理重定向
  ]);

  // 执行请求并自动处理重定向
  final response = await dio.get('http://facebook.com');
  print("statusCode: ${response.statusCode}");
  print("rawRequestOption uri: ${response.rawRequestOption?.uri}");
  print("redirectCount: ${response.redirectCount}");
  print("uri: ${response.requestOptions.uri}");
  print("rawUri: ${response.rawUri}");

  // 获取 cookies
  final cookies = await cookieJar.loadForRequest(Uri.parse('http://facebook.com'));
  print("Cookies: $cookies");
}
```

### 代码解释

- **CookieManager**：用于保存和加载 cookies。`CookieJar` 会在请求和响应之间持久化 cookies。
- **RedirectInterceptor**：自定义拦截器，用于手动处理 HTTP 重定向。禁用 `Dio` 默认的重定向处理，确保 `CookieManager` 能正确保存 cookies。
- **followRedirects**：通过将 `followRedirects` 设置为 `false`，我们禁用了默认的重定向处理。所有重定向都将由 `RedirectInterceptor` 处理。

### 测试输出

假设您请求 `http://facebook.com`，并且发生了重定向（例如，重定向到 `https://www.facebook.com`），输出如下：

```
statusCode: 200
rawRequestOption uri: http://facebook.com
redirectCount: 2
uri: https://www.facebook.com/
rawUri: http://facebook.com
Cookies: [Cookie: ...]
```

## 使用扩展方法获取重定向信息

本库提供了 `Response` 的扩展方法，帮助您轻松获取与重定向相关的详细信息：

### `RedirectInterceptorResponseExtension` 扩展

```dart
import 'package:dio/dio.dart';
import 'package:dio_redirect_interceptor/src/extension.dart';

extension RedirectInterceptorResponseExtension on Response {
  /// 获取原始请求选项
  RequestOptions? get rawRequestOption {
    return requestOptions.extra[RedirectInterceptor.rawRequestOption] as RequestOptions?;
  }

  /// 获取重定向次数
  int get redirectCount {
    return requestOptions.extra[RedirectInterceptor.redirectCount] as int? ?? 0;
  }

  /// 获取原始 URI
  Uri? get rawUri {
    return requestOptions.extra[RedirectInterceptor.rawUri] as Uri?;
  }
}
```

### 示例代码：获取重定向信息

```dart
import 'package:dio/dio.dart';
import 'package:dio_redirect_interceptor/src/extension.dart';
import 'package:dio_redirect_interceptor/src/redirect_interceptor.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      validateStatus: (status) => status != null && status < 400,
      followRedirects: false,  // 禁用 Dio 默认的重定向处理
    ),
  );
  dio.interceptors.addAll([
    RedirectInterceptor(() => dio),  // 使用重定向拦截器
  ]);

  // 执行请求，自动重定向
  final response = await dio.get('http://facebook.com');
  print("statusCode: ${response.statusCode}");
  print("rawRequestOption uri: ${response.rawRequestOption?.uri}");
  print("redirectCount: ${response.redirectCount}");
  print("uri: ${response.requestOptions.uri}");
  print("rawUri: ${response.rawUri}");

  print("-" * 50);

  // 禁用重定向
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

### 输出结果

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

## 解决的问题

### `Dio` 默认的重定向处理

`Dio` 默认的重定向行为由 `http` 库处理，意味着当发生重定向时，`http` 库会自动处理这些请求并返回最终响应，`Dio` 的拦截器无法捕获到重定向请求。这会导致某些功能（如 `CookieManager`）在重定向过程中失效。如果您使用自定义的拦截器（例如修改请求头、处理 cookies 等），也可能会遇到无法正确处理重定向的情况。

### 解决方案：禁用默认重定向

通过将 `Dio` 配置中的 `followRedirects` 设置为 `false`，我们禁用了默认的重定向处理。然后，使用 `RedirectInterceptor` 拦截器手动处理重定向过程，确保拦截器能够正确执行。例如，`CookieManager` 可以在重定向过程中正确管理 cookies，其他自定义拦截器也可以在重定向过程中按预期执行。

## 总结

本库提供的 `RedirectInterceptor` 可以有效解决 `Dio` 默认重定向处理的问题，确保在重定向过程中所有需要执行的拦截器（如 `CookieManager` 和自定义拦截器）能够正常工作。通过禁用默认重定向处理，您可以完全控制重定向过程，从而实现更精细的请求控制和处理。