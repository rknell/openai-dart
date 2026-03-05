import '../core/api_http_client.dart';
import '../types/model.dart';

class ModelsResource {
  ModelsResource(this._httpClient);

  final ApiHttpClient _httpClient;

  Future<ModelsListResponse> list() async {
    final response = await _httpClient.getJson('/v1/models');
    return ModelsListResponse.fromJson(response.json);
  }
}
