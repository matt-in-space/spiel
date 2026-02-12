# P1: Deployment

## Priority: P1 — Needed to ship to anyone beyond localhost

## Problem

The app currently runs locally with Docker Compose (PostgreSQL, Whisper, WeasyPrint). To use it anywhere else — or let anyone else try it — it needs to be deployed.

## Essential Outcome

Spiel is running in production, accessible via a public URL, with all services (app, database, transcription, PDF rendering) operational and reasonably reliable.

## Design

**Target platform:** Fly.io — good fit for Phoenix apps, supports PostgreSQL as a managed service, and can run additional services (WeasyPrint, potentially Whisper) as separate Fly machines.

**Key decisions to make:**
- **Transcription:** Self-hosted Whisper requires a GPU-capable machine, which is more expensive on Fly. Alternatives: Deepgram, AssemblyAI, or OpenAI Whisper API. Trade-off is cost vs. latency vs. infrastructure complexity. For an initial deploy, a third-party API is probably simpler — can always move to self-hosted later.
- **WeasyPrint:** Can run as a small Fly service that accepts HTML via HTTP and returns PDF bytes. Lightweight, doesn't need GPU.
- **LLM:** Already uses Anthropic API, no infrastructure needed beyond the API key.

## Implementation Tasks

- [ ] Deploy Phoenix app to Fly.io
- [ ] Set up Fly Postgres
- [ ] Set up runtime config for `DATABASE_URL`, `SECRET_KEY_BASE`, `PHX_HOST`, `ANTHROPIC_API_KEY` via Fly secrets
- [ ] Evaluate transcription approach: self-hosted Whisper on GPU Fly machine vs. third-party API (Deepgram, AssemblyAI, OpenAI Whisper API)
- [ ] Deploy or replace WeasyPrint service for production
- [ ] CI pipeline (GitHub Actions → Fly deploy)
- [ ] Domain and SSL setup
- [ ] Basic health check / monitoring
