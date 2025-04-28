class DioRedirectInterceptorException implements Exception {
  final String message;

  DioRedirectInterceptorException(this.message);

  @override
  String toString() => 'DioRedirectInterceptorException: $message';
}
