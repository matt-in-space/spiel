# P1: Telemetry, Logging & Observability

## Priority: P1 — Essential infrastructure for operating and understanding the app

## Problem

The app makes LLM calls, transcription calls, and PDF rendering calls — all of which cost money, can fail, and vary in latency. Right now there's no visibility into any of it. You can't answer basic questions like: how many tokens did that resume generation use? How long does transcription take on average? Which LLM prompts are the most expensive? Is WeasyPrint ever slow?

Beyond cost tracking, proper telemetry is foundational for debugging production issues, understanding usage patterns, and eventually enforcing usage limits (P3: Payments). It's also a good opportunity to get comfortable with Prometheus + Grafana as a general skill.

## Essential Outcome

Every significant operation in the app emits structured telemetry events. LLM token usage is tracked per-call with cost estimates. All services (transcription, LLM, PDF rendering) have latency and error rate visibility. Everything flows into Prometheus and is visualizable in Grafana dashboards.

---

## Design

### What to Instrument

**LLM Calls (highest priority):**
- Input tokens, output tokens, total tokens per call
- Model used
- Call type: fact_extraction, resume_generation, resume_adjustment, directive_classification, onboarding_question, job_posting_extraction, cover_letter, compaction
- Latency (time from request to full response)
- Success/failure
- Cost estimate (tokens × per-token rate for the model)
- User ID (for per-user usage tracking, feeds into P3 payments)

**Transcription (Whisper):**
- Audio duration (seconds)
- Transcription latency
- Success/failure
- Resulting transcript length (characters/words)

**PDF Rendering (WeasyPrint):**
- Rendering latency
- HTML input size
- PDF output size
- Success/failure

**Fact Extraction Pipeline:**
- Source type: voice, upload, link, text_paste
- Number of facts extracted per call
- Processing latency end-to-end (from user input to facts saved)

**General App Metrics:**
- Request count and latency per LiveView route
- WebSocket connection count
- Database query latency (Ecto telemetry — already emitted by default, just needs to be wired up)
- Background job metrics (if using Oban or similar)

### Phoenix Telemetry Integration

Phoenix and Ecto already emit `:telemetry` events out of the box. The main work is:
1. Attaching handlers to existing events (Phoenix request duration, Ecto query time)
2. Emitting custom events for LLM calls, transcription, and PDF rendering
3. Exporting everything to Prometheus format

**Custom event naming convention:**
```
[:spiel, :llm, :call]        → metadata: %{type: :resume_generation, model: "claude-sonnet-4-20250514", ...}
[:spiel, :llm, :tokens]      → measurements: %{input: 1500, output: 800, total: 2300, estimated_cost_cents: 2.3}
[:spiel, :transcription, :call]  → measurements: %{duration_ms: 3400, audio_seconds: 45}
[:spiel, :pdf, :render]      → measurements: %{duration_ms: 850, html_bytes: 12000, pdf_bytes: 45000}
[:spiel, :facts, :extracted]  → measurements: %{count: 12, duration_ms: 5600}, metadata: %{source: :voice}
```

### Stack

**Prometheus:** Time-series metrics database. Scrapes a `/metrics` endpoint exposed by the app. Stores all the counters, histograms, and gauges.

**Grafana:** Dashboard UI on top of Prometheus. Build dashboards for LLM costs, latency distributions, error rates, usage patterns.

**Libraries:**
- `telemetry` / `telemetry_poller` — already in Phoenix deps, core event system
- `telemetry_metrics` — define metric types (counter, sum, distribution)
- `peep` or `prom_ex` — Prometheus exporter for Elixir telemetry. `prom_ex` is batteries-included with plugins for Phoenix, Ecto, and Oban. Exposes `/metrics` endpoint.

**Infrastructure:** Add Prometheus and Grafana as Docker Compose services alongside PostgreSQL, Whisper, and WeasyPrint. They're lightweight and this keeps everything local for development.

### Structured Logging

Alongside metrics, structured logging with metadata gives you the ability to trace individual requests:

- Use `Logger.metadata` to attach user_id, request_id to all log lines in a request
- Log LLM calls with token counts and latency at `:info` level
- Log errors with full context at `:error` level
- Consider JSON log format for production (easier to search/filter)

Elixir's built-in Logger + a JSON formatter backend is sufficient. No need for an external logging service initially — just make sure logs are structured so they're useful when you eventually ship to production and want to pipe them somewhere.

### LLM Cost Tracking

This deserves its own callout because it's the primary ongoing cost.

#### Current Anthropic Pricing (per million tokens, as of Feb 2025)

| Model | Input | Output |
|-------|-------|--------|
| Haiku 4.5 | $1 | $5 |
| Sonnet 4.5 | $3 | $15 |
| Opus 4.5 | $5 | $25 |

**Recommended model:** Sonnet 4.5 for all Spiel operations. Best balance of capability and cost for structured extraction and generation tasks.

#### Estimated Cost Per Operation (Sonnet 4.5)

| Operation | Input Tokens | Output Tokens | Est. Cost |
|-----------|-------------|---------------|----------|
| Fact extraction (voice/upload) | ~3,500 | ~1,000 | ~$0.01 |
| Onboarding interview question | ~4,000 | ~200 | ~$0.015 |
| Job posting extraction | ~3,000 | ~500 | ~$0.017 |
| Resume generation | ~8,000 | ~2,500 | ~$0.06 |
| Resume adjustment | ~10,000 | ~2,500 | ~$0.07 |
| Directive classification | ~2,000 | ~200 | ~$0.006 |

