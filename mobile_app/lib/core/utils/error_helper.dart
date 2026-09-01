import 'package:dio/dio.dart';

/// Extracts a human-readable error message from any exception.
/// Prioritises the server-side message from the API response body.
String extractErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      // Our API returns { success, message } or { message }
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
      if (msg is List && msg.isNotEmpty) return msg.first.toString();
    }
    // HTTP status fallbacks
    final status = error.response?.statusCode;
    if (status == 401) return 'Session expired. Please sign in again.';
    if (status == 403) return data is Map
        ? (data['message']?.toString() ?? 'Access denied.')
        : 'Access denied.';
    if (status == 404) return 'The requested resource was not found.';
    if (status == 429) return 'Too many requests. Please slow down.';
    if (status != null && status >= 500) {
      return 'Server error. Please try again later.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Request timed out. Check your connection.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your connection.';
    }
  }
  final str = error.toString();
  // Strip Dart exception prefixes
  if (str.startsWith('Exception: ')) return str.substring(11);
  if (str.startsWith('Error: ')) return str.substring(7);
  return str;
}
