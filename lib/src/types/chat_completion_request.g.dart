// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_completion_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatCompletionCreateParams _$ChatCompletionCreateParamsFromJson(
  Map<String, dynamic> json,
) => ChatCompletionCreateParams(
  model: json['model'] as String,
  messages: (json['messages'] as List<dynamic>)
      .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
      .toList(),
  maxTokens: (json['max_tokens'] as num?)?.toInt(),
  temperature: (json['temperature'] as num?)?.toDouble(),
  stream: json['stream'] as bool?,
  tools: (json['tools'] as List<dynamic>?)
      ?.map((e) => ToolDefinition.fromJson(e as Map<String, dynamic>))
      .toList(),
  toolChoice: json['tool_choice'] as Map<String, dynamic>?,
  stop: (json['stop'] as List<dynamic>?)?.map((e) => e as String).toList(),
  responseFormat: json['response_format'] as Map<String, dynamic>?,
  thinking: json['thinking'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ChatCompletionCreateParamsToJson(
  ChatCompletionCreateParams instance,
) => <String, dynamic>{
  'model': instance.model,
  'messages': instance.messages.map((e) => e.toJson()).toList(),
  'max_tokens': ?instance.maxTokens,
  'temperature': ?instance.temperature,
  'stream': ?instance.stream,
  'tools': ?instance.tools?.map((e) => e.toJson()).toList(),
  'tool_choice': ?instance.toolChoice,
  'stop': ?instance.stop,
  'response_format': ?instance.responseFormat,
  'thinking': ?instance.thinking,
};
