# Spiel — Voice-to-Resume App

## Overview

Spiel is a voice-first resume builder. Users talk about their experience and the app extracts facts, then generates polished, tailored resumes on demand. No forms, no manual data entry — just speak and get a resume.

## Tech Stack

- **Backend/Frontend:** Elixir + Phoenix LiveView
- **Auth:** Phoenix built-in auth generator (phx.gen.auth)
- **Voice Transcription:** Self-hosted Whisper (Docker Compose service)
- **LLM:** Anthropic API (Claude) — behind a behaviour so the provider is swappable
- **PDF Rendering:** WeasyPrint (HTML/CSS → PDF with proper page break support, Docker Compose service)
- **Resume Templates:** HEEx components + CSS (same templates for live preview and PDF export)
- **Infrastructure:** Docker Compose for local dev services (Whisper, WeasyPrint, PostgreSQL)

## Architecture

### Data Model Concepts

- **Facts:** A JSON array on the user record containing atomic career statements extracted from voice input. Facts are the raw material — append-only during ingestion, editable post-MVP. Examples: "Built a monorepo using Vite and React at Bonusly", "Led a team of 4 engineers", "BS in Computer Science from NYU, 2018".
- **Resume:** A generated entity with persisted structured data (JSONB). Created by passing the user's facts + a target (desired position or job posting) through the LLM. The structured output is saved once and used for rendering — no re-running the LLM on each view.
- **Template:** An HEEx component + CSS file that controls layout, typography, and styling. The same template renders in-browser previews and PDF exports.

### Data Flow

1. **Voice → Facts:** User records audio → Whisper transcribes → LLM extracts atomic facts → appended to user's facts JSON
2. **Facts → Resume:** User provides a target (job title, job posting URL, or freeform description) → LLM takes all facts + target → generates structured resume data → persisted on the resume record
3. **Resume → Output:** Structured data + template → HEEx renders HTML → live preview in browser or WeasyPrint renders PDF

### Resume Schema Design Principles

- Schema is internal — users never upload or see raw schema data
- Dates should be flexible: year required, month optional, day optional (not forced ISO 8601)
- Schema is the storage format, not the render format — templates decide presentation
- Schema should be opinionated about structure but flexible about content
- Top-level sections to support:
  - Contact info (name, email, phone, location, links)
  - Summary/objective
  - Work experience (role, company, date range, accomplishments/bullets)
  - Education (institution, degree, field, date range)
  - Skills (categorized)
  - Optional: certifications, projects, publications, volunteer work

### Voice Input Flow

Two modes:

1. **Guided Onboarding:** A conversational flow that walks the user through their career. Focused prompts per topic (current role, accomplishments, previous roles, education, skills, etc.). Each step is: prompt → record → transcribe → LLM extracts facts → user reviews → saved to user's facts. Guided flow produces better LLM output because each chunk is scoped narrowly.

2. **Incremental Addition:** User returns to add something new. App gives a focused prompt, records, transcribes, extracts facts, and appends to the existing facts list.

### Job Posting Tailoring

- User pastes a URL or raw text of a job posting
- App fetches the page content (if URL) and extracts requirements
- LLM takes user's facts + job requirements → generates a tailored resume with reordered/filtered/reworded content
- Result is a new resume entity with persisted structured data
- Can be previewed and exported like any other resume

### PDF Rendering Pipeline

- Resume templates are HEEx components + CSS
- Same HTML renders in LiveView for live preview
- For PDF export: rendered HTML is sent to WeasyPrint service via HTTP
- WeasyPrint respects CSS paged media properties (`break-inside: avoid`, `break-before`, widows/orphans)
- This solves the page break problem that plagues most resume builders
- Sub-second rendering for resume-length documents

---

## Implementation Roadmap

### Phase 1: Foundation

- [x] Run `mix phx.gen.auth` to scaffold user authentication (email/password)
- [x] Set up basic app layout and navigation with authenticated/unauthenticated states
- [x] Set up Docker Compose file with PostgreSQL (and placeholder services for Whisper, WeasyPrint)
- [x] Add `facts` JSON column to users table (default: empty array)
- [x] Design and implement the resume structured schema as Ecto embedded schemas
  - [x] Contact info fields (name, email, phone, location, website, LinkedIn, GitHub)
  - [x] Work experience entries (role, company, start date, end date, current flag, accomplishments list)
  - [x] Education entries (institution, degree, field of study, start date, end date)
  - [x] Skills (grouped by category)
  - [x] Optional sections: certifications, projects, publications, volunteer work
  - [x] Flexible date type: `%{year: integer, month: integer | nil}` — no forced day
