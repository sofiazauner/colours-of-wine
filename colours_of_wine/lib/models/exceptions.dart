class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}
