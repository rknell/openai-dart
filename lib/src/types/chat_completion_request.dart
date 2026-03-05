import 'package:json_annotation/json_annotation.dart';

import 'chat_message.dart';
import 'tool_definition.dart';

part 'chat_completion_request.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatCompletionCreateParams {
  const ChatCompletionCreateParams({
    required this.model,
    required this.messages,
    @JsonKey(name: 'max_tokens') this.maxTokens,
    this.temperature,
    this.stream,
    this.tools,
    @JsonKey(name: 'tool_choice') this.toolChoice,
    this.stop,
    @JsonKey(name: 'response_format') this.responseFormat,
    this.thinking,
  });

  factory ChatCompletionCreateParams.fromJson(Map<String, dynamic> json) =>
      _$ChatCompletionCreateParamsFromJson(json);

  final String model;
  final List<ChatMessage> messages;
  final int? maxTokens;
  final double? temperature;
  final bool? stream;
  final List<ToolDefinition>? tools;
  final Map<String, dynamic>? toolChoice;
  final List<String>? stop;
  final Map<String, dynamic>? responseFormat;
  final Map<String, dynamic>? thinking;

  Map<String, dynamic> toJson() => _$ChatCompletionCreateParamsToJson(this);
}
