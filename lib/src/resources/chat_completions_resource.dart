import '../core/api_http_client.dart';
import '../types/chat_completion_chunk.dart';
import '../types/chat_completion_request.dart';
import '../types/chat_completion_response.dart';

class ChatCompletionsResource {
  ChatCompletionsResource(this._httpClient);

  final ApiHttpClient _httpClient;

  Future<ChatCompletionResponse> create(
    ChatCompletionCreateParams params,
  ) async {
    if (params.stream == true) {
      throw ArgumentError(
        'params.stream=true is not supported in create(). Use createStream() instead.',
      );
    }

    final response = await _httpClient.postJson(
      '/v1/chat/completions',
      params.toJson(),
    );

    return ChatCompletionResponse.fromJson(
      response.json,
      requestId: response.requestId,
    );
  }

  Stream<ChatCompletionChunk> createStream(ChatCompletionCreateParams params) {
    final body = <String, dynamic>{...params.toJson(), 'stream': true};
    return _httpClient
        .postSse('/v1/chat/completions', body)
        .map(ChatCompletionChunk.fromJson);
  }
}
