import 'dart:convert';
import 'dart:io';

import 'package:openai_dart/openai_dart.dart';
import 'package:test/test.dart';

void main() {
  final apiKey =
      Platform.environment['DEEPSEEK_API_KEY'] ??
      _readDotEnvValue('DEEPSEEK_API_KEY');
  final hasApiKey = apiKey != null && apiKey.isNotEmpty;

  group('DeepSeek integration', () {
    late OpenAI client;
    var integrationEnabled = hasApiKey;

    setUp(() {
      client = OpenAI(apiKey: apiKey ?? '');
    });

    setUpAll(() async {
      if (!hasApiKey) {
        return;
      }

      final probe = OpenAI(apiKey: apiKey);
      try {
        await probe.models.list();
      } on AuthenticationError {
        integrationEnabled = false;
      } catch (_) {
        // Keep integration enabled for non-auth failures, so they surface.
      }
    });

    test('lists models', () async {
      if (!integrationEnabled) {
        markTestSkipped(
          'DEEPSEEK_API_KEY is invalid; skipping integration tests.',
        );
        return;
      }
      final models = await client.models.list();
      expect(models.data, isNotEmpty);
    });

    test('basic chat completion', () async {
      if (!integrationEnabled) {
        markTestSkipped(
          'DEEPSEEK_API_KEY is invalid; skipping integration tests.',
        );
        return;
      }
      final response = await client.chat.completions.create(
        const ChatCompletionCreateParams(
          model: 'deepseek-chat',
          messages: <ChatMessage>[
            ChatMessage(role: 'user', content: 'Reply exactly: ok'),
          ],
          maxTokens: 32,
        ),
      );

      final content = response.firstMessage?.content ?? '';
      expect(content.toLowerCase(), contains('ok'));
    });

    test('json output returns parseable JSON content', () async {
      if (!integrationEnabled) {
        markTestSkipped(
          'DEEPSEEK_API_KEY is invalid; skipping integration tests.',
        );
        return;
      }
      final response = await client.chat.completions.create(
        const ChatCompletionCreateParams(
          model: 'deepseek-chat',
          messages: <ChatMessage>[
            ChatMessage(
              role: 'system',
              content: 'Return valid json only with keys question and answer.',
            ),
            ChatMessage(role: 'user', content: 'What is 2+2? 4'),
          ],
          responseFormat: <String, dynamic>{'type': 'json_object'},
          maxTokens: 128,
        ),
      );

      final content = response.firstMessage?.content ?? '{}';
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      expect(decoded.containsKey('question'), isTrue);
      expect(decoded.containsKey('answer'), isTrue);
    });

    test('streaming completion emits at least one chunk', () async {
      if (!integrationEnabled) {
        markTestSkipped(
          'DEEPSEEK_API_KEY is invalid; skipping integration tests.',
        );
        return;
      }
      final stream = client.chat.completions.createStream(
        const ChatCompletionCreateParams(
          model: 'deepseek-chat',
          messages: <ChatMessage>[
            ChatMessage(role: 'user', content: 'Write one short sentence.'),
          ],
          maxTokens: 32,
        ),
      );

      var seen = false;
      await for (final chunk in stream) {
        if (chunk.choices.isNotEmpty) {
          seen = true;
          break;
        }
      }

      expect(seen, isTrue);
    });

    test(
      'thinking mode returns reasoning and final response',
      () async {
        if (!integrationEnabled) {
          markTestSkipped(
            'DEEPSEEK_API_KEY is invalid; skipping integration tests.',
          );
          return;
        }

        final response = await client.chat.completions.create(
          const ChatCompletionCreateParams(
            model: 'deepseek-reasoner',
            messages: <ChatMessage>[
              ChatMessage(
                role: 'user',
                content: 'Which is larger, 9.11 or 9.8?',
              ),
            ],
            maxTokens: 256,
          ),
        );

        final message = response.firstMessage;
        expect(message, isNotNull);
        expect((message?.content ?? '').isNotEmpty, isTrue);
        final reasoning = message?.reasoningContent;
        if (reasoning != null) {
          expect(reasoning.isNotEmpty, isTrue);
        }
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test(
      'context caching fields are returned for repeated prefix',
      () async {
        if (!integrationEnabled) {
          markTestSkipped(
            'DEEPSEEK_API_KEY is invalid; skipping integration tests.',
          );
          return;
        }

        final repeatedPrefix =
            'You are a finance analyst. Analyze this report prefix: '
            '${List<String>.filled(180, 'revenue margin growth outlook').join(' ')}';

        Future<ChatCompletionResponse> run(String question) {
          return client.chat.completions.create(
            ChatCompletionCreateParams(
              model: 'deepseek-chat',
              messages: <ChatMessage>[
                const ChatMessage(
                  role: 'system',
                  content: 'You answer briefly in bullet points.',
                ),
                ChatMessage(
                  role: 'user',
                  content: '$repeatedPrefix\n\n$question',
                ),
              ],
              maxTokens: 128,
            ),
          );
        }

        await run('What are the top 3 profitability risks?');
        final second = await run(
          'What are the top 3 profitability opportunities?',
        );

        expect(second.usage, isNotNull);
        expect(second.usage!.promptCacheHitTokens, isNotNull);
        expect(second.usage!.promptCacheMissTokens, isNotNull);
        expect(second.usage!.promptCacheHitTokens! >= 0, isTrue);
        expect(second.usage!.promptCacheMissTokens! >= 0, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test(
      'chat prefix completion works on beta endpoint',
      () async {
        if (!integrationEnabled) {
          markTestSkipped(
            'DEEPSEEK_API_KEY is invalid; skipping integration tests.',
          );
          return;
        }

        final betaClient = OpenAI(
          apiKey: apiKey!,
          baseUrl: 'https://api.deepseek.com/beta',
        );

        final response = await betaClient.chat.completions.create(
          const ChatCompletionCreateParams(
            model: 'deepseek-chat',
            messages: <ChatMessage>[
              ChatMessage(role: 'user', content: 'Write quick sort in Python'),
              ChatMessage(
                role: 'assistant',
                content: '```python\n',
                prefix: true,
              ),
            ],
            stop: <String>['```'],
            maxTokens: 256,
          ),
        );

        final content = response.firstMessage?.content ?? '';
        expect(content.isNotEmpty, isTrue);
        expect(content.toLowerCase().contains('def'), isTrue);
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test(
      'strict mode tool definition works on beta endpoint',
      () async {
        if (!integrationEnabled) {
          markTestSkipped(
            'DEEPSEEK_API_KEY is invalid; skipping integration tests.',
          );
          return;
        }

        final betaClient = OpenAI(
          apiKey: apiKey!,
          baseUrl: 'https://api.deepseek.com/beta',
        );

        final response = await betaClient.chat.completions.create(
          ChatCompletionCreateParams(
            model: 'deepseek-chat',
            messages: const <ChatMessage>[
              ChatMessage(
                role: 'user',
                content: 'Call get_weather for Boston.',
              ),
            ],
            tools: <ToolDefinition>[
              ToolDefinition.function(
                name: 'get_weather',
                strict: true,
                description: 'Get weather by city',
                parameters: const ToolParameters(
                  properties: <String, dynamic>{
                    'location': <String, dynamic>{'type': 'string'},
                  },
                  requiredFields: <String>['location'],
                  additionalProperties: false,
                ),
              ),
            ],
            toolChoice: const <String, dynamic>{
              'type': 'function',
              'function': <String, dynamic>{'name': 'get_weather'},
            },
            maxTokens: 128,
          ),
        );

        final message = response.firstMessage;
        expect(message, isNotNull);
        final calls = _extractToolCalls(message!);
        expect(calls, isNotEmpty);
        expect(calls.first.name, 'get_weather');
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test('error handling surfaces bad request for invalid model', () async {
      if (!integrationEnabled) {
        markTestSkipped(
          'DEEPSEEK_API_KEY is invalid; skipping integration tests.',
        );
        return;
      }

      expect(
        () => client.chat.completions.create(
          const ChatCompletionCreateParams(
            model: 'not-a-real-model',
            messages: <ChatMessage>[
              ChatMessage(role: 'user', content: 'hello'),
            ],
          ),
        ),
        throwsA(isA<BadRequestError>()),
      );
    });

    test(
      'multi-round weather conversation performs at least 3 tool calls in one conversation',
      () async {
        if (!integrationEnabled) {
          markTestSkipped(
            'DEEPSEEK_API_KEY is invalid; skipping integration tests.',
          );
          return;
        }

        final tools = <ToolDefinition>[
          ToolDefinition.function(
            name: 'get_weather',
            description: 'Get weather by location',
            parameters: const ToolParameters(
              properties: <String, dynamic>{
                'location': <String, dynamic>{'type': 'string'},
              },
              requiredFields: <String>['location'],
            ),
          ),
        ];

        final messages = <ChatMessage>[
          const ChatMessage(
            role: 'system',
            content:
                'Use tools to answer weather questions. '
                'For each requested city, call get_weather once before answering.',
          ),
          const ChatMessage(
            role: 'user',
            content:
                'What is the weather in Hangzhou, Beijing, and Shanghai? '
                'Use get_weather for each city, then summarize.',
          ),
        ];

        var toolCallCount = 0;
        ChatMessage? round1Final;

        for (var subTurn = 0; subTurn < 8; subTurn++) {
          final response = await client.chat.completions.create(
            ChatCompletionCreateParams(
              model: 'deepseek-chat',
              messages: messages,
              tools: tools,
              maxTokens: 256,
            ),
          );

          final assistant = response.firstMessage;
          expect(assistant, isNotNull);
          messages.add(assistant!);

          final calls = _extractToolCalls(assistant);
          if (calls.isEmpty) {
            round1Final = assistant;
            break;
          }

          for (final call in calls) {
            toolCallCount++;
            final toolOutput = _toolResultFor(call);
            messages.add(
              ChatMessage(
                role: 'tool',
                toolCallId: call.id,
                name: call.name,
                content: toolOutput,
              ),
            );
          }
        }

        expect(round1Final, isNotNull, reason: 'Round 1 did not finish.');
        expect(
          toolCallCount >= 3,
          isTrue,
          reason:
              'Expected at least 3 tool calls in one conversation; got $toolCallCount.',
        );
        expect((round1Final?.content ?? '').isNotEmpty, isTrue);

        _clearReasoningContent(messages);
        messages.add(
          const ChatMessage(
            role: 'user',
            content:
                'Based on that forecast, which city seems warmest and what should I wear?',
          ),
        );

        final round2 = await client.chat.completions.create(
          ChatCompletionCreateParams(
            model: 'deepseek-chat',
            messages: messages,
            tools: tools,
            maxTokens: 256,
          ),
        );
        final round2Message = round2.firstMessage;
        expect(round2Message, isNotNull);
        expect((round2Message?.content ?? '').isNotEmpty, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );
  }, skip: !hasApiKey);
}

String? _readDotEnvValue(String key) {
  final file = File('.env');
  if (!file.existsSync()) {
    return null;
  }

  final lines = file.readAsLinesSync();
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }

    final eq = line.indexOf('=');
    if (eq <= 0) {
      continue;
    }

    final k = line.substring(0, eq).trim();
    if (k != key) {
      continue;
    }

    var v = line.substring(eq + 1).trim();
    if (v.startsWith('"') && v.endsWith('"') && v.length >= 2) {
      v = v.substring(1, v.length - 1);
    } else if (v.startsWith("'") && v.endsWith("'") && v.length >= 2) {
      v = v.substring(1, v.length - 1);
    }
    return v;
  }

  return null;
}

void _clearReasoningContent(List<ChatMessage> messages) {
  for (var i = 0; i < messages.length; i++) {
    final m = messages[i];
    if (m.reasoningContent != null) {
      messages[i] = ChatMessage(
        role: m.role,
        content: m.content,
        name: m.name,
        toolCallId: m.toolCallId,
        prefix: m.prefix,
        toolCalls: m.toolCalls,
      );
    }
  }
}

List<_IntegrationToolCall> _extractToolCalls(ChatMessage message) {
  final output = <_IntegrationToolCall>[];
  for (final raw in message.toolCalls ?? const <Map<String, dynamic>>[]) {
    final id = raw['id'] as String?;
    final function = (raw['function'] as Map?)?.cast<String, dynamic>();
    final name = function?['name'] as String?;
    final argsRaw = function?['arguments'] as String? ?? '{}';
    if (id == null || name == null) {
      continue;
    }

    Map<String, dynamic> args;
    try {
      final decoded = jsonDecode(argsRaw);
      args = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'value': decoded};
    } catch (_) {
      args = <String, dynamic>{};
    }

    output.add(_IntegrationToolCall(id: id, name: name, arguments: args));
  }
  return output;
}

String _toolResultFor(_IntegrationToolCall call) {
  if (call.name == 'get_weather') {
    final location =
        (call.arguments['location'] as String?)?.toLowerCase() ?? '';
    if (location.contains('hangzhou')) {
      return 'Hangzhou: Cloudy 7~13C';
    }
    if (location.contains('beijing')) {
      return 'Beijing: Sunny 2~10C';
    }
    if (location.contains('shanghai')) {
      return 'Shanghai: Rainy 9~16C';
    }
    return 'Unknown: Cloudy 10~15C';
  }

  return 'unsupported_tool';
}

class _IntegrationToolCall {
  const _IntegrationToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  final String id;
  final String name;
  final Map<String, dynamic> arguments;
}
