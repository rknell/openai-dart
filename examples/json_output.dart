import 'dart:convert';

import 'package:openai_dart/openai_dart.dart';

import '_utils.dart';

Future<void> main() async {
  final client = createClient();

  final response = await client.chat.completions.create(
    const ChatCompletionCreateParams(
      model: 'deepseek-chat',
      messages: <ChatMessage>[
        ChatMessage(
          role: 'system',
          content:
              'Return valid json only with keys question and answer. Include the word json in your reasoning.',
        ),
        ChatMessage(
          role: 'user',
          content: 'Which river is longest? The Nile River.',
        ),
      ],
      responseFormat: <String, dynamic>{'type': 'json_object'},
      maxTokens: 128,
    ),
  );

  final raw = response.firstMessage?.content ?? '{}';
  final data = jsonDecode(raw) as Map<String, dynamic>;

  print('question: ${data['question']}');
  print('answer: ${data['answer']}');
}
