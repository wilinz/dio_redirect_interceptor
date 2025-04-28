import 'dart:async';

import 'package:dio/dio.dart';

import 'exception.dart';
import 'internal/parse_http_location.dart';

typedef RedirectCallback =
    bool Function(Response response, ResponseInterceptorHandler handler);

typedef RedirectValidator = bool Function(Response response);

class RedirectInterceptor extends Interceptor {
  final FutureOr<Dio> Function() dio;
  final RedirectCallback? _redirectCallback;
  RedirectValidator? __redirectValidator;
  final int maxRedirectCount;

  RedirectValidator get _redirectValidator => __redirectValidator!;

  RedirectValidator get _defaultRedirectValidator => (Response response) {
    final statusCode = response.statusCode;
    return statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 303 ||
        statusCode == 307 ||
        statusCode == 308;
  };

  static const String followRedirects = "followRedirects";
  static const String rawUri = "rawUri";
  static const String rawRequestOption = "rawRequestOption";
  static const String redirectCount = "redirectCount";

  RedirectInterceptor(
    this.dio, {
    RedirectCallback? onRedirect,
    RedirectValidator? redirectValidator,
    this.maxRedirectCount = 10,
  }) : _redirectCallback = onRedirect {
    __redirectValidator = redirectValidator ?? _defaultRedirectValidator;
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final isFollowRedirects =
        response.requestOptions.extra[followRedirects] as bool? ?? true;
    if (!isFollowRedirects) {
      handler.next(response);
      return;
    }

    final rawUriValue = response.requestOptions.extra[rawUri] as Uri?;
    if (rawUriValue == null) {
      response.requestOptions.extra[rawUri] = response.requestOptions.uri;
    }
    final rawRequestOptionValue =
        response.requestOptions.extra[rawRequestOption];
    if (rawRequestOptionValue == null) {
      response.requestOptions.extra[rawRequestOption] = response.requestOptions;
    }

    if (_redirectValidator(response)) {
      try {
        final redirectCountValue =
            response.requestOptions.extra[redirectCount] ?? 0;
        if (redirectCountValue >= maxRedirectCount) {
          handler.next(response);
          return;
        }
        if (_redirectCallback != null &&
            !_redirectCallback.call(response, handler)) {
          return;
        }
        final location = response.headers.value('location');
        if (location == null) throw DioRedirectInterceptorException("Redirect location is null");
        final requestOptions = response.requestOptions;
        final rawUri = requestOptions.uri.toString();
        final newUri = Uri.parse(parseHttpLocation(rawUri, location));
        response.requestOptions.extra[redirectCount] = redirectCountValue + 1;

        final option = Options(
          sendTimeout: requestOptions.sendTimeout,
          receiveTimeout: requestOptions.receiveTimeout,
          extra: requestOptions.extra,
          responseType: requestOptions.responseType,
          validateStatus: requestOptions.validateStatus,
          receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
          followRedirects: requestOptions.followRedirects,
          maxRedirects: requestOptions.maxRedirects,
          persistentConnection: requestOptions.persistentConnection,
          requestEncoder: requestOptions.requestEncoder,
          responseDecoder: requestOptions.responseDecoder,
          listFormat: requestOptions.listFormat,
        );

        final redirectResponse = await (await dio()).getUri(
          newUri,
          options: option,
        );
        return handler.next(redirectResponse);
      } on DioException catch (e) {
        return handler.reject(e);
      }
    }
    return handler.next(response);
  }
}