- [x] Create the `resumes` table (belongs_to user, JSONB structured data, template identifier, optional job posting URL/text, timestamps)
- [x] Set up LLM behaviour and Anthropic adapter

### Phase 2: Voice Input Pipeline

- [x] Build a LiveView page with browser-based audio recording (MediaRecorder API via JS hook)
- [x] Integrate self-hosted Whisper service — send audio via HTTP, receive transcript
- [ ] Build the guided onboarding flow as a LiveView state machine
  - [ ] Step: "Tell me about yourself" — name, contact info, background
  - [ ] Step: "Tell me about your current/most recent role" — what you did, accomplishments
  - [ ] Loop: "Any previous roles?" → repeat or skip
  - [ ] Step: Education background
  - [ ] Step: Skills, certifications, anything else
  - [ ] Review: Show extracted facts, allow user to remove any before saving
- [ ] Build the incremental addition flow
  - [ ] Focused prompt → record → transcribe → extract facts → append to user's facts
- [ ] Anthropic API integration for fact extraction
  - [ ] Build prompt templates that extract atomic facts from transcripts
  - [ ] Parse and validate LLM output before saving
  - [ ] Handle errors and retry logic

### Phase 3: Resume Generation

- [ ] Build resume generation pipeline: facts + target → LLM → structured data → persisted on resume
- [ ] Build a LiveView page for creating a new resume
  - [ ] Input: target position, or paste a job posting URL/text
  - [ ] Show loading state during LLM generation
  - [ ] Preview generated resume
  - [ ] Save resume
- [ ] Build a LiveView UI for managing resumes
  - [ ] List existing resumes with metadata (created date, target/job posting, template used)
  - [ ] View/preview a resume
  - [ ] Delete resumes
  - [ ] Regenerate a resume (re-run LLM with current facts)

### Phase 4: PDF Rendering

- [ ] Verify WeasyPrint service runs via HTTP
- [ ] Build the first resume template as an HEEx component + CSS
  - [ ] Clean, professional single-column layout
  - [ ] Proper CSS paged media rules: `break-inside: avoid` on experience/education sections, sensible margins, page numbering if multi-page
  - [ ] Handle flexible dates (render "March 2021 – Present" or "2019 – 2023" depending on available data)
- [ ] Build the rendering pipeline: structured data → HEEx → HTML string → WeasyPrint HTTP → PDF bytes
- [ ] Add PDF download endpoint
- [ ] Build a live preview in the browser using the same HEEx template (rendered inline in LiveView)

### Phase 5: Job Posting Tailoring

- [ ] Fetch and extract job posting content from URL (Req + LLM extraction)
- [ ] Build the tailoring prompt: facts + job requirements → structured resume optimized for the posting
- [ ] Save the tailored result as a new resume entity
- [ ] Preview and export the tailored resume using the same rendering pipeline

### Phase 6: Polish and QA

- [ ] Test PDF rendering across various resume lengths (1-page, 2-page, 3-page) and verify page breaks never split sections
- [ ] Test voice recording across browsers (Chrome, Firefox, Safari)
- [ ] Error handling for failed transcriptions, LLM timeouts, bad URLs
- [ ] Loading states and feedback during voice processing (transcribing → extracting → done)
- [ ] Mobile-responsive layout for the main app (voice recording on phone is a key use case)

---

## Future Considerations (Not MVP)

- Additional resume templates (2-column, academic CV, minimal, etc.)
- `.docx` export for applicant tracking systems
- Cover letter generation from the same facts + job posting
- Fact editing UI (review, edit, delete individual facts)
- Cost management for LLM/transcription calls if scaling to multiple users
- Billing/subscription model (per-tailored-resume or monthly during active job search)
- User-created or customizable templates
- Alternative LLM providers (Ollama, OpenAI) via the behaviour system
