import 'chat_message.dart';

class ChatCompletionResponse {
  ChatCompletionResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    this.usage,
    this.requestId,
  });

  factory ChatCompletionResponse.fromJson(
    Map<String, dynamic> json, {
    String? requestId,
  }) {
    return ChatCompletionResponse(
      id: json['id'] as String? ?? '',
      object: json['object'] as String? ?? 'chat.completion',
      created: json['created'] as int?,
      model: json['model'] as String? ?? '',
      choices: (json['choices'] as List<dynamic>? ?? const [])
          .map((e) => ChatCompletionChoice.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      usage: json['usage'] == null
          ? null
          : Usage.fromJson(json['usage'] as Map<String, dynamic>),
      requestId: requestId,
    );
  }

  final String id;
  final String object;
  final int? created;
  final String model;
  final List<ChatCompletionChoice> choices;
  final Usage? usage;
  final String? requestId;

  ChatMessage? get firstMessage =>
      choices.isEmpty ? null : choices.first.message;
}

class ChatCompletionChoice {
  const ChatCompletionChoice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  factory ChatCompletionChoice.fromJson(Map<String, dynamic> json) {
    return ChatCompletionChoice(
      index: json['index'] as int? ?? 0,
      message: ChatMessage.fromJson(
        (json['message'] as Map<String, dynamic>? ?? {}),
      ),
      finishReason: json['finish_reason'] as String?,
    );
  }

  final int index;
  final ChatMessage message;
  final String? finishReason;
}

class Usage {
  const Usage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    this.promptCacheHitTokens,
    this.promptCacheMissTokens,
  });

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      promptTokens: json['prompt_tokens'] as int? ?? 0,
      completionTokens: json['completion_tokens'] as int? ?? 0,
      totalTokens: json['total_tokens'] as int? ?? 0,
      promptCacheHitTokens: json['prompt_cache_hit_tokens'] as int?,
      promptCacheMissTokens: json['prompt_cache_miss_tokens'] as int?,
    );
  }

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final int? promptCacheHitTokens;
  final int? promptCacheMissTokens;
}
