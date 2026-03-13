/// Callback type for HTTP debug logging.
///
/// Invoked for each HTTP request/response when [OpenAI] is configured with
/// [OpenAI.onHttpLog]. Silent when null.
typedef HttpLogCallback = void Function(HttpLogEvent event);

/// Immutable event describing an HTTP request and response for debug logging.
///
/// Headers are sanitized: [Authorization] is redacted as `Bearer ***`.
/// Use with [OpenAI.onHttpLog] to log HTTP traffic.
class HttpLogEvent {
  const HttpLogEvent({
    required this.method,
    required this.uri,
    this.statusCode,
    this.duration,
    required this.requestHeaders,
    this.requestBody,
    this.responseHeaders,
    this.responseBody,
  });

  /// HTTP method (e.g. GET, POST).
  final String method;

  /// Full request URI.
  final Uri uri;

  /// HTTP status code, or null before response is received.
  final int? statusCode;

  /// Request duration, or null if not yet completed.
  final Duration? duration;

  /// Request headers with sensitive values redacted (e.g. Authorization: Bearer ***).
  final Map<String, String> requestHeaders;

  /// Request body as string, or null if none.
  final String? requestBody;

  /// Response headers, or null if not yet received.
  final Map<String, String>? responseHeaders;

  /// Response body as string, or null for empty/streaming.
  final String? responseBody;

  /// Sanitizes headers by redacting Authorization values.
  static Map<String, String> sanitizeHeaders(Map<String, String> headers) {
    final result = <String, String>{};
    for (final e in headers.entries) {
      final key = e.key.toLowerCase();
      if (key == 'authorization') {
        result[e.key] = 'Bearer ***';
      } else {
        result[e.key] = e.value;
      }
    }
    return result;
  }
}
