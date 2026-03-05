// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolDefinition _$ToolDefinitionFromJson(Map<String, dynamic> json) =>
    ToolDefinition(
      type: json['type'] as String? ?? 'function',
      function: ToolFunction.fromJson(json['function'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ToolDefinitionToJson(ToolDefinition instance) =>
    <String, dynamic>{
      'type': instance.type,
      'function': instance.function.toJson(),
    };

ToolFunction _$ToolFunctionFromJson(Map<String, dynamic> json) => ToolFunction(
  name: json['name'] as String,
  description: json['description'] as String,
  parameters: ToolParameters.fromJson(
    json['parameters'] as Map<String, dynamic>,
  ),
  strict: json['strict'] as bool?,
);

Map<String, dynamic> _$ToolFunctionToJson(ToolFunction instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'parameters': instance.parameters.toJson(),
      'strict': ?instance.strict,
    };

ToolParameters _$ToolParametersFromJson(Map<String, dynamic> json) =>
    ToolParameters(
      type: json['type'] as String? ?? 'object',
      properties: json['properties'] as Map<String, dynamic>,
      requiredFields: (json['required'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      additionalProperties: json['additionalProperties'] as bool?,
    );

Map<String, dynamic> _$ToolParametersToJson(ToolParameters instance) =>
    <String, dynamic>{
      'type': instance.type,
      'properties': instance.properties,
      'required': ?instance.requiredFields,
      'additionalProperties': ?instance.additionalProperties,
    };
