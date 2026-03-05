class ChatCompletionChunk {
  const ChatCompletionChunk({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
  });

  factory ChatCompletionChunk.fromJson(Map<String, dynamic> json) {
    return ChatCompletionChunk(
      id: json['id'] as String? ?? '',
      object: json['object'] as String? ?? 'chat.completion.chunk',
      created: json['created'] as int?,
      model: json['model'] as String? ?? '',
      choices: (json['choices'] as List<dynamic>? ?? const [])
          .map(
            (e) =>
                ChatCompletionChunkChoice.fromJson(e as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final String id;
  final String object;
  final int? created;
  final String model;
  final List<ChatCompletionChunkChoice> choices;
}

class ChatCompletionChunkChoice {
  const ChatCompletionChunkChoice({
    required this.index,
    required this.delta,
    this.finishReason,
  });

  factory ChatCompletionChunkChoice.fromJson(Map<String, dynamic> json) {
    return ChatCompletionChunkChoice(
      index: json['index'] as int? ?? 0,
      delta: ChatCompletionDelta.fromJson(
        (json['delta'] as Map<String, dynamic>? ?? {}),
      ),
      finishReason: json['finish_reason'] as String?,
    );
  }

  final int index;
  final ChatCompletionDelta delta;
  final String? finishReason;
}

class ChatCompletionDelta {
  const ChatCompletionDelta({
    this.role,
    this.content,
    this.reasoningContent,
    this.toolCalls,
  });

  factory ChatCompletionDelta.fromJson(Map<String, dynamic> json) {
    final rawToolCalls = json['tool_calls'] as List<dynamic>?;
    return ChatCompletionDelta(
      role: json['role'] as String?,
      content: json['content'] as String?,
      reasoningContent: json['reasoning_content'] as String?,
      toolCalls: rawToolCalls
          ?.map((e) => e as Map<String, dynamic>)
          .toList(growable: false),
    );
  }

  final String? role;
  final String? content;
  final String? reasoningContent;
  final List<Map<String, dynamic>>? toolCalls;
}
