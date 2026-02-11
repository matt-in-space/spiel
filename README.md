# Spiel

A voice-first resume builder. Talk about your experience and the app extracts facts, then generates polished, tailored resumes on demand. No forms, no manual data entry — just speak and get a resume.

Built with Elixir, Phoenix LiveView, and Anthropic's Claude API.

## How It Works

1. **Voice to facts** — Record audio describing your career. Whisper transcribes it, then the LLM extracts atomic career facts ("Built a monorepo using Vite and React at Bonusly", "Led a team of 4 engineers").
2. **Facts to resume** — Provide a job title or paste a job posting. The LLM takes your facts and generates a structured resume tailored to the target.
3. **Resume to PDF** — Pick a template, preview in the browser, tweak inline, and download a PDF.

## Prerequisites

- **Elixir** >= 1.15 and **Erlang/OTP**
- **PostgreSQL** 15+
- **pdftotext** (from `poppler-utils`) — used for extracting text from uploaded PDF documents
- **Docker** (optional) — for running Whisper and WeasyPrint services via Compose

### System packages

```bash
# macOS
brew install poppler

# Ubuntu/Debian
sudo apt install poppler-utils

# Arch
sudo pacman -S poppler
```

## Setup

```bash
# Start external services (PostgreSQL, Whisper, WeasyPrint)
podman compose up -d   # or docker compose up -d

# Install deps, create DB, build assets
mix setup

# Start the dev server
mix phx.server
```

Visit [localhost:4000](http://localhost:4000).

### Environment variables

Create a `.env` or export these:

| Variable | Required | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | Yes | API key for Claude LLM (fact extraction + resume generation) |
| `DATABASE_URL` | Production | PostgreSQL connection string |
| `SECRET_KEY_BASE` | Production | Phoenix secret (generate with `mix phx.gen.secret`) |
| `PHX_HOST` | Production | Hostname for URL generation |

## External Services

The app depends on three external services, all runnable via `compose.yaml`:

| Service | Image | Port | Purpose |
|---|---|---|---|
| **PostgreSQL** | `postgres:17` | 5432 | Database |
| **Whisper** | `onerahmet/openai-whisper-asr-webservice` | 9000 | Audio transcription (faster_whisper engine, base model) |
| **WeasyPrint** | `ghcr.io/bcgov/weasyprint` | 8080 | HTML/CSS to PDF rendering with proper page break support |

Service URLs are configured in `config/dev.exs`:
- Whisper: `http://localhost:9000`
- WeasyPrint: `http://localhost:8080`

Both use a behaviour/adapter pattern, so they can be swapped for third-party APIs (e.g. OpenAI Whisper API, Deepgram) by implementing the behaviour and changing the config.

## Development

```bash
mix phx.server               # Start dev server
iex -S mix phx.server        # Start with interactive shell
mix test                     # Run tests
mix test --failed            # Re-run failures
mix format                   # Format code
mix precommit               # Full check: compile warnings, deps, format, tests
```

## Architecture

- **`lib/resume/`** — Business logic: accounts, resumes, transcription, LLM, PDF, documents
- **`lib/resume_web/`** — Phoenix web layer: LiveViews, controllers, templates, components
- **`lib/resume_web/resume_templates/`** — Resume HEEx templates + CSS (Default, Mono, Fresh, Executive)

Key patterns:
- External services (LLM, transcription, PDF) use **behaviour + adapter** with test mocks
- Resume data stored as **Ecto embedded schemas** in a JSONB column
- Same HEEx templates render both the **live preview** and the **PDF export**
- Voice input uses a **colocated JS hook** for MediaRecorder API integration

## Project Structure

```
lib/resume/
  accounts/          # User auth (phx.gen.auth)
  resumes/           # Resume schemas, generator, embedded data types
  transcription/     # Whisper adapter + behaviour
  llm/               # Anthropic adapter + behaviour
  pdf/               # WeasyPrint adapter + behaviour
  documents.ex       # File upload text extraction (PDF, plain text)

lib/resume_web/
  live/
    onboarding_live.ex    # Guided voice onboarding flow
    recording_live.ex     # Incremental voice recording
    upload_live.ex        # Document upload for fact extraction
    resumes_live/         # Resume CRUD, preview, inline editing
  resume_templates/       # HEEx + CSS templates for rendering
  controllers/            # PDF download endpoint
```
