import 'package:openai_dart/openai_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ChatSession', () {
    test('setSystemMessage inserts and replaces first system message', () {
      final session = _buildSession(<ChatCompletionResponse>[]);
      session.setSystemMessage('You are helpful.');
      expect(session.messages.first.role, 'system');
      expect(session.messages.first.content, 'You are helpful.');

      session.setSystemMessage('You are concise.');
      expect(session.messages.length, 1);
      expect(session.messages.first.content, 'You are concise.');
    });

    test('addToolResult enforces known tool_call_id', () async {
      final responses = <ChatCompletionResponse>[
        _responseWithAssistant(
          ChatMessage(
            role: 'assistant',
            content: null,
            toolCalls: <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'call_1',
                'type': 'function',
                'function': <String, dynamic>{
                  'name': 'get_weather',
                  'arguments': '{"location":"Boston"}',
                },
              },
            ],
          ),
        ),
      ];

      final session = _buildSession(responses);
      session.replaceContext(<ChatMessage>[
        const ChatMessage(role: 'user', content: 'weather?'),
      ]);

      final assistant = await session.continueAfterTools();
      expect(assistant.toolCalls?.length, 1);
      expect(session.pendingToolCallIds, contains('call_1'));

      expect(
        () => session.addToolResult(toolCallId: 'wrong', content: 'sunny'),
        throwsA(isA<ToolCallStateError>()),
      );

      session.addToolResult(toolCallId: 'call_1', content: 'sunny');
      expect(session.pendingToolCallIds, isEmpty);
    });

    test('sendMessage fails while pending tool calls unresolved', () async {
      final responses = <ChatCompletionResponse>[
        _responseWithAssistant(
          ChatMessage(
            role: 'assistant',
            toolCalls: <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'call_1',
                'type': 'function',
                'function': <String, dynamic>{
                  'name': 'get_weather',
                  'arguments': '{}',
                },
              },
            ],
          ),
        ),
      ];
      final session = _buildSession(responses);
      session.replaceContext(<ChatMessage>[
        const ChatMessage(role: 'user', content: 'weather?'),
      ]);

      await session.continueAfterTools();
      expect(
        () => session.sendMessage('new turn'),
        throwsA(isA<ToolCallStateError>()),
      );
    });

    test(
      'runToolsUntilDone resolves loop and appends tool result with id',
      () async {
        final responses = <ChatCompletionResponse>[
          _responseWithAssistant(
            ChatMessage(
              role: 'assistant',
              reasoningContent: 'Need weather API call',
              toolCalls: <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'call_9',
                  'type': 'function',
                  'function': <String, dynamic>{
                    'name': 'get_weather',
                    'arguments': '{"location":"Tokyo"}',
                  },
                },
              ],
            ),
          ),
          _responseWithAssistant(
            const ChatMessage(
              role: 'assistant',
              content: 'It is 24C in Tokyo.',
            ),
          ),
        ];

        final session = _buildSession(responses);
        session.replaceContext(<ChatMessage>[
          const ChatMessage(role: 'user', content: 'weather?'),
        ]);

        final finalMessage = await session.runToolsUntilDone((call) async {
          expect(call.id, 'call_9');
          expect(call.name, 'get_weather');
          expect(call.arguments['location'], 'Tokyo');
          return '24C';
        });

        expect(finalMessage.content, contains('24C'));
        expect(session.pendingToolCallIds, isEmpty);
        expect(
          session.messages.any(
            (m) => m.role == 'tool' && m.toolCallId == 'call_9',
          ),
          isTrue,
        );
      },
    );

    test('contextSnapshot and replaceContext roundtrip', () {
      final session = _buildSession(<ChatCompletionResponse>[]);
      session.replaceContext(<ChatMessage>[
        const ChatMessage(role: 'system', content: 'S'),
        const ChatMessage(role: 'user', content: 'U'),
      ]);

      final snapshot = session.contextSnapshot();
      final mutated = <ChatMessage>[
        ...snapshot,
        const ChatMessage(role: 'assistant', content: 'A'),
      ];

      session.replaceContext(mutated);
      expect(session.messages.length, 3);
      expect(session.messages.last.content, 'A');
    });

    test(
      'clearHistoricalReasoningContent removes reasoning content fields',
      () {
        final session = _buildSession(<ChatCompletionResponse>[]);
        session.replaceContext(<ChatMessage>[
          const ChatMessage(
            role: 'assistant',
            content: 'X',
            reasoningContent: 'R1',
          ),
          const ChatMessage(
            role: 'assistant',
            content: 'Y',
            reasoningContent: 'R2',
          ),
        ]);

        session.clearHistoricalReasoningContent();

        expect(
          session.messages.every((m) => m.reasoningContent == null),
          isTrue,
        );
      },
    );
  });
}

ChatSession _buildSession(List<ChatCompletionResponse> responses) {
  var index = 0;
  return ChatSession(
    requester: (_) async {
      if (index >= responses.length) {
        throw StateError('No fake response remaining');
      }
      return responses[index++];
    },
    model: 'deepseek-chat',
  );
}

ChatCompletionResponse _responseWithAssistant(ChatMessage message) {
  return ChatCompletionResponse(
    id: 'cmpl_test',
    object: 'chat.completion',
    created: 0,
    model: 'deepseek-chat',
    choices: <ChatCompletionChoice>[
      ChatCompletionChoice(index: 0, message: message),
    ],
  );
}
