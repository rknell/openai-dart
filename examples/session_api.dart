import 'dart:convert';

import 'package:openai_dart/openai_dart.dart';

import '_utils.dart';

Future<void> main() async {
  final client = createClient();

  final session = client.sessions.create(model: 'deepseek-chat');
  session.setSystemMessage('You are a concise weather assistant.');
  session.addTool(
    ToolDefinition.function(
      name: 'get_weather',
      description: 'Get weather by location',
      parameters: ToolParameters(
        properties: <String, dynamic>{
          'location': <String, dynamic>{'type': 'string'},
        },
        requiredFields: <String>['location'],
      ),
    ),
  );

  // Turn 1: user asks for 3 cities.
  await session.sendMessage(
    'What is the weather in Hangzhou, Beijing, and Shanghai?',
  );

  // Resolve tool calls until assistant gives final answer.
  await _resolvePendingToolCalls(session);
  final turn1Answer = session.messages.last;
  print('Turn 1 answer:\n${turn1Answer.content}\n');

  // Context extraction/edit convenience.
  final snapshot = session.contextSnapshot();
  print('Context messages after turn 1: ${snapshot.length}');

  // Example: remove historical reasoning fields (if any) and replace context.
  final cleaned = snapshot
      .map(
        (m) => ChatMessage(
          role: m.role,
          content: m.content,
          name: m.name,
          toolCallId: m.toolCallId,
          prefix: m.prefix,
          toolCalls: m.toolCalls,
        ),
      )
      .toList(growable: false);
  session.replaceContext(cleaned);

  // Turn 2: follow-up question in the same session context.
  await session.sendMessage(
    'Which city seems warmest, and what should I wear?',
  );
  await _resolvePendingToolCalls(session);
  final turn2Answer = session.messages.last;
  print('Turn 2 answer:\n${turn2Answer.content}');
}

Future<void> _resolvePendingToolCalls(ChatSession session) async {
  while (true) {
    if (session.pendingToolCallIds.isEmpty) {
      final last = session.messages.isEmpty ? null : session.messages.last;
      final calls = _extractToolCalls(last);
      if (calls.isEmpty) {
        return;
      }
      for (final call in calls) {
        session.addToolResultForCall(call, _runTool(call.name, call.arguments));
      }
      await session.continueAfterTools();
      continue;
    }

    final last = session.messages.last;
    final calls = _extractToolCalls(last);
    if (calls.isEmpty) {
      return;
    }

    for (final call in calls) {
      session.addToolResultForCall(call, _runTool(call.name, call.arguments));
    }
    await session.continueAfterTools();
  }
}

List<ToolCallRequest> _extractToolCalls(ChatMessage? message) {
  if (message == null) {
    return const <ToolCallRequest>[];
  }

  final out = <ToolCallRequest>[];
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

    out.add(ToolCallRequest(id: id, name: name, arguments: args, raw: raw));
  }

  return out;
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
