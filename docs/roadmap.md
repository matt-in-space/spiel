# Spiel — Voice-to-Resume App

## Overview

Spiel is a voice-first resume builder. Users talk about their experience and the app structures it into a master record, renders it as a polished PDF resume, and can tailor resumes for specific job postings. No forms, no manual data entry — just speak and get a resume.

## Tech Stack

- **Backend/Frontend:** Elixir + Phoenix LiveView
- **Auth:** Phoenix built-in auth generator (phx.gen.auth)
- **Voice Transcription:** Self-hosted Whisper (Docker Compose service)
- **LLM:** Anthropic API (Claude) — for structuring voice input into schema data and tailoring resumes
- **PDF Rendering:** WeasyPrint (HTML/CSS → PDF with proper page break support, Docker Compose service)
- **Resume Templates:** HEEx components + CSS (same templates for live preview and PDF export)
- **Infrastructure:** Docker Compose for local dev services (Whisper, WeasyPrint, PostgreSQL)

## Architecture

### Data Model Concepts

- **Master Record:** The canonical source of truth for a user's entire career history. Contains everything they've ever done. Never modified by tailoring — only by the user directly.
- **Resume:** A curated snapshot derived from the master record. Consists of selected schema data + a template reference. Tailored resumes are new resume entities, frozen at creation time so they don't drift if the master record is updated later.
- **Template:** An HEEx component + CSS file that controls layout, typography, and styling. The same template renders in-browser previews and PDF exports.

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

1. **Guided Onboarding:** A conversational, multi-step flow that walks the user through building their full master record. Works like an interview — focused prompts per section (current role, accomplishments, previous roles, education, skills, etc.). Each step is: prompt → record → transcribe → LLM structures → user reviews/confirms → saved to master record. This is a state machine in LiveView.

2. **Incremental Addition:** User returns to add something new (new job, new project, new cert). App asks what type, gives a focused prompt, records, structures, and merges into the existing master record.

Guided flow produces better LLM output because each chunk is scoped narrowly rather than parsing a 20-minute career monologue.

### Job Posting Tailoring

- User pastes a URL to a job posting
- App fetches the page content and passes it to the LLM to extract requirements
- LLM compares requirements against the user's master record
- Generates a tailored resume: reorders sections, filters irrelevant experience, and rewrites bullet points to better match the job's language
- Result is a new resume entity (snapshot) that can be previewed and exported
- Fallback: allow pasting raw text if URL is behind auth or doesn't scrape cleanly

### PDF Rendering Pipeline

- Resume templates are HEEx components + CSS
- Same HTML renders in LiveView for live preview
- For PDF export: rendered HTML is piped to WeasyPrint via `System.cmd/3`
- WeasyPrint respects CSS paged media properties (`break-inside: avoid`, `break-before`, widows/orphans)
- This solves the page break problem that plagues most resume builders
- Sub-second rendering for resume-length documents

---

## Implementation Roadmap

### Phase 1: Foundation

- [x] Run `mix phx.gen.auth` to scaffold user authentication (email/password)
- [x] Set up basic app layout and navigation with authenticated/unauthenticated states
- [ ] Set up Docker Compose file with PostgreSQL (and placeholder services for Whisper, WeasyPrint)
- [ ] Design and implement the resume schema as Ecto embedded schemas
  - [ ] Contact info fields (name, email, phone, location, website, LinkedIn, GitHub)
  - [ ] Work experience entries (role, company, start date, end date, current flag, accomplishments list)
  - [ ] Education entries (institution, degree, field of study, start date, end date)
  - [ ] Skills (grouped by category)
  - [ ] Optional sections: certifications, projects, publications, volunteer work
  - [ ] Flexible date type: `%{year: integer, month: integer | nil}` — no forced day
- [ ] Create the database schema for master records and resumes
  - [ ] `master_records` table (belongs_to user, stores full career data as JSONB)
  - [ ] `resumes` table (belongs_to user, stores a JSONB snapshot of schema data, template identifier, optional job posting URL, timestamps)
