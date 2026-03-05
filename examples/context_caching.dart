import 'package:openai_dart/openai_dart.dart';

import '_utils.dart';

Future<void> main() async {
  final client = createClient();

  final repeatedPrefix =
      'You are a finance analyst. Analyze this report: '
      '${List<String>.filled(180, 'revenue margin growth outlook').join(' ')}';

  Future<void> run(String question) async {
    final response = await client.chat.completions.create(
      ChatCompletionCreateParams(
        model: 'deepseek-chat',
        messages: <ChatMessage>[
          const ChatMessage(
            role: 'system',
            content: 'Use concise bullet points.',
          ),
          ChatMessage(role: 'user', content: '$repeatedPrefix\n\n$question'),
        ],
        maxTokens: 128,
      ),
    );

    final usage = response.usage;
    print('---');
    print('question: $question');
    print('answer: ${response.firstMessage?.content}');
    print('prompt_cache_hit_tokens: ${usage?.promptCacheHitTokens}');
    print('prompt_cache_miss_tokens: ${usage?.promptCacheMissTokens}');
  }

  await run('What are the top 3 profitability risks?');
  await run('What are the top 3 profitability opportunities?');
}
