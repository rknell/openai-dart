import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'errors.dart';
import 'http_log_event.dart';

class RetryConfig {
  const RetryConfig({
    this.enabled = true,
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 250),
  });

  final bool enabled;
  final int maxAttempts;
  final Duration initialDelay;
}

class ApiHttpClient {
  ApiHttpClient({
    required this.apiKey,
    required this.baseUrl,
    required this.timeout,
    required this.retryConfig,
    HttpLogCallback? onHttpLog,
    http.Client? httpClient,
  })  : _onHttpLog = onHttpLog,
        _httpClient = httpClient ?? http.Client();

  final String apiKey;
  final String baseUrl;
  final Duration timeout;
  final RetryConfig retryConfig;
  final HttpLogCallback? _onHttpLog;
  final http.Client _httpClient;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

  Future<JsonResponse> getJson(String path) async {
    return _withRetry(() async {
      try {
        final stopwatch = Stopwatch()..start();
        final uri = _uri(path);
        final response = await _httpClient
            .get(uri, headers: _headers)
            .timeout(timeout);
        stopwatch.stop();
        final callback = _onHttpLog;
        if (callback != null) {
          callback(HttpLogEvent(
            method: 'GET',
            uri: uri,
            statusCode: response.statusCode,
            duration: stopwatch.elapsed,
            requestHeaders: HttpLogEvent.sanitizeHeaders(_headers),
            requestBody: null,
            responseHeaders: response.headers,
            responseBody: response.body.isNotEmpty ? response.body : null,
          ));
        }
        return _parseResponse(response);
      } on TimeoutException catch (e) {
        throw APIConnectionError('Request timeout: $e');
      } on http.ClientException catch (e) {
        throw APIConnectionError('Connection failed: $e');
      }
    });
  }

  Future<JsonResponse> postJson(String path, Map<String, dynamic> body) async {
    return _withRetry(() async {
      try {
        final stopwatch = Stopwatch()..start();
        final uri = _uri(path);
        final bodyStr = jsonEncode(body);
        final response = await _httpClient
            .post(uri, headers: _headers, body: bodyStr)
            .timeout(timeout);
        stopwatch.stop();
        final callback = _onHttpLog;
        if (callback != null) {
          callback(HttpLogEvent(
            method: 'POST',
            uri: uri,
            statusCode: response.statusCode,
            duration: stopwatch.elapsed,
            requestHeaders: HttpLogEvent.sanitizeHeaders(_headers),
            requestBody: bodyStr,
            responseHeaders: response.headers,
            responseBody: response.body.isNotEmpty ? response.body : null,
          ));
        }
        return _parseResponse(response);
      } on TimeoutException catch (e) {
        throw APIConnectionError('Request timeout: $e');
      } on http.ClientException catch (e) {
        throw APIConnectionError('Connection failed: $e');
      }
    });
  }

  Stream<Map<String, dynamic>> postSse(
    String path,
    Map<String, dynamic> body,
  ) async* {
    final stopwatch = Stopwatch()..start();
    final uri = _uri(path);
    final bodyStr = jsonEncode(body);
    final request = http.Request('POST', uri);
    request.headers.addAll(_headers);
    request.body = bodyStr;

    http.StreamedResponse response;
    try {
      response = await _httpClient.send(request).timeout(timeout);
    } on TimeoutException catch (e) {
      throw APIConnectionError('Request timeout: $e');
    } on http.ClientException catch (e) {
      throw APIConnectionError('Connection failed: $e');
    }

    stopwatch.stop();
    final callback = _onHttpLog;
    if (callback != null) {
      callback(HttpLogEvent(
        method: 'POST',
        uri: uri,
        statusCode: response.statusCode,
        duration: stopwatch.elapsed,
        requestHeaders: HttpLogEvent.sanitizeHeaders(_headers),
        requestBody: bodyStr,
        responseHeaders: response.headers,
        responseBody: null, // SSE stream - body not captured
      ));
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final raw = await response.stream.bytesToString();
      Map<String, dynamic>? bodyJson;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          bodyJson = decoded;
        }
      } catch (_) {}

      final message =
          (bodyJson?['error']?['message'] as String?) ??
          'HTTP ${response.statusCode}';
      throwForStatus(response.statusCode, message, bodyJson);
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final dataLines = <String>[];
    await for (final line in lines) {
      if (line.isEmpty) {
        if (dataLines.isEmpty) {
          continue;
        }

        final data = dataLines.join('\n');
        dataLines.clear();

        if (data == '[DONE]') {
          break;
        }

        try {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, dynamic>) {
            yield decoded;
          }
        } catch (_) {
          // Ignore malformed event lines.
        }
        continue;
      }

      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }
  }

  Future<JsonResponse> _withRetry(
    Future<JsonResponse> Function() operation,
  ) async {
    if (!retryConfig.enabled) {
      return operation();
    }

    var attempt = 0;
    var delay = retryConfig.initialDelay;

    while (true) {
      attempt += 1;
      try {
        return await operation();
      } on APIConnectionError {
        if (attempt >= retryConfig.maxAttempts) {
          rethrow;
        }
      } on RateLimitError {
        if (attempt >= retryConfig.maxAttempts) {
          rethrow;
        }
      } on InternalServerError {
        if (attempt >= retryConfig.maxAttempts) {
          rethrow;
        }
      }

      await Future<void>.delayed(delay);
      delay *= 2;
    }
  }

  JsonResponse _parseResponse(http.Response response) {
    Map<String, dynamic>? bodyJson;
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        bodyJson = decoded;
      } else {
        bodyJson = <String, dynamic>{'data': decoded};
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          (bodyJson?['error']?['message'] as String?) ??
          'HTTP ${response.statusCode}';
      throwForStatus(response.statusCode, message, bodyJson);
    }

    return JsonResponse(
      json: bodyJson ?? const <String, dynamic>{},
      requestId: response.headers['x-request-id'],
    );
  }
}

class JsonResponse {
  const JsonResponse({required this.json, this.requestId});

  final Map<String, dynamic> json;
  final String? requestId;
}
