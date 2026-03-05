import 'package:json_annotation/json_annotation.dart';

part 'tool_definition.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ToolDefinition {
  const ToolDefinition({this.type = 'function', required this.function});

  ToolDefinition.function({
    required String name,
    required String description,
    required ToolParameters parameters,
    bool? strict,
  }) : this(
         type: 'function',
         function: ToolFunction(
           name: name,
           description: description,
           parameters: parameters,
           strict: strict,
         ),
       );

  factory ToolDefinition.fromJson(Map<String, dynamic> json) =>
      _$ToolDefinitionFromJson(json);

  final String type;
  final ToolFunction function;

  Map<String, dynamic> toJson() => _$ToolDefinitionToJson(this);

  String get name => function.name;
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ToolFunction {
  const ToolFunction({
    required this.name,
    required this.description,
    required this.parameters,
    this.strict,
  });

  factory ToolFunction.fromJson(Map<String, dynamic> json) =>
      _$ToolFunctionFromJson(json);

  final String name;
  final String description;
  final ToolParameters parameters;
  final bool? strict;

  Map<String, dynamic> toJson() => _$ToolFunctionToJson(this);
}

@JsonSerializable(includeIfNull: false)
class ToolParameters {
  const ToolParameters({
    this.type = 'object',
    required this.properties,
    @JsonKey(name: 'required') this.requiredFields,
    this.additionalProperties,
  });

  factory ToolParameters.fromJson(Map<String, dynamic> json) =>
      _$ToolParametersFromJson(json);

  final String type;

  /// The only intentionally flexible part of the schema.
  final Map<String, dynamic> properties;

  @JsonKey(name: 'required')
  final List<String>? requiredFields;

  final bool? additionalProperties;

  Map<String, dynamic> toJson() => _$ToolParametersToJson(this);
}
