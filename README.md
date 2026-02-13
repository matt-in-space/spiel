# Spiel

An agentic resume builder. Have a conversation with the AI to build your career profile, generate tailored resumes, and refine them through natural language feedback. Voice and text input throughout — speak or type, the system adapts.

Built with Elixir, Phoenix LiveView, and Anthropic's Claude API.

## How It Works

1. **Onboarding interview** — An AI interviewer asks about your career through text or voice. It extracts atomic career facts ("Built a monorepo using Vite and React at Bonusly", "Led a team of 4 engineers") and builds your profile. You can also import existing resumes or documents.
2. **Resume generation** — Provide a job title or paste a job posting. The LLM takes your facts, profile, and standing directives to generate a structured, tailored resume.
3. **Conversational refinement** — Chat with the system to adjust the resume. The AI classifies feedback as one-time tweaks or lasting preferences (directives) and applies changes as a preview you confirm before saving.
4. **Export** — Pick a template, preview in the browser, and download a PDF.

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
| `RESEND_API_KEY` | Production | Resend API key for transactional email delivery |
| `FROM_EMAIL` | Production | Sender email address for outbound emails |
| `OPENAI_API_KEY` | Production | OpenAI API key for Whisper transcription |
| `WEASYPRINT_URL` | Production | WeasyPrint service URL for PDF generation |

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

- **`lib/resume/`** — Business logic: accounts, resumes, feedback, interview, transcription, LLM, PDF
- **`lib/resume_web/`** — Phoenix web layer: LiveViews, controllers, templates, components
- **`lib/resume_web/resume_templates/`** — Resume HEEx templates + CSS (Default, Mono, Fresh, Executive)

Key patterns:
- External services (LLM, transcription, PDF) use **behaviour + adapter** with test mocks
- Resume data stored as **Ecto embedded schemas** in a JSONB column
- Same HEEx templates render both the **live preview** and the **PDF export**
- Voice input uses a **colocated JS hook** for MediaRecorder API integration
- Conversational flows (onboarding interview, resume feedback) use **async tasks** with tagged refs for non-blocking LLM calls

## Project Structure

```
lib/resume/
  accounts/          # User auth (phx.gen.auth), profile, facts, directives
  resumes/           # Resume schemas, generator, embedded data types
  feedback.ex        # Conversational resume adjustment via LLM
  interview.ex       # AI-driven career interview for onboarding
  facts.ex           # Fact extraction from text/documents
  transcription/     # Whisper adapter + behaviour
  llm/               # Anthropic adapter + behaviour
  pdf/               # WeasyPrint adapter + behaviour
  job_postings.ex    # Job posting URL fetch + text extraction
  documents.ex       # File upload text extraction (PDF, plain text)

lib/resume_web/
  live/
    onboarding_live.ex        # Guided onboarding: contact, import, interview, recap
    home_live.ex              # Dashboard with resume list + generation
    resumes_live/show.ex      # Resume view with conversational feedback
    profile_settings_live.ex  # Profile, facts, and directive management
    recording_live.ex         # Standalone voice recording
  resume_templates/           # HEEx + CSS templates for rendering
  controllers/                # PDF download endpoint
```
