# DeepSeek Dart Client - Implementation Plan and Progress

Last updated: 2026-03-05

## Goals

1. Prioritize robust tool-call handling, especially correct propagation of `tool_call_id`.
2. Provide strong context/session ergonomics:
   * extract/edit context
   * convenience methods (`addTool`, `setSystemMessage`, `sendMessage`, etc.)
3. Full unit + integration test coverage.
4. Credentials are passed directly to client constructors (no hidden global singleton state).
5. Use `json_serializable` for request/response model classes.
6. Keep developer ergonomics close to `openai-node` style.

## Scope

Initial API scope:

* `GET /v1/models`
* `POST /v1/chat/completions`
* Streaming chat completions (SSE)
* Tool calls
* Thinking mode support
* JSON Output support
* Context caching usage fields
* Beta features:
  * Chat Prefix Completion
  * Strict tool mode

## Design Direction (aligned to openai-node style)

### Client shape

* Top-level client class: `OpenAI` (or `DeepSeekClient`, with alias export decision pending).
* Resource hierarchy:
  * `client.models.list()`
  * `client.chat.completions.create(...)`
* Optional convenience layer on top:
  * `client.sessions.create(...)` -> returns mutable `ChatSession`.

### Construction

```dart
final client = OpenAI(
  apiKey: '...',
  baseUrl: 'https://api.deepseek.com', // or /beta
  timeout: const Duration(seconds: 30),
);
```

No implicit env-var resolution in core client constructor.

### Error model

Typed exceptions mirroring node-style categories:

* `BadRequestError` (400)
* `AuthenticationError` (401)
* `PermissionDeniedError` (403)
* `NotFoundError` (404)
* `UnprocessableEntityError` (422)
* `RateLimitError` (429)
* `InternalServerError` (>=500)
* `ApiConnectionError` (transport/timeout)

## Tool Call First-Class Design

### Non-negotiable tool-call invariants

1. Assistant tool-call message must be preserved as returned.
2. Each tool result message must include the exact `tool_call_id` from the assistant tool call.
3. Tool results must be appended after the corresponding assistant tool-call message, before the follow-up model call.
4. Multi-tool responses must preserve call order.

### Library helpers for safe IDs

Provide utility APIs that make wrong ID handling difficult:

* `ToolCall` model includes required `id`.
* `ChatSession.addToolResult({required String toolCallId, required String content, String? name})`.
* `ChatSession.addToolResultForCall(ToolCall call, String content)` convenience helper.
* Validation: throw clear exception when `toolCallId` is unknown in current session state.

### Thinking mode tool-call handling

Within a single user turn, include assistant `reasoning_content` while continuing sub-turn tool cycles.
Before a new user turn, provide `clearHistoricalReasoningContent()` helper.

## Context/Session Management

## Session API (planned)

```dart
final session = client.sessions.create(
  model: 'deepseek-chat',
  systemMessage: 'You are helpful.',
);

session.addTool(weatherTool);
session.setSystemMessage('You are concise.');
session.sendMessage('What is the weather in Boston?');
final context = session.contextSnapshot();
session.replaceContext(contextEdited);
```

### Required capabilities

* Get immutable snapshot of context.
* Replace entire context.
* Edit messages by index/id.
* Add/remove tools.
* Set/replace system message.
* Send user message and automatically append assistant response.
* Tool loop helper:
  * detect tool calls
  * run user-provided tool executor
  * append tool results with IDs
  * continue until final assistant content.

## Data Modeling (`json_serializable`)

All request/response DTOs under `lib/src/models/`:

* Chat request/response models
* Message models (user/system/assistant/tool)
* Tool schema models
* Streaming delta models
* Usage/caching models
* Error payload models

Generation setup:

* `json_annotation` in runtime deps
* `json_serializable` + `build_runner` in dev deps
* `part '*.g.dart';` for each DTO

## Testing Strategy

### Unit tests (must-have)

* DTO serialization/deserialization.
* Error mapping by status code.
* SSE parser (chunk fragmentation + done handling).
* Session context operations:
  * set/get/replace context
  * message ordering guarantees
  * tool call ID validation
* Tool loop state machine:
  * single tool call
  * multiple tool calls
  * missing/invalid tool IDs
* Thinking-mode reasoning propagation and clearing behavior.

### Integration tests (must-have, env guarded)

* Runs only when `DEEPSEEK_API_KEY` is set; otherwise skipped.
* Smoke:
  * list models
  * simple chat completion
  * streaming completion
  * JSON output completion
  * tool-call roundtrip (mock tool executor in test process)

## Phased Execution Plan

### Phase 0 - Package bootstrap

* Create Dart package structure.
* Add linting, formatting, test config.
* Add `json_serializable` generation pipeline.

Status: `completed`

### Phase 1 - Core HTTP + errors + base models

* Implement HTTP transport wrapper.
* Implement typed errors.
* Implement base chat/models APIs.

Status: `completed`

### Phase 2 - Session/context manager

* Implement `ChatSession`.
* Add context extraction/edit/replace.
* Add convenience methods (`addTool`, `setSystemMessage`, `sendMessage`).

Status: `completed`

### Phase 3 - Tool-call engine

* Implement strict ID-safe tool result APIs.
* Implement multi-tool loop helper.
* Implement thinking-mode sub-turn handling.

Status: `completed`

### Phase 4 - Streaming + beta features

* SSE streaming support.
* Prefix completion support.
* Strict-mode support (beta URL workflows).

Status: `in_progress`

### Phase 5 - Tests and hardening

* Complete unit coverage for all above modules.
* Add env-guarded integration suite.
* Add usage examples in docs.

Status: `in_progress`

## Progress Log

### 2026-03-05

* Created initial plan and progress tracking document.
* Documented architecture direction and phased milestones.
* Locked key invariants for tool-call ID handling.
* Confirmed decisions:
  * Public naming: `OpenAI`
  * Session abstraction: ship in v1
  * Retries: enabled by default
  * Dart target: `>=3.11.0`
* Implemented initial package:
  * core client/resources
  * typed errors
  * chat completion + streaming
  * session/context management convenience APIs
  * tool-call ID-safe workflow helpers
  * unit tests + env-guarded integration tests
* Added integration coverage for:
  * multi-round conversation flow
  * weather tool-call loop with at least 3 tool calls in one conversation
  * correct `tool_call_id` chaining in API sub-requests
* Added `examples/` suite covering major features from API docs:
  * simple chat, streaming, JSON output, thinking mode
  * multi-round conversation, tool calling, context caching
  * chat prefix completion (beta), strict mode (beta)

## Open Decisions / Questions

1. Beta feature ergonomics:
   * Add explicit `client.beta` resource tree vs single-client `baseUrl` switching?
2. Strict-mode schema helper:
   * Add optional local schema validator utility for faster feedback before API call?
