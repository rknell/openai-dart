// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  role: json['role'] as String,
  content: json['content'] as String?,
  name: json['name'] as String?,
  toolCallId: json['tool_call_id'] as String?,
  reasoningContent: json['reasoning_content'] as String?,
  prefix: json['prefix'] as bool?,
  toolCalls: (json['tool_calls'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'role': instance.role,
      'content': ?instance.content,
      'name': ?instance.name,
      'tool_call_id': ?instance.toolCallId,
      'reasoning_content': ?instance.reasoningContent,
      'prefix': ?instance.prefix,
      'tool_calls': ?instance.toolCalls,
    };
