import 'package:openai_dart/openai_dart.dart';
import 'package:test/test.dart';

void main() {
  test('ChatCompletionCreateParams serializes expected keys', () {
    final params = ChatCompletionCreateParams(
      model: 'deepseek-chat',
      messages: const <ChatMessage>[
        ChatMessage(role: 'user', content: 'Hello'),
      ],
      maxTokens: 100,
      temperature: 1.0,
      responseFormat: const <String, dynamic>{'type': 'json_object'},
      thinking: const <String, dynamic>{'type': 'enabled'},
    );

    final json = params.toJson();
    expect(json['model'], 'deepseek-chat');
    expect(json['max_tokens'], 100);
    expect(json['messages'], isA<List<dynamic>>());
    expect(
      (json['response_format'] as Map<String, dynamic>)['type'],
      'json_object',
    );
    expect((json['thinking'] as Map<String, dynamic>)['type'], 'enabled');
  });

  test('ChatMessage roundtrip with tool_calls and reasoning_content', () {
    const message = ChatMessage(
      role: 'assistant',
      content: '',
      reasoningContent: 'think',
      toolCalls: <Map<String, dynamic>>[
        <String, dynamic>{'id': 'call_1'},
      ],
    );

    final json = message.toJson();
    final decoded = ChatMessage.fromJson(json);
    expect(decoded.reasoningContent, 'think');
    expect(decoded.toolCalls?.first['id'], 'call_1');
  });

  test('ToolDefinition.function serializes typed schema correctly', () {
    final tool = ToolDefinition.function(
      name: 'get_weather',
      description: 'Get weather by location',
      strict: true,
      parameters: const ToolParameters(
        properties: <String, dynamic>{
          'location': <String, dynamic>{'type': 'string'},
        },
        requiredFields: <String>['location'],
        additionalProperties: false,
      ),
    );

    final json = tool.toJson();
    final function = json['function'] as Map<String, dynamic>;
    final parameters = function['parameters'] as Map<String, dynamic>;

    expect(json['type'], 'function');
    expect(function['name'], 'get_weather');
    expect(function['description'], 'Get weather by location');
    expect(function['strict'], true);
    expect(parameters['type'], 'object');
    expect(
      (parameters['properties'] as Map<String, dynamic>).containsKey(
        'location',
      ),
      isTrue,
    );
    expect(parameters['required'], <String>['location']);
    expect(parameters['additionalProperties'], false);
  });
}
