import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:test/test.dart';

void main() {
  group('HttpLogCallback', () {
    test('REGRESSION: onHttpLog is invoked for GET requests with sanitized headers',
        () async {
      final logEvents = <HttpLogEvent>[];
      final client = OpenAI(
        apiKey: 'sk-test-key',
        baseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'data': [],
              'object': 'list',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        onHttpLog: logEvents.add,
      );

      await client.models.list();

      expect(logEvents, hasLength(1));
      final event = logEvents.single;
      expect(event.method, 'GET');
      expect(event.uri.toString(), contains('/v1/models'));
      expect(event.statusCode, 200);
      expect(event.duration, isNotNull);
      expect(event.requestHeaders['Authorization'], 'Bearer ***');
      expect(event.responseBody, contains('"object":"list"'));
    });

    test('REGRESSION: onHttpLog is invoked for POST requests with request body',
        () async {
      final logEvents = <HttpLogEvent>[];
      final client = OpenAI(
        apiKey: 'sk-secret',
        baseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          return http.Response(
            jsonEncode({
              'id': 'cmpl_test',
              'object': 'chat.completion',
              'created': 0,
              'model': 'gpt-4',
              'choices': [
                {
                  'index': 0,
                  'message': {
                    'role': 'assistant',
                    'content': 'Hi',
                  },
                  'finish_reason': 'stop',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        onHttpLog: logEvents.add,
      );

      await client.chat.completions.create(
        ChatCompletionCreateParams(
          model: 'gpt-4',
          messages: [
            ChatMessage(role: 'user', content: 'Hello'),
          ],
        ),
      );

      expect(logEvents, hasLength(1));
      final event = logEvents.single;
      expect(event.method, 'POST');
      expect(event.uri.toString(), contains('/v1/chat/completions'));
      expect(event.statusCode, 200);
      expect(event.requestBody, contains('"model":"gpt-4"'));
      expect(event.requestHeaders['Authorization'], 'Bearer ***');
    });

    test('REGRESSION: when onHttpLog is null, no callback is invoked', () async {
      final client = OpenAI(
        apiKey: 'sk-test',
        baseUrl: 'https://api.example.com',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      await client.models.list();

      // No callback to invoke - test passes if no throw
    });
  });
}
