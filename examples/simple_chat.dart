import 'package:openai_dart/openai_dart.dart';

import '_utils.dart';

Future<void> main() async {
  final client = createClient();

  final response = await client.chat.completions.create(
    const ChatCompletionCreateParams(
      model: 'deepseek-chat',
      messages: <ChatMessage>[
        ChatMessage(role: 'system', content: 'You are concise.'),
        ChatMessage(role: 'user', content: 'Say hello in one short sentence.'),
      ],
    ),
  );

  print(response.firstMessage?.content ?? '(no content)');
}
