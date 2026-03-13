import 'package:http/http.dart' as http;

import 'core/api_http_client.dart';
import 'core/http_log_event.dart';
import 'resources/chat_completions_resource.dart';
import 'resources/chat_resource.dart';
import 'resources/models_resource.dart';
import 'session/chat_session.dart';
import 'types/tool_definition.dart';

class OpenAI {
  OpenAI({
    required String apiKey,
    String baseUrl = 'https://api.deepseek.com',
    Duration timeout = const Duration(seconds: 30),
    RetryConfig retryConfig = const RetryConfig(),
    HttpLogCallback? onHttpLog,
    http.Client? httpClient,
  }) : _httpClient = ApiHttpClient(
         apiKey: apiKey,
         baseUrl: baseUrl,
         timeout: timeout,
         retryConfig: retryConfig,
         onHttpLog: onHttpLog,
         httpClient: httpClient,
       ) {
    chat = ChatResource(completions: ChatCompletionsResource(_httpClient));
    models = ModelsResource(_httpClient);
    sessions = ChatSessions(this);
  }

  final ApiHttpClient _httpClient;

  late final ChatResource chat;
  late final ModelsResource models;
  late final ChatSessions sessions;
}

class ChatSessions {
  ChatSessions(this._client);

  final OpenAI _client;

  ChatSession create({
    required String model,
    String? systemMessage,
    List<ToolDefinition>? tools,
    int? maxTokens,
    double? temperature,
    Map<String, dynamic>? thinking,
    Map<String, dynamic>? responseFormat,
    List<String>? stop,
    Map<String, dynamic>? toolChoice,
  }) {
    final session = ChatSession(
      requester: _client.chat.completions.create,
      model: model,
      tools: tools,
      maxTokens: maxTokens,
      temperature: temperature,
      thinking: thinking,
      responseFormat: responseFormat,
      stop: stop,
      toolChoice: toolChoice,
    );

    if (systemMessage != null) {
      session.setSystemMessage(systemMessage);
    }

    return session;
  }
}
