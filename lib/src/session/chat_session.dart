import 'dart:convert';

import '../types/chat_completion_request.dart';
import '../types/chat_completion_response.dart';
import '../types/chat_message.dart';
import '../types/tool_definition.dart';

typedef CompletionRequester =
    Future<ChatCompletionResponse> Function(ChatCompletionCreateParams params);

typedef ToolExecutor = Future<String> Function(ToolCallRequest toolCall);

class ToolCallRequest {
  const ToolCallRequest({
    required this.id,
    required this.name,
    required this.arguments,
    required this.raw,
  });

  final String id;
  final String name;
  final Map<String, dynamic> arguments;
  final Map<String, dynamic> raw;
}

class ToolCallStateError extends StateError {
  ToolCallStateError(super.message);
}

class ChatSession {
  ChatSession({
    required CompletionRequester requester,
    required this.model,
    String? systemMessage,
    List<ToolDefinition>? tools,
    this.maxTokens,
    this.temperature,
    this.thinking,
    this.responseFormat,
    this.stop,
    this.toolChoice,
  }) : _requester = requester,
       _tools = List<ToolDefinition>.from(tools ?? const <ToolDefinition>[]);

  final CompletionRequester _requester;

  final String model;
  final int? maxTokens;
  final double? temperature;
  final Map<String, dynamic>? thinking;
  final Map<String, dynamic>? responseFormat;
  final List<String>? stop;
  final Map<String, dynamic>? toolChoice;

  final List<ChatMessage> _messages = <ChatMessage>[];
  final List<ToolDefinition> _tools;
  final Set<String> _pendingToolCallIds = <String>{};

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  List<ToolDefinition> get tools => List<ToolDefinition>.unmodifiable(_tools);
  Set<String> get pendingToolCallIds =>
      Set<String>.unmodifiable(_pendingToolCallIds);

  void setSystemMessage(String content) {
    final system = ChatMessage(role: 'system', content: content);
    if (_messages.isNotEmpty && _messages.first.role == 'system') {
      _messages[0] = system;
    } else {
      _messages.insert(0, system);
    }
    _recomputePendingToolCallIds();
  }

  void addTool(ToolDefinition tool) {
    _tools.add(tool);
  }

  bool removeToolByName(String name) {
    final before = _tools.length;
    _tools.removeWhere((tool) => tool.name == name);
    return _tools.length != before;
  }

  List<ChatMessage> contextSnapshot() => _messages
      .map((m) => ChatMessage.fromJson(m.toJson()))
      .toList(growable: false);

  void replaceContext(List<ChatMessage> context) {
    _messages
      ..clear()
      ..addAll(context.map((m) => ChatMessage.fromJson(m.toJson())));
    _recomputePendingToolCallIds();
  }

  void updateMessageAt(int index, ChatMessage message) {
    _messages[index] = message;
    _recomputePendingToolCallIds();
  }

  void clearHistoricalReasoningContent() {
    for (var i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      if (msg.reasoningContent != null) {
        _messages[i] = ChatMessage(
          role: msg.role,
          content: msg.content,
          name: msg.name,
          toolCallId: msg.toolCallId,
          reasoningContent: null,
          prefix: msg.prefix,
          toolCalls: msg.toolCalls,
        );
      }
    }
  }

  Future<ChatMessage> sendMessage(String content) async {
    _ensureNoPendingToolCalls();
    _messages.add(ChatMessage(role: 'user', content: content));
    return _requestAndAppendAssistant();
  }

  Future<ChatMessage> continueAfterTools() async {
    _ensureNoPendingToolCalls();
    return _requestAndAppendAssistant();
  }

  void addToolResult({
    required String toolCallId,
    required String content,
    String? name,
  }) {
    if (!_pendingToolCallIds.contains(toolCallId)) {
      throw ToolCallStateError(
        'Unknown or already-resolved tool_call_id: $toolCallId',
      );
    }

    _messages.add(
      ChatMessage(
        role: 'tool',
        toolCallId: toolCallId,
        content: content,
        name: name,
      ),
    );

    _pendingToolCallIds.remove(toolCallId);
  }

  void addToolResultForCall(
    ToolCallRequest call,
    String content, {
    String? name,
  }) {
    addToolResult(
      toolCallId: call.id,
      content: content,
      name: name ?? call.name,
    );
  }

  Future<ChatMessage> runToolsUntilDone(ToolExecutor executor) async {
    while (true) {
      final assistant = await _requestAndAppendAssistant();
      final toolCalls = _extractToolCalls(assistant);
      if (toolCalls.isEmpty) {
        return assistant;
      }

      for (final call in toolCalls) {
        final result = await executor(call);
        addToolResultForCall(call, result);
      }
    }
  }

  Future<ChatMessage> _requestAndAppendAssistant() async {
    final params = ChatCompletionCreateParams(
      model: model,
      messages: _messages,
      maxTokens: maxTokens,
      temperature: temperature,
      tools: _tools.isEmpty ? null : _tools,
      thinking: thinking,
      responseFormat: responseFormat,
      stop: stop,
      toolChoice: toolChoice,
    );

    final response = await _requester(params);
    final assistant = response.firstMessage;
    if (assistant == null) {
      throw StateError('Response contains no assistant message.');
    }

    _messages.add(assistant);
    _recomputePendingToolCallIds();
    return assistant;
  }

  void _ensureNoPendingToolCalls() {
    if (_pendingToolCallIds.isNotEmpty) {
      throw ToolCallStateError(
        'Cannot continue while tool calls are unresolved: '
        '${_pendingToolCallIds.join(', ')}',
      );
    }
  }

  List<ToolCallRequest> _extractToolCalls(ChatMessage assistant) {
    final raw = assistant.toolCalls ?? const <Map<String, dynamic>>[];
    final output = <ToolCallRequest>[];

    for (final call in raw) {
      final id = call['id'] as String?;
      final function = (call['function'] as Map?)?.cast<String, dynamic>();
      final name = function?['name'] as String?;
      final argsRaw = function?['arguments'] as String? ?? '{}';
      if (id == null || name == null) {
        continue;
      }

      Map<String, dynamic> args;
      try {
        final decoded = jsonDecode(argsRaw);
        args = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{'value': decoded};
      } catch (_) {
        args = <String, dynamic>{};
      }

      output.add(
        ToolCallRequest(id: id, name: name, arguments: args, raw: call),
      );
    }

    return output;
  }

  void _recomputePendingToolCallIds() {
    _pendingToolCallIds.clear();

    for (final message in _messages) {
      if (message.role == 'assistant') {
        final calls = message.toolCalls;
        if (calls != null) {
          for (final call in calls) {
            final id = call['id'] as String?;
            if (id != null) {
              _pendingToolCallIds.add(id);
            }
          }
        }
      } else if (message.role == 'tool' && message.toolCallId != null) {
        _pendingToolCallIds.remove(message.toolCallId);
      }
    }
  }
}
