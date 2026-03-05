import 'dart:io';

import 'package:openai_dart/openai_dart.dart';

import '_utils.dart';

Future<void> main() async {
  final client = createClient();

  final stream = client.chat.completions.createStream(
    const ChatCompletionCreateParams(
      model: 'deepseek-chat',
      messages: <ChatMessage>[
        ChatMessage(
          role: 'user',
          content: 'Write one short paragraph about Dart.',
        ),
      ],
      maxTokens: 128,
    ),
  );

  final buffer = StringBuffer();
  await for (final chunk in stream) {
    if (chunk.choices.isEmpty) {
      continue;
    }
    final delta = chunk.choices.first.delta.content;
    if (delta != null && delta.isNotEmpty) {
      buffer.write(delta);
      stdout.write(delta);
    }
  }

  stdout.writeln('\n\nFinal text:\n${buffer.toString()}');
}
