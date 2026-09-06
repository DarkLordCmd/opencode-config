# API Optimization Guide

For developers calling the Anthropic API directly (SDKs, custom agents, production apps). These techniques layer on top of the Claude Code optimizations in the main SKILL.md.

## Pricing Cheatsheet

| Model | Input / MTok | Output / MTok |
|-------|-------------:|--------------:|
| Haiku 4.5 | $1 | $5 |
| Sonnet 4.6 | $3 | $15 |
| Opus 4.6 | $5 | $25 |

Every other optimization in this guide is a multiplier on these base prices.

## 1. Prompt Caching — The Biggest Lever

Cached input reads cost **0.1x** the base input price (90% discount). Cache writes cost **1.25x** (one-time surcharge). A cached system prompt pays for itself on the second request.

### Enable it

```json
{
  "model": "claude-sonnet-4-6",
  "system": [
    {
      "type": "text",
      "text": "Your stable system prompt...",
      "cache_control": {"type": "ephemeral"}
    }
  ],
  "messages": [...]
}
```

### Minimum tokens per breakpoint

| Model | Minimum |
|-------|--------:|
| Opus 4.6 / 4.5 | 4,096 |
| Sonnet 4.6 | 2,048 |
| Sonnet 4.5 / 4 | 1,024 |
| Haiku 4.5 | 4,096 |

Below the threshold the request succeeds silently with nothing cached. **Always verify `cache_creation_input_tokens` in the response.**

### Structure for cacheability

Claude processes content in this order: `tools` → `system` → `messages`. Put the most stable content first and place cache breakpoints there. You get up to **4 breakpoints** — use them for sections that change at different rates (e.g. tools, long system prompt, large document, recent history).

### TTL

- Default: **5 minutes**, refreshed on each hit
- Long option: **1 hour** (2x write cost, same 0.1x reads) — worth it for extended-thinking workflows or gaps >5 min

### How to break your cache (avoid these)

| Breaks cache | Survives cache |
|---|---|
| Changing any content before the breakpoint | Changing messages after the breakpoint |
| Adding or removing an **image** anywhere in the prompt | Changing `max_tokens` |
| Modifying `tool_choice` | Appending new user messages |
| Toggling extended thinking on/off (message-level caches only) | Thinking toggle does NOT invalidate system/tool caches |
| Putting `cache_control` on a block with a timestamp, session ID, or user message | — |
| TTL expiration | — |

**Image gotcha:** if your workflow sometimes sends images and sometimes doesn't, treat them as separate request patterns with independent cache lifecycles. Otherwise every toggle triggers a full rewrite.

### Concurrency pitfall

A cache entry is only available **after** the first response starts streaming. If you fan out 10 parallel requests simultaneously, only the first writes the cache — the other 9 miss. Fix: fire the first request, wait for streaming to begin, then fan out the rest.

## 2. Batch API — 50% Off Everything

All token prices cut in half for workloads that tolerate <24h latency. Combines with prompt caching for up to **95% total savings**.

Ideal for: bulk code analysis, content generation, data labeling, offline evals, embeddings-adjacent workflows.

Not for: chat UIs, anything in a user-facing request path.

## 3. Effort Parameter & Thinking Budget

Opus 4.6 and Sonnet 4.6 support `effort: low | medium | high | max`. Lower effort = fewer reasoning tokens = lower cost and latency.

```json
{ "thinking": {"type": "adaptive"}, "effort": "low" }
```

- Use `low` for classification, extraction, formatting, simple routing.
- Use `medium`/`high` for genuine reasoning tasks.
- **Cap `budget_tokens`** (8K–16K is plenty for most tasks — you don't need 100K to format a date).
- **Turn extended thinking off entirely** for pure formatting / lookup tasks. Thinking tokens bill as output.
- Set thinking block `display: "omitted"` if you don't surface reasoning to the user — faster TTFT.

## 4. Prompt Architecture for Lower Output

These reduce both input and output tokens with near-zero effort.

### Be direct, say it once, put the ask first

Skip pleasantries. Put the most important instruction at the top — Claude weights the start of the prompt more. Repeating instructions does not increase compliance; it just costs tokens.

### Use XML tags

```
<instructions>...</instructions>
<context>...</context>
<output_format>...</output_format>
```

Less ambiguity = fewer tokens spent on Claude guessing your intent.

### Constrain length and format explicitly

- "Respond in under 50 words"
- "Max 3 bullet points"
- "Return a JSON object with keys: name, status, score. No explanation."

Open-ended prompts produce open-ended (expensive) responses.

### Prefill the assistant turn to skip preamble

```json
{ "role": "assistant", "content": "{" }
```

Claude continues from `{` with no "Sure! Here's the JSON:" preamble. Go further by prefilling `{"result":` to jump straight to the value.

## 5. Tool Use Efficiency

### Token-efficient tool use

Claude 4 models enable this by default (saves ~14% output tokens on average, up to 70%). For Claude 3.7 Sonnet add header `token-efficient-tools-2025-02-19`. Free savings.

### Load tools dynamically

Every tool definition ships with every request. If you have 15 tools defined but a given task only needs 2, you're paying for 13 unused schemas on every call. Route tasks to minimal tool subsets.

## 6. Model Routing

Don't send every request to the same model. Build a router:

- **Haiku 4.5** — classification, extraction, routing, summarization, simple Q&A (60-70% of typical traffic)
- **Sonnet 4.6** — default coding, medium reasoning
- **Opus 4.6** — deep reasoning, architectural decisions

This single architectural decision is usually the biggest cost lever at scale.

## 7. Conversation Hygiene (API-side)

- **Don't re-send thinking blocks** from prior turns if you manage history manually (the API ignores them automatically, but manual history-builders often re-send them).
- **Summarize long conversations** — compress 20 turns into a 200-word summary. Usage goes from exponential to linear.
- **Prune irrelevant turns** — not every message needs to stay in context.

## 8. Pre-flight Token Counting

Anthropic exposes a token-counting endpoint that returns the exact token count for a request **without running inference**. Use it to:

- Catch unexpectedly large prompts before they cost money
- Debug why a request suddenly got expensive
- Stay under cache-breakpoint minimums intentionally

## 9. Monitoring

- **Usage & Cost API** — breakdowns by model, cache hit/miss, token type. Build dashboards. Fix the top offender first.
- **Claude Code `/cost`** — current session usage; configure the statusline for continuous display.
- **Workspace spend limits** in the Console for teams.
- Community tool: `Maciek-roboblog/Claude-Code-Usage-Monitor`.

## Stacking Savings

Real-world example of compounding:

| Layer | Savings |
|-------|--------:|
| Route simple tasks to Haiku | ~66% vs Sonnet |
| Prompt cache the system prompt | ~90% on repeated input |
| Batch API for offline work | 50% on top |
| Token-efficient tools | ~14% on output |

Combined, an API-heavy workflow can realistically drop 80-95% of its bill without touching product quality.

## Checklist

- [ ] Enable `cache_control` on system prompt and tool definitions
- [ ] Verify `cache_creation_input_tokens` > 0 in responses
- [ ] Route traffic by complexity (Haiku → Sonnet → Opus)
- [ ] Move non-urgent workloads to Batch API
- [ ] Set `effort: low` / cap `budget_tokens` where thinking isn't critical
- [ ] Prefill assistant turn for structured output
- [ ] Load only the tools each task needs
- [ ] Never toggle images in/out of an otherwise-cached prompt
- [ ] Summarize long histories instead of re-sending
- [ ] Monitor via Usage & Cost API or `/cost`
