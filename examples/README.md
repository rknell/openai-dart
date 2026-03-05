# Examples

These examples demonstrate each major feature in `docs/API_DOCS.md`.

## Prerequisites

1. Add your key to `.env`:

```bash
DEEPSEEK_API_KEY=your_key_here
```

2. Install dependencies:

```bash
dart pub get
```

## Run order

1. Simple chat:

```bash
dart run examples/simple_chat.dart
```

2. Streaming:

```bash
dart run examples/streaming_chat.dart
```

3. JSON output:

```bash
dart run examples/json_output.dart
```

4. Thinking mode:

```bash
dart run examples/thinking_mode.dart
```

5. Multi-round conversation:

```bash
dart run examples/multi_round_conversation.dart
```

6. Tool calling (weather, with correct `tool_call_id` chaining):

```bash
dart run examples/tool_calling_weather.dart
```

7. Context caching visibility (`usage.prompt_cache_hit_tokens`):

```bash
dart run examples/context_caching.dart
```

8. Chat prefix completion (beta):

```bash
dart run examples/chat_prefix_completion_beta.dart
```

9. Strict mode tool schema (beta):

```bash
dart run examples/strict_mode_beta.dart
```

10. Session API convenience flow (context + tools + multi-turn):

```bash
dart run examples/session_api.dart
```
