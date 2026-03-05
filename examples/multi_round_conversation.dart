import 'package:openai_dart/openai_dart.dart';

import '_utils.dart';

Future<void> main() async {
  final client = createClient();

  final messages = <ChatMessage>[
    const ChatMessage(role: 'system', content: 'You answer briefly.'),
    const ChatMessage(role: 'user', content: 'What is the capital of China?'),
  ];

  final round1 = await client.chat.completions.create(
    ChatCompletionCreateParams(model: 'deepseek-chat', messages: messages),
  );
  final assistant1 = round1.firstMessage!;
  messages.add(assistant1);
  print('Round 1: ${assistant1.content}');

  messages.add(
    const ChatMessage(
      role: 'user',
      content: 'What is the capital of the United States?',
    ),
  );

  final round2 = await client.chat.completions.create(
    ChatCompletionCreateParams(model: 'deepseek-chat', messages: messages),
  );
  final assistant2 = round2.firstMessage!;
  messages.add(assistant2);

  print('Round 2: ${assistant2.content}');
}
