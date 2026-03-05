import 'package:openai_dart/openai_dart.dart';

import '_utils.dart';

Future<void> main() async {
  final client = createClient();

  final response = await client.chat.completions.create(
    const ChatCompletionCreateParams(
      model: 'deepseek-reasoner',
      messages: <ChatMessage>[
        ChatMessage(role: 'user', content: 'Which is larger: 9.11 or 9.8?'),
      ],
      maxTokens: 256,
    ),
  );

  final msg = response.firstMessage;
  print('reasoning_content:\n${msg?.reasoningContent ?? '(not returned)'}\n');
  print('final_content:\n${msg?.content ?? '(no content)'}');
}
