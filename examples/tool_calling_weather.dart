import 'dart:convert';

import 'package:openai_dart/openai_dart.dart';

import '_utils.dart';

Future<void> main() async {
  final client = createClient();

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
          'Use tools to answer weather questions. Call get_weather before answering.',
    ),
    const ChatMessage(
      role: 'user',
      content: 'What is the weather in Hangzhou, Beijing, and Shanghai?',
    ),
  ];

  for (var i = 0; i < 8; i++) {
    final response = await client.chat.completions.create(
      ChatCompletionCreateParams(
        model: 'deepseek-chat',
        messages: messages,
        tools: tools,
        maxTokens: 256,
      ),
    );

    final assistant = response.firstMessage;
    if (assistant == null) {
      throw StateError('Missing assistant message');
    }
    messages.add(assistant);

    final calls = assistant.toolCalls ?? const <Map<String, dynamic>>[];
    if (calls.isEmpty) {
      print('Final answer:\n${assistant.content}');
      break;
    }

    for (final call in calls) {
      final callId = call['id'] as String?;
      final function = (call['function'] as Map?)?.cast<String, dynamic>();
      final name = function?['name'] as String? ?? '';
      final args =
          jsonDecode((function?['arguments'] as String?) ?? '{}')
              as Map<String, dynamic>;

      if (callId == null) {
        continue;
      }

      final result = _runTool(name, args);

      // Critical: tool_call_id must match assistant tool call id.
      messages.add(
        ChatMessage(
          role: 'tool',
          toolCallId: callId,
          name: name,
          content: result,
        ),
      );
    }
  }
}

String _runTool(String name, Map<String, dynamic> args) {
  if (name != 'get_weather') {
    return 'unsupported_tool';
  }

  final location = (args['location'] as String?)?.toLowerCase() ?? '';
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