**Typical user session** (generate 1 tailored resume + 3 adjustment rounds): ~$0.29

**Typical active monthly user** (10 tailored resumes with adjustments): ~$2-4/month in API costs

**Full onboarding** (upload + 8-10 interview questions + recap): ~$0.20-0.30

These estimates assume facts lists of ~3,000-5,000 tokens. As users accumulate more facts over time, input token counts for generation and adjustment calls will grow. Prompt caching (see below) mitigates this significantly.

#### Prompt Caching

Anthropic's prompt caching reduces repeated input costs by 90%. Since Spiel sends the same system prompt + user facts + directives on nearly every call in a session, caching should be implemented early:

- Cache write: 1.25x base input price (first call in a session)
- Cache read: 0.1x base input price (subsequent calls)
- 5-minute default TTL, 1-hour option available

With caching, a session with 4 resume adjustments drops from ~$0.29 to ~$0.12 since the facts/directives/system prompt are only paid in full once.

#### Cost Tracking Implementation

- Maintain a config map of model → price per input token / output token (update when Anthropic changes pricing)
- Anthropic returns `input_tokens` and `output_tokens` in every API response body — read these directly, don't estimate
- After each LLM call, compute estimated cost from actual token counts
- Emit as a telemetry measurement so it flows into Prometheus
- Grafana dashboard: daily/weekly/monthly LLM spend, broken down by call type
- Per-user token usage (feeds directly into P3 usage limits)

**Storage consideration:** For per-user tracking and billing, persist LLM call records to the database (not just Prometheus) — a `llm_events` table with user_id, call_type, model, input_tokens, output_tokens, estimated_cost_cents, timestamp. This gives you queryable history that Prometheus time-series data doesn't easily support (Prometheus is great for aggregates, not great for "show me all calls for user X in the last month").

---

## Implementation Tasks

### Telemetry Foundation
- [ ] Add `prom_ex` (or `peep` + `telemetry_metrics_prometheus`) to deps
- [ ] Configure PromEx plugins: Phoenix, Ecto, and any others relevant
- [ ] Expose `/metrics` endpoint for Prometheus scraping
- [ ] Verify default Phoenix and Ecto metrics are flowing

### Custom Telemetry Events
- [ ] Define custom event modules (e.g. `Spiel.Telemetry`)
- [ ] Instrument LLM adapter: emit `[:spiel, :llm, :call]` with token counts, latency, type, model, success/failure
- [ ] Instrument transcription service: emit `[:spiel, :transcription, :call]` with audio duration, latency, success/failure
- [ ] Instrument PDF rendering: emit `[:spiel, :pdf, :render]` with latency, sizes, success/failure
- [ ] Instrument fact extraction pipeline: emit `[:spiel, :facts, :extracted]` with count, source type, end-to-end latency

### LLM Cost Tracking
- [ ] Config map: model name → input token price, output token price (Sonnet 4.5: $3/$15 per MTok)
- [ ] Read `input_tokens` and `output_tokens` from Anthropic API response body (don't estimate)
- [ ] Compute estimated cost per call, include in telemetry event
- [ ] Create `llm_events` table (user_id, call_type, model, input_tokens, output_tokens, cache_read_tokens, cache_write_tokens, estimated_cost_cents, inserted_at)
- [ ] Write to `llm_events` after each LLM call (async — don't block the request)
- [ ] Context function: `Spiel.Telemetry.user_usage_summary(user_id, period)` for querying usage

### Prompt Caching
- [ ] Implement Anthropic prompt caching for system prompt + user facts + directives (these are the same across calls in a session)
- [ ] Track cache hit/miss in telemetry events
- [ ] Monitor cache effectiveness in Grafana (cache hit rate, cost savings vs. non-cached)

### Structured Logging
- [ ] Set up Logger metadata: user_id, request_id on each request/socket connection
- [ ] Add structured log lines for LLM calls, transcription, PDF rendering
- [ ] Consider JSON log formatter for production (`logger_json` or similar)

### Docker Compose Services
- [ ] Add Prometheus service to docker-compose.yml
  - [ ] Configure scrape target pointing at the Phoenix app's `/metrics` endpoint
  - [ ] Set appropriate scrape interval (15s is typical)
- [ ] Add Grafana service to docker-compose.yml
  - [ ] Pre-configure Prometheus as a data source
  - [ ] Volume mount for persistent dashboard storage

### Grafana Dashboards
- [ ] **LLM Overview:** total calls, tokens, estimated cost over time, broken down by call type
- [ ] **LLM Latency:** p50/p95/p99 latency per call type
- [ ] **Transcription:** call count, latency, audio duration distribution
- [ ] **PDF Rendering:** call count, latency, success/failure rate
- [ ] **App Health:** Phoenix request latency, WebSocket connections, Ecto query time
- [ ] **Per-User Usage:** token consumption by user (when relevant for payments)

---

## Open Questions

- `prom_ex` vs. `peep` + manual setup? `prom_ex` is more batteries-included but is a heavier dependency. `peep` is simpler and more lightweight. Since the goal is also to learn the stack, manual setup with `peep` might be more educational.
- Should `llm_events` be written synchronously or via an async job (Oban)? Async is better for latency but adds complexity. A simple `Task.Supervisor` based async write might be the sweet spot.
- How long to retain detailed `llm_events`? Could grow large over time. Maybe keep 90 days of detail and rely on Prometheus for longer-term aggregates.
- Should Grafana dashboards be checked into the repo as JSON exports, or just built manually and persisted via Docker volume? Checking them in is more reproducible.
