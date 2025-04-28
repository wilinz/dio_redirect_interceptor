import 'package:dio/dio.dart';
import 'package:dio_redirect_interceptor/src/redirect_interceptor.dart';

extension RedirectInterceptorResponseExtension on Response {
  /// Get the original request option
  RequestOptions? get rawRequestOption {
    return requestOptions.extra[RedirectInterceptor.rawRequestOption] as RequestOptions?;
  }

  /// Get the number of redirects
  int get redirectCount {
    return requestOptions.extra[RedirectInterceptor.redirectCount] as int? ?? 0;
  }

  /// Get the original URI
  Uri? get rawUri {
    return requestOptions.extra[RedirectInterceptor.rawUri] as Uri?;
  }
}