- [ ] Seed/migration setup

### Phase 2: Voice Input Pipeline

- [ ] Build a LiveView page with browser-based audio recording (MediaRecorder API via JS hook)
- [ ] Integrate self-hosted Whisper service (Docker Compose) — send audio, receive text
- [ ] Build the guided onboarding flow as a LiveView state machine
  - [ ] Step: Contact info prompt → record → transcribe → structure → confirm
  - [ ] Step: "Tell me about your current/most recent role" → record → transcribe → LLM extracts structured experience → confirm
  - [ ] Loop: "Any previous roles?" → repeat experience step or skip
  - [ ] Step: Education prompt → record → transcribe → structure → confirm
  - [ ] Step: Skills and certifications → record → transcribe → structure → confirm
  - [ ] Review: Show full master record summary, allow edits before finalizing
- [ ] Build the incremental addition flow
  - [ ] User selects what to add (new job, project, cert, skill, etc.)
  - [ ] Focused prompt → record → transcribe → LLM structures → merge into master record
- [ ] Anthropic API integration for structuring transcribed text into schema data
  - [ ] Build prompt templates that output structured data matching the schema
  - [ ] Parse and validate LLM output before saving
  - [ ] Handle errors and retry logic

### Phase 3: Manual Editing

- [ ] Build a LiveView UI for viewing and editing the master record directly
  - [ ] Edit contact info
  - [ ] Add/edit/remove/reorder work experience entries
  - [ ] Add/edit/remove/reorder education entries
  - [ ] Add/edit/remove skills and categories
  - [ ] Add/edit/remove optional sections
- [ ] Build a LiveView UI for managing resumes
  - [ ] Create a new resume from master record (select which sections/entries to include)
  - [ ] List existing resumes with metadata (created date, job posting if tailored, template used)
  - [ ] Delete resumes

### Phase 4: PDF Rendering

- [ ] Add WeasyPrint as a Docker Compose service and verify it runs via HTTP or `System.cmd/3`
- [ ] Build the first resume template as an HEEx component + CSS
  - [ ] Clean, professional single-column layout
  - [ ] Proper CSS paged media rules: `break-inside: avoid` on experience/education sections, sensible margins, page numbering if multi-page
  - [ ] Handle flexible dates (render "March 2021 – Present" or "2019 – 2023" depending on available data)
- [ ] Build the rendering pipeline: schema data → HEEx → HTML string → WeasyPrint → PDF bytes
- [ ] Add PDF download endpoint
- [ ] Build a live preview in the browser using the same HEEx template (rendered inline in LiveView)

### Phase 5: Job Posting Tailoring

- [ ] Build a LiveView page for tailoring: paste a URL or raw text of a job posting
- [ ] Fetch and extract job posting content from URL (Req + Anthropic API extraction)
- [ ] Build the tailoring prompt: compare master record against job requirements, output a tailored resume schema with reordered/filtered/reworded content
- [ ] Save the tailored result as a new resume entity (snapshot)
- [ ] Preview and export the tailored resume using the same rendering pipeline

### Phase 6: Polish and QA

- [ ] Test PDF rendering across various resume lengths (1-page, 2-page, 3-page) and verify page breaks never split sections
- [ ] Test voice recording across browsers (Chrome, Firefox, Safari)
- [ ] Error handling for failed transcriptions, Anthropic API timeouts, bad URLs
- [ ] Loading states and feedback during voice processing (transcribing → structuring → done)
- [ ] Mobile-responsive layout for the main app (voice recording on phone is a key use case)

---

## Future Considerations (Not MVP)

- Additional resume templates (2-column, academic CV, minimal, etc.)
- `.docx` export for applicant tracking systems
- Cover letter generation from the same master record + job posting
- Cost management for LLM/transcription calls if scaling to multiple users
- Billing/subscription model (per-tailored-resume or monthly during active job search)
- User-created or customizable templates
