import 'dart:convert';

import 'package:openai_dart/openai_dart.dart';

import '_utils.dart';

Future<void> main() async {
  final client = createClient(beta: true);

  final response = await client.chat.completions.create(
    ChatCompletionCreateParams(
      model: 'deepseek-chat',
      messages: const <ChatMessage>[
        ChatMessage(role: 'user', content: 'Call get_weather for Boston.'),
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

  final calls =
      response.firstMessage?.toolCalls ?? const <Map<String, dynamic>>[];
  if (calls.isEmpty) {
    print('No tool call returned. Message: ${response.firstMessage?.content}');
    return;
  }

  final function =
      (calls.first['function'] as Map?)?.cast<String, dynamic>() ?? const {};
  print('Tool name: ${function['name']}');
  print(
    'Arguments: ${const JsonEncoder.withIndent('  ').convert(jsonDecode((function['arguments'] as String?) ?? '{}'))}',
  );
}
