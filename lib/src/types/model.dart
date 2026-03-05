class ModelsListResponse {
  const ModelsListResponse({required this.data});

  factory ModelsListResponse.fromJson(Map<String, dynamic> json) {
    return ModelsListResponse(
      data: (json['data'] as List<dynamic>? ?? const [])
          .map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final List<ModelInfo> data;
}

class ModelInfo {
  const ModelInfo({required this.id, required this.object});

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'] as String? ?? '',
      object: json['object'] as String? ?? 'model',
    );
  }

  final String id;
  final String object;
}
