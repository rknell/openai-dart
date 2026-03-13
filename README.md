# openai_dart

OpenAI-compatible Dart client focused on DeepSeek chat completions.

This library is designed to be easy to use (similar style to `openai-node`) while covering DeepSeek-specific details such as tool-calling loops, thinking mode, JSON output, context caching fields, and beta features.

## Requirements

- Dart SDK `>=3.11.0 <4.0.0`

## Installation

This package is currently repository-first (not yet published to pub.dev).

### Local path dependency

```yaml
dependencies:
  openai_dart:
    path: ../openai-dart
```

### Git dependency

```yaml
dependencies:
  openai_dart:
    git:
      url: https://github.com/<your-org>/openai-dart.git
```

Then run:

```bash
dart pub get
```

## Quick Start

```dart
import 'package:openai_dart/openai_dart.dart';

Future<void> main() async {
  final client = OpenAI(
    apiKey: 'YOUR_DEEPSEEK_API_KEY',
    // default baseUrl is https://api.deepseek.com
  );

  final response = await client.chat.completions.create(
    const ChatCompletionCreateParams(
      model: 'deepseek-chat',
      messages: [
        ChatMessage(role: 'user', content: 'Say hello in one sentence.'),
      ],
    ),
  );

  print(response.firstMessage?.content);
}
```

## Client Construction

```dart
final client = OpenAI(
  apiKey: 'YOUR_KEY',
  baseUrl: 'https://api.deepseek.com', // optional
  timeout: const Duration(seconds: 30), // optional
  retryConfig: const RetryConfig( // optional; retries enabled by default
    enabled: true,
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 250),
  ),
);
```

### Debug logging

Enable HTTP request/response logging by passing an `onHttpLog` callback. Logging is silent by default (`onHttpLog: null`).

```dart
final client = OpenAI(
  apiKey: apiKey,
  onHttpLog: (event) {
    print('${event.method} ${event.uri} -> ${event.statusCode} (${event.duration?.inMilliseconds}ms)');
  },
);
```

`HttpLogEvent` provides `method`, `uri`, `statusCode`, `duration`, `requestHeaders` (sanitized; `Authorization` is redacted), `requestBody`, `responseHeaders`, and `responseBody`. Forward to your own logger:

```dart
final _log = Logger('my_app');
final client = OpenAI(
  apiKey: apiKey,
  onHttpLog: (e) => _log.fine('HTTP ${e.method} ${e.uri} ${e.statusCode}'),
);
```

Libraries that consume this package can pass the callback through to let end users control debug output.

### Beta features

Use beta base URL for beta-only APIs:

```dart
final betaClient = OpenAI(
  apiKey: 'YOUR_KEY',
  baseUrl: 'https://api.deepseek.com/beta',
);
```

## Main APIs

- `client.models.list()`
- `client.chat.completions.create(params)`
- `client.chat.completions.createStream(params)`
- `client.sessions.create(...)` -> convenience session/context manager

## Streaming

```dart
final stream = client.chat.completions.createStream(
  const ChatCompletionCreateParams(
    model: 'deepseek-chat',
    messages: [ChatMessage(role: 'user', content: 'Write a short paragraph.')],
  ),
);

await for (final chunk in stream) {
  if (chunk.choices.isEmpty) continue;
  final text = chunk.choices.first.delta.content;
  if (text != null) {
    stdout.write(text);
  }
}
```

## Tool Calling

Tool schemas are strongly typed except `properties`, which remains `Map<String, dynamic>` for flexibility.

```dart
final tools = <ToolDefinition>[
  const ToolDefinition.function(
    name: 'get_weather',
    description: 'Get weather by location',
    parameters: ToolParameters(
      properties: {
        'location': {'type': 'string'},
      },
      requiredFields: ['location'],
    ),
  ),
];
```

### Critical rule: `tool_call_id`

When returning tool results, `tool_call_id` must match the exact ID returned by the assistant tool call.

The `ChatSession` helper provides ID-safe methods:

- `addToolResult(toolCallId: ..., content: ...)`
- `addToolResultForCall(call, content)`

These throw if IDs are unknown/resolved already.

## Session/Context Convenience API

`ChatSession` helps with context management and multi-turn flows.

```dart
final session = client.sessions.create(model: 'deepseek-chat');
session.setSystemMessage('You are concise.');
session.addTool(weatherTool);

await session.sendMessage('Weather in Tokyo?');

// extract/edit/replace context
final snapshot = session.contextSnapshot();
session.replaceContext(snapshot);
```

Convenience capabilities:

- set/replace system message
- add/remove tools
- send message
- continue after tools
- run tool loop until done
- inspect/replace full context
- clear historical reasoning content

## JSON Output

```dart
final response = await client.chat.completions.create(
  const ChatCompletionCreateParams(
    model: 'deepseek-chat',
    messages: [
      ChatMessage(role: 'system', content: 'Return valid json only with keys question and answer.'),
      ChatMessage(role: 'user', content: 'Which river is longest? The Nile River.'),
    ],
    responseFormat: {'type': 'json_object'},
  ),
);

final raw = response.firstMessage?.content ?? '{}';
final parsed = jsonDecode(raw) as Map<String, dynamic>;
```

## Thinking Mode

```dart
final response = await client.chat.completions.create(
  const ChatCompletionCreateParams(
    model: 'deepseek-reasoner',
    messages: [
      ChatMessage(role: 'user', content: 'Which is larger: 9.11 or 9.8?'),
    ],
  ),
);

print(response.firstMessage?.reasoningContent);
print(response.firstMessage?.content);
```

## Error Handling

Typed exceptions are provided:

- `BadRequestError` (400)
- `AuthenticationError` (401)
- `PermissionDeniedError` (403)
- `NotFoundError` (404)
- `UnprocessableEntityError` (422)
- `RateLimitError` (429)
- `InternalServerError` (>=500)
- `APIConnectionError` (transport/timeout)

Example:

```dart
try {
  await client.models.list();
} on AuthenticationError catch (e) {
  print('Auth error: ${e.message}');
}
```

## Examples

See [examples/README.md](examples/README.md) for a full runnable walkthrough:

- simple chat
- streaming
- JSON output
- thinking mode
- multi-round conversation
- tool calling (weather)
- context caching
- chat prefix completion (beta)
- strict mode (beta)
- session API convenience flow

## Testing

### Unit tests

```bash
dart test test/unit
```

### Integration tests

Set key in env:

```bash
export DEEPSEEK_API_KEY=your_key
```

Or place it in `.env` (integration tests support `.env` fallback).

Then run:

```bash
dart test test/integration/deepseek_integration_test.dart
```

## Pre-commit Secret Scanning

This repo includes a pre-commit secret scanner using `gitleaks`.

### One-time setup

1. Install `pre-commit` (for example: `pipx install pre-commit`).
2. Install hooks in this repo:

```bash
pre-commit install
```

### Usage

Hooks run automatically on `git commit`.

To scan all files manually:

```bash
pre-commit run --all-files
```

Config files:

- `.pre-commit-config.yaml`
- `.gitleaks.toml`

## Docs

- API-focused implementation doc: [docs/API_DOCS.md](docs/API_DOCS.md)
- Implementation/progress tracking: [docs/IMPLEMENTATION_PROGRESS.md](docs/IMPLEMENTATION_PROGRESS.md)

## Security

- See [SECURITY.md](SECURITY.md) for vulnerability reporting guidance.
- Do not commit real credentials.
- `.env` files are ignored; use `.env.example` as a template.

## License

This project is licensed under the [MIT License](LICENSE).
