import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatMessage {
  const ChatMessage({
    required this.role,
    this.content,
    this.name,
    @JsonKey(name: 'tool_call_id') this.toolCallId,
    @JsonKey(name: 'reasoning_content') this.reasoningContent,
    this.prefix,
    @JsonKey(name: 'tool_calls') this.toolCalls,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  final String role;
  final String? content;
  final String? name;
  final String? toolCallId;
  final String? reasoningContent;
  final bool? prefix;

  /// Raw OpenAI/DeepSeek-compatible tool call objects.
  final List<Map<String, dynamic>>? toolCalls;

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  ChatMessage copyWith({
    String? role,
    String? content,
    String? name,
    String? toolCallId,
    String? reasoningContent,
    bool? prefix,
    List<Map<String, dynamic>>? toolCalls,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      name: name ?? this.name,
      toolCallId: toolCallId ?? this.toolCallId,
      reasoningContent: reasoningContent ?? this.reasoningContent,
      prefix: prefix ?? this.prefix,
      toolCalls: toolCalls ?? this.toolCalls,
    );
  }
}
