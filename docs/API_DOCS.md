# DeepSeek API Documentation (Converted to Markdown)

Source: [https://api-docs.deepseek.com/](https://api-docs.deepseek.com/)

---

## Overview

DeepSeek provides an API compatible with the OpenAI API format. This allows developers to use the same client libraries and workflows while targeting DeepSeek models.

Base URL:

```
https://api.deepseek.com
```

Authentication uses an API key passed in the Authorization header.

```
Authorization: Bearer YOUR_API_KEY
```

---

## Models

Available models include:

* `deepseek-chat` – general chat model
* `deepseek-reasoner` – reasoning‑optimized model

Example request to list models:

```
GET /v1/models
```

Example response:

```json
{
  "data": [
    {
      "id": "deepseek-chat",
      "object": "model"
    },
    {
      "id": "deepseek-reasoner",
      "object": "model"
    }
  ]
}
```

---

## Chat Completions

Endpoint:

```
POST /v1/chat/completions
```

Example request:

```json
{
  "model": "deepseek-chat",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello"}
  ]
}
```

Example response:

```json
{
  "id": "chatcmpl-xxx",
  "object": "chat.completion",
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "Hello! How can I help you today?"
      }
    }
  ]
}
```

---

## Streaming

Streaming responses are supported via Server‑Sent Events.

Request example:

```json
{
  "model": "deepseek-chat",
  "stream": true,
  "messages": [
    {"role": "user", "content": "Tell me a story"}
  ]
}
```

The response will be delivered as a stream of incremental tokens.

---

## Function / Tool Calling

DeepSeek supports OpenAI-style tool calling.

Use the `tools` array in `/chat/completions`, then handle returned `tool_calls` by executing tools in your application and sending tool results back as `role: "tool"` messages.

For full implementation details (standard flow, thinking mode behavior, and `strict` mode schema rules), see:

* [Tool Calls (Guide)](#tool-calls-guide)
* [Thinking Mode](#thinking-mode)

---

## Parameters

Common request parameters:

| Parameter       | Description |
| --------------- | ----------- |
| `model`         | Model name (`deepseek-chat`, `deepseek-reasoner`) |
| `messages`      | Chat message array |
| `max_tokens`    | Maximum generated tokens for this response |
| `stream`        | Enable SSE streaming |
| `temperature`   | Sampling randomness (not effective in thinking mode) |
| `tools`         | Tool/function definitions |
| `response_format` | Structured output mode (for JSON Output) |
| `stop`          | Stop sequences |
| `thinking`      | Enable thinking mode when not selecting `deepseek-reasoner` |

Feature-specific parameter rules are documented in each guide section below.

---

## Temperature Settings

Source: [https://api-docs.deepseek.com/quick_start/parameter_settings](https://api-docs.deepseek.com/quick_start/parameter_settings)

The default value of `temperature` is `1.0`.

Note: these recommendations apply to normal chat usage. In thinking mode, `temperature` is accepted for compatibility but has no effect.

DeepSeek recommends these `temperature` values by use case:

| Use Case                      | Recommended Temperature |
| ----------------------------- | ----------------------- |
| Coding / Math                 | `0.0`                   |
| Data Cleaning / Data Analysis | `1.0`                   |
| General Conversation          | `1.3`                   |
| Translation                   | `1.3`                   |
| Creative Writing / Poetry     | `1.5`                   |

---

## Thinking Mode

Source: [https://api-docs.deepseek.com/guides/thinking_mode](https://api-docs.deepseek.com/guides/thinking_mode)

DeepSeek thinking mode returns two assistant outputs:

* `reasoning_content`: intermediate reasoning text (CoT field in the API schema)
* `content`: final user-facing answer

Enable thinking mode in either way:

1. Use the reasoning model:
   ```json
   { "model": "deepseek-reasoner" }
   ```
2. Use `thinking`:
   ```json
   { "thinking": { "type": "enabled" } }
   ```

If using the OpenAI SDK with `thinking`, put it in `extra_body`:

```python
response = client.chat.completions.create(
    model="deepseek-chat",
    messages=[{"role": "user", "content": "Hello"}],
    extra_body={"thinking": {"type": "enabled"}},
)
```

### API Parameters and Behavior

**Input**

* `max_tokens`: maximum output length including both reasoning and final answer.
  * Default: `32768` (32K)
  * Maximum: `65536` (64K)

**Output fields**

* `reasoning_content`: reasoning output
* `content`: final answer
* `tool_calls`: tool calls emitted by the model

**Supported with thinking mode**

* Chat Completions
* Tool calls
* JSON Output mode
* Chat Prefix Completion (Beta)

**Not supported with thinking mode**

* FIM Completion (Beta)

**Parameters not supported in thinking mode**

* `temperature`, `top_p`, `presence_penalty`, `frequency_penalty`, `logprobs`, `top_logprobs`
* Compatibility behavior:
  * `temperature`, `top_p`, `presence_penalty`, `frequency_penalty`: accepted but ignored
  * `logprobs`, `top_logprobs`: request errors

### Multi-turn Conversation Rules

* The model emits both `reasoning_content` and `content` each turn.
* For a *new user turn*, pass prior `content` forward, but do not rely on prior-turn `reasoning_content` as chat context.
* For *sub-requests within the same tool-calling turn*, you must send back `reasoning_content` so the model can continue reasoning correctly.
* Recommended optimization: before starting a new user turn, remove historical `reasoning_content` to reduce payload size.

### API Example (No Streaming)

```python
from openai import OpenAI

client = OpenAI(
    api_key="<DeepSeek API Key>",
    base_url="https://api.deepseek.com",
)

# Turn 1
messages = [{"role": "user", "content": "9.11 and 9.8, which is greater?"}]
response = client.chat.completions.create(
    model="deepseek-reasoner",
    messages=messages,
)

reasoning_content = response.choices[0].message.reasoning_content
content = response.choices[0].message.content

# Turn 2: carry assistant content + new user input
messages.append({"role": "assistant", "content": content})
messages.append({"role": "user", "content": "How many Rs are there in 'strawberry'?"})
response = client.chat.completions.create(
    model="deepseek-reasoner",
    messages=messages,
)
```

### API Example (Streaming)

```python
from openai import OpenAI

client = OpenAI(
    api_key="<DeepSeek API Key>",
    base_url="https://api.deepseek.com",
)

messages = [{"role": "user", "content": "9.11 and 9.8, which is greater?"}]
stream = client.chat.completions.create(
    model="deepseek-reasoner",
    messages=messages,
    stream=True,
)

reasoning_content = ""
content = ""
for chunk in stream:
    delta = chunk.choices[0].delta
    if getattr(delta, "reasoning_content", None):
        reasoning_content += delta.reasoning_content
    elif getattr(delta, "content", None):
        content += delta.content
```

### Tool Calls in Thinking Mode

Thinking mode supports multi-step reasoning + tool use before final output.

* During sub-turns of the same user turn, pass the assistant message back with `reasoning_content` and `tool_calls`.
* At the start of a new user turn, remove historical `reasoning_content` (if sent, API ignores old-turn reasoning).
* If your tool-call loop fails to send required in-turn `reasoning_content`, the API can return HTTP `400`.

Compatibility note:

* `response.choices[0].message` already contains `content`, `reasoning_content`, and `tool_calls`. In most SDKs you can append it directly to `messages`.

Equivalent explicit form:

```python
messages.append({
    "role": "assistant",
    "content": response.choices[0].message.content,
    "reasoning_content": response.choices[0].message.reasoning_content,
    "tool_calls": response.choices[0].message.tool_calls,
})
```

#### Full Tool-Call Loop Skeleton

```python
import json
from openai import OpenAI

client = OpenAI(api_key="<DeepSeek API Key>", base_url="https://api.deepseek.com")

tools = [
    {
        "type": "function",
        "function": {
            "name": "get_date",
            "description": "Get the current date",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get weather by location and date",
            "parameters": {
                "type": "object",
                "properties": {
                    "location": {"type": "string"},
                    "date": {"type": "string"},
                },
                "required": ["location", "date"],
            },
        },
    },
]

def get_date():
    return "2026-03-05"

def get_weather(location, date):
    return f"Mock weather for {location} on {date}: Cloudy 7~13C"

tool_impl = {
    "get_date": lambda _: get_date(),
    "get_weather": lambda args: get_weather(args["location"], args["date"]),
}

def clear_reasoning_content(messages):
    for m in messages:
        if isinstance(m, dict) and "reasoning_content" in m:
            m.pop("reasoning_content", None)

messages = [{"role": "user", "content": "How's the weather in Hangzhou tomorrow?"}]

while True:
    response = client.chat.completions.create(
        model="deepseek-reasoner",
        messages=messages,
        tools=tools,
    )
    msg = response.choices[0].message

    # Keep full assistant message for in-turn continuation.
    messages.append(msg)

    if not msg.tool_calls:
        print(msg.content)
        break

    for tc in msg.tool_calls:
        name = tc.function.name
        args = json.loads(tc.function.arguments or "{}")
        result = tool_impl[name](args)
        messages.append({
            "role": "tool",
            "tool_call_id": tc.id,
            "name": name,
            "content": str(result),
        })

# Before the next user turn:
clear_reasoning_content(messages)
messages.append({"role": "user", "content": "What should I wear?"})
```

---

## JSON Output

Source: [https://api-docs.deepseek.com/guides/json_mode](https://api-docs.deepseek.com/guides/json_mode)

JSON Output mode is used when you need strict, machine-parseable JSON output.

### Enable JSON Output

To enable JSON Output, configure all of the following:

1. Set `response_format` to `{"type": "json_object"}`.
2. Include the word `json` in the system or user prompt.
3. Provide a concrete JSON example/shape in the prompt.
4. Set `max_tokens` high enough to avoid truncating JSON midway.

DeepSeek also notes that JSON Output may occasionally return empty `content`; prompt adjustments can reduce this.

### API Contract

**Request parameter**

```json
{
  "response_format": {
    "type": "json_object"
  }
}
```

**Prompting requirements**

* Explicitly request JSON output.
* Define expected keys and structure.
* Provide an example JSON object.

### Minimal Request Example

```json
{
  "model": "deepseek-chat",
  "messages": [
    {
      "role": "system",
      "content": "Return valid JSON only with keys: question, answer."
    },
    {
      "role": "user",
      "content": "Which is the longest river in the world? The Nile River."
    }
  ],
  "response_format": {
    "type": "json_object"
  }
}
```

### Full Python Example

```python
import json
from openai import OpenAI

client = OpenAI(
    api_key="<your api key>",
    base_url="https://api.deepseek.com",
)

system_prompt = """
The user will provide some exam text. Please parse the "question" and "answer"
and output them in JSON format.

EXAMPLE INPUT:
Which is the highest mountain in the world? Mount Everest.

EXAMPLE JSON OUTPUT:
{
    "question": "Which is the highest mountain in the world?",
    "answer": "Mount Everest"
}
"""

user_prompt = "Which is the longest river in the world? The Nile River."

messages = [
    {"role": "system", "content": system_prompt},
    {"role": "user", "content": user_prompt},
]

response = client.chat.completions.create(
    model="deepseek-chat",
    messages=messages,
    response_format={"type": "json_object"},
)

parsed = json.loads(response.choices[0].message.content)
print(parsed)
```

Expected output shape:

```json
{
  "question": "Which is the longest river in the world?",
  "answer": "The Nile River"
}
```

### Implementation Notes

* Parse `response.choices[0].message.content` as JSON (for example, with `json.loads`).
* If JSON is truncated, increase `max_tokens` and tighten prompt verbosity.
* If `content` is empty, retry with stronger constraints and explicit output examples.
* Validate required keys/types after parsing before downstream use.

---

## Tool Calls (Guide)

Source: [https://api-docs.deepseek.com/guides/tool_calls](https://api-docs.deepseek.com/guides/tool_calls)

Tool Calls allows the model to request external function execution. The model does not execute tools itself; your application must execute them and return results as `tool` messages.

### Standard Tool-Call Flow (Non-thinking)

1. Send `messages` plus `tools`.
2. If the assistant returns `tool_calls`, append the assistant message.
3. Execute each requested tool in your application.
4. Append each tool result as a `{"role": "tool", ...}` message.
5. Send the updated `messages` again to let the model produce the final natural-language response.

Minimal loop skeleton:

```python
from openai import OpenAI
import json

client = OpenAI(api_key="<your api key>", base_url="https://api.deepseek.com")

tools = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get weather of a location",
            "parameters": {
                "type": "object",
                "properties": {"location": {"type": "string"}},
                "required": ["location"],
            },
        },
    }
]

messages = [{"role": "user", "content": "How's the weather in Hangzhou, Zhejiang?"}]

response = client.chat.completions.create(
    model="deepseek-chat",
    messages=messages,
    tools=tools,
)
msg = response.choices[0].message
messages.append(msg)

if msg.tool_calls:
    for tc in msg.tool_calls:
        args = json.loads(tc.function.arguments or "{}")
        # Your application executes the tool here.
        tool_result = "24C"
        messages.append({
            "role": "tool",
            "tool_call_id": tc.id,
            "content": tool_result,
        })

    final = client.chat.completions.create(
        model="deepseek-chat",
        messages=messages,
        tools=tools,
    )
    print(final.choices[0].message.content)
```

### Thinking Mode with Tool Calls

From DeepSeek-V3.2 onward, tool use is supported in thinking mode (`deepseek-reasoner` or `thinking` enabled). See Thinking Mode for the full multi-subturn loop and `reasoning_content` handling rules.

### `strict` Mode (Beta)

`strict` mode enforces tool-call output against your function JSON Schema.

Requirements:

1. Use beta base URL: `https://api.deepseek.com/beta`
2. For each function in `tools`, set `"strict": true`
3. Server validates provided JSON Schema; invalid or unsupported schema usage returns an error

Example strict tool definition:

```json
{
  "type": "function",
  "function": {
    "name": "get_weather",
    "strict": true,
    "description": "Get weather of a location",
    "parameters": {
      "type": "object",
      "properties": {
        "location": {
          "type": "string",
          "description": "The city and state, e.g. San Francisco, CA"
        }
      },
      "required": ["location"],
      "additionalProperties": false
    }
  }
}
```

### Supported JSON-Schema Types in `strict` Mode

Supported types:

* `object`
* `string`
* `number`
* `integer`
* `boolean`
* `array`
* `enum`
* `anyOf`

Key constraints from the guide:

* `object`:
  * All properties must be listed in `required`
  * `additionalProperties` must be `false`
* `string`:
  * Supported: `pattern`, `format` (`email`, `hostname`, `ipv4`, `ipv6`, `uuid`)
  * Not supported: `minLength`, `maxLength`
* `number` / `integer`:
  * Supported: `const`, `default`, `minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`, `multipleOf`
* `array`:
  * Not supported: `minItems`, `maxItems`
* `enum`, `anyOf`: supported
* `$ref` / `$def` reusable schema modules are supported per guide examples

Implementation recommendations:

* Validate schemas in CI before deployment to avoid runtime schema-rejection errors.
* Keep schemas explicit and narrow; avoid unsupported constraints.
* When migrating existing tool schemas to `strict`, test against the beta endpoint first.

---

## Context Caching

Source: [https://api-docs.deepseek.com/guides/kv_cache](https://api-docs.deepseek.com/guides/kv_cache)

DeepSeek context caching reuses repeated request prefixes between calls.

### Core Rule

Only repeated **prefix** content between requests can result in cache hits.

If request B starts with the same token prefix as request A, the overlapping prefix can be served from cache in request B.

### Common Patterns That Benefit

1. Long-document Q&A:
   * Re-send the same document prefix with different follow-up questions.
2. Multi-round chat:
   * Earlier shared conversation prefix is reusable.
3. Few-shot prompting:
   * Stable examples in the prompt act as reusable prefix across similar requests.

### Checking Cache Hit Status

Response `usage` includes cache accounting fields:

* `prompt_cache_hit_tokens`: input tokens served from cache
* `prompt_cache_miss_tokens`: input tokens not served from cache

The guide also lists different pricing rates for hit vs miss tokens (check current pricing docs for latest billing details).

Example usage shape:

```json
{
  "usage": {
    "prompt_tokens": 1234,
    "completion_tokens": 256,
    "total_tokens": 1490,
    "prompt_cache_hit_tokens": 900,
    "prompt_cache_miss_tokens": 334
  }
}
```

### Cache Behavior and Limits

* Cache matching applies to request prefix only.
* Output remains newly generated and can still vary (e.g., due to `temperature` randomness).
* Cache unit size is 64 tokens; content shorter than 64 tokens is not cached.
* Cache is best-effort, not guaranteed 100% hit rate.
* Cache build can take seconds.
* Unused cache is evicted automatically (typically hours to days).

Implementation recommendations:

* Keep invariant prompt/context at the front of `messages` for better hit rates.
* Minimize edits to leading prompt text when issuing related follow-up requests.
* Monitor `prompt_cache_hit_tokens` in telemetry to verify caching effectiveness.

---

## Chat Prefix Completion (Beta)

Source: [https://api-docs.deepseek.com/guides/chat_prefix_completion](https://api-docs.deepseek.com/guides/chat_prefix_completion)

Chat Prefix Completion uses Chat Completions, but you provide an assistant prefix and ask the model to continue from that prefix.

### Requirements

1. The last message in `messages` must be role `assistant`.
2. The last assistant message must include `"prefix": true`.
3. Use beta base URL: `https://api.deepseek.com/beta`.

### Typical Use Case

Force constrained output starts, e.g. code blocks:

* Set assistant prefix content to ```` ```python\n ````.
* Use `stop` (for example `["```"]`) to stop generation at the desired boundary.

### Example

```python
from openai import OpenAI

client = OpenAI(
    api_key="<your api key>",
    base_url="https://api.deepseek.com/beta",
)

messages = [
    {"role": "user", "content": "Please write quick sort code"},
    {"role": "assistant", "content": "```python\n", "prefix": True},
]

response = client.chat.completions.create(
    model="deepseek-chat",
    messages=messages,
    stop=["```"],
)

print(response.choices[0].message.content)
```

### Implementation Notes

* Prefix completion is beta-only; do not use the non-beta base URL.
* Keep the prefix short and unambiguous to reduce malformed continuations.
* Pair with `stop` sequences to enforce clean boundaries and avoid extra prose.
* If output drifts, tighten the user instruction and make the assistant prefix more explicit.

---

## Multi-round Conversation

Source: [https://api-docs.deepseek.com/guides/multi_round_chat](https://api-docs.deepseek.com/guides/multi_round_chat)

### Stateless API Design

The `/chat/completions` API is **stateless** — the server does not retain any context between requests. Every request is independent. To maintain conversational continuity across turns, the client is responsible for accumulating the full message history and sending it with every request.

**Rule:** After each turn, append the assistant's response message to your `messages` list, then append the next user message, and send the entire list to the API.

### Message Accumulation Pattern

The canonical pattern for multi-turn conversation:

1. Start with an initial `messages` array (optionally including a `system` message).
2. Send the array to `/chat/completions`.
3. Append the assistant's response message object to `messages`.
4. Append the next user message to `messages`.
5. Repeat from step 2.

### Round-by-Round Message Structure

**Round 1 — initial request payload:**

```json
[
  {"role": "user", "content": "What's the highest mountain in the world?"}
]
```

**Round 2 — full payload sent to API (history + new user turn):**

```json
[
  {"role": "user", "content": "What's the highest mountain in the world?"},
  {"role": "assistant", "content": "The highest mountain in the world is Mount Everest."},
  {"role": "user", "content": "What is the second?"}
]
```

The assistant message from round 1 is inserted between the original user message and the new user message. This ordering must be maintained: `user → assistant → user → assistant → ...`.

### Code Example (Python / OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(api_key="<DeepSeek API Key>", base_url="https://api.deepseek.com")

# Round 1
messages = [{"role": "user", "content": "What's the highest mountain in the world?"}]
response = client.chat.completions.create(
    model="deepseek-chat",
    messages=messages
)

messages.append(response.choices[0].message)
print(f"Messages Round 1: {messages}")

# Round 2
messages.append({"role": "user", "content": "What is the second?"})
response = client.chat.completions.create(
    model="deepseek-chat",
    messages=messages
)

messages.append(response.choices[0].message)
print(f"Messages Round 2: {messages}")
```

### Message Roles

| Role        | Description                                                                                        |
| ----------- | -------------------------------------------------------------------------------------------------- |
| `system`    | Optional. Sets the assistant's behavior/persona. Typically the first message in the array.         |
| `user`      | A message from the human user.                                                                     |
| `assistant` | A response from the model. Must be appended from prior API responses to preserve context.          |
| `tool`      | Result of a tool call. Used in function-calling flows (see Tool Calls section).                    |

### Ordering Constraints

* The conversation must alternate: `user` → `assistant` → `user` → `assistant` → ...
* A `system` message may appear only at the start of the array.
* `tool` result messages follow the `assistant` message that contained the `tool_calls` request.
* Do **not** fabricate or modify assistant message content — always use the exact message object returned by the API.

### Appending the Assistant Message

The assistant message returned by the API contains the full message object including `role`, `content`, and potentially `reasoning_content` and `tool_calls`. You can append the entire message object directly:

```python
messages.append(response.choices[0].message)
```

Or explicitly:

```python
messages.append({
    "role": "assistant",
    "content": response.choices[0].message.content,
})
```

### Multi-turn with Thinking Mode (deepseek-reasoner)

When using `deepseek-reasoner` or `thinking` mode, the assistant message contains an additional `reasoning_content` field alongside `content`. The rules for what to carry forward differ by turn boundary:

* **Within the same user turn** (e.g. mid tool-call loop): pass `reasoning_content` forward — the model needs it to continue its reasoning chain. Omitting it can result in HTTP `400`.
* **At the start of a new user turn**: strip historical `reasoning_content` from prior assistant messages before sending. The API will ignore old-turn reasoning, so removing it reduces payload size without loss of context.

See the [Thinking Mode](#thinking-mode) section for the full tool-call loop skeleton that demonstrates this pattern.

### Context Window and Token Management

Because the entire history is sent on every request, conversation length is bounded by the model's context window. Practical implications for client implementations:

* Track cumulative token usage across turns using the `usage` field in each response.
* Implement a truncation or summarization strategy once the history approaches the context limit.
* `max_tokens` in the request controls the maximum output length for **that turn only** — it does not limit history.
* For `deepseek-reasoner`, the default `max_tokens` is `32768` (32K) and the maximum is `65536` (64K), covering both `reasoning_content` and `content` combined.

### System Message

An optional `system` message can be prepended to set the assistant's behavior across all turns:

```json
[
  {"role": "system", "content": "You are a concise assistant that responds in bullet points."},
  {"role": "user", "content": "What's the highest mountain in the world?"}
]
```

The `system` message is carried forward unchanged in every request as the first element of the array.

---

## Error Handling

Errors return standard HTTP status codes.

Example:

```json
{
  "error": {
    "message": "Invalid API key",
    "type": "authentication_error"
  }
}
```

---

## Rate Limits

Rate limits depend on account tier. If exceeded the API returns HTTP `429`.

---

## Compatibility

DeepSeek aims for compatibility with the OpenAI API, meaning most OpenAI SDKs can be used by simply changing the base URL and API key.

Example configuration:

```python
from openai import OpenAI

client = OpenAI(
    api_key="YOUR_API_KEY",
    base_url="https://api.deepseek.com"
)
```

Beta-only features require:

```python
client = OpenAI(
    api_key="YOUR_API_KEY",
    base_url="https://api.deepseek.com/beta"
)
```

---

## Notes

* Tool calling and chat completions follow OpenAI‑style schemas.
* Some OpenAI features may not yet be implemented.
* Always verify model compatibility.

---

## Dart Client Implementation Checklist

Use this checklist to ensure a complete production-ready Dart client implementation from this document.

### Core HTTP Layer

* Implement base URL configuration:
  * default: `https://api.deepseek.com`
  * beta: `https://api.deepseek.com/beta` (for beta-only features)
* Add `Authorization: Bearer <API_KEY>` header.
* Add `Content-Type: application/json`.
* Implement `GET /v1/models`.
* Implement `POST /v1/chat/completions`.

### Request/Response Modeling

* Model chat roles: `system`, `user`, `assistant`, `tool`.
* Preserve full assistant message objects returned by API.
* Support request fields:
  * `model`, `messages`, `max_tokens`, `stream`, `temperature`, `tools`, `stop`, `response_format`, `thinking`.
* Support response fields:
  * `choices[].message.content`
  * `choices[].message.reasoning_content` (thinking mode)
  * `choices[].message.tool_calls`
  * `usage` including cache fields when present.

### Streaming (SSE)

* Parse SSE events incrementally.
* Accumulate `delta.content`.
* In thinking mode streams, also accumulate `delta.reasoning_content`.
* Handle stream completion cleanly and expose partial chunks if needed.

### Multi-turn State Management

* Treat API as stateless; client must send full conversation history each turn.
* Append prior assistant responses before next user message.
* In tool flows, append assistant tool-call message and tool result messages in order.
* In thinking mode:
  * within same tool-call turn, pass required `reasoning_content`
  * before new user turn, clear historical `reasoning_content` for efficiency.

### JSON Output Support

* Support `response_format: {"type":"json_object"}`.
* Provide helpers to parse `message.content` into JSON objects.
* Surface parse failures and empty-content responses clearly to callers.

### Tool Calling Support

* Expose typed tool schema registration.
* Parse `tool_calls[].function.name` and `tool_calls[].function.arguments`.
* Correlate tool results with `tool_call_id`.
* Return control to model with appended `tool` messages.

### Strict Mode (Beta) Support

* Allow `strict: true` in tool function definitions.
* Enforce/use beta base URL for strict mode requests.
* Surface schema validation errors returned by server with actionable messages.

### Context Caching Observability

* Parse and expose `usage.prompt_cache_hit_tokens`.
* Parse and expose `usage.prompt_cache_miss_tokens`.
* Provide client-side metrics hooks for cache effectiveness.

### Prefix Completion (Beta)

* Support assistant-final message with `"prefix": true`.
* Ensure last message role is `assistant` when using prefix completion.
* Support `stop` for bounded continuations.
* Require/use beta base URL for this feature.

### Error Handling and Retries

* Parse non-2xx JSON error bodies into typed exceptions.
* Handle at least:
  * `401` auth failures
  * `429` rate limits
  * `400` validation/schema errors
  * `5xx` transient server errors
* Implement retry policy for transient failures (`429`, selected `5xx`) with backoff.

### Testing Coverage

* Unit tests for request serialization and response parsing.
* Streaming parser tests (including split chunk boundaries).
* Tool-call loop tests (single and multi-tool cases).
* Thinking-mode tests (reasoning content handling).
* JSON output parsing tests.
* Beta-feature tests (`strict`, prefix completion).
* Integration smoke tests against real endpoints (optional but strongly recommended).

---

End of document.
