import 'package:openai_dart/openai_dart.dart';

import '_utils.dart';

Future<void> main() async {
  final client = createClient(beta: true);

  final response = await client.chat.completions.create(
    const ChatCompletionCreateParams(
      model: 'deepseek-chat',
      messages: <ChatMessage>[
        ChatMessage(role: 'user', content: 'Write quick sort code in Python.'),
        ChatMessage(role: 'assistant', content: '```python\n', prefix: true),
      ],
      stop: <String>['```'],
      maxTokens: 256,
    ),
  );

  print('```python');
  print(response.firstMessage?.content ?? '');
  print('```');
}
