# P0: Agent-Driven Onboarding

## Priority: P0 — Core product direction

## Problem

The current onboarding is a multi-step guided flow with fixed prompts (tell me about yourself, your current role, education, etc.). It works, but it's rigid — every user walks through the same script regardless of what they already have. Most people already have a resume, a LinkedIn profile, or some existing documentation of their career. Making them re-dictate everything from scratch is friction that doesn't need to exist.

## Essential Outcome

A new user goes from signup to a fully populated master record in under 5 minutes, with minimal effort. The system meets them where they are — if they have existing materials, it ingests those first and only asks about what's missing.

## Design

### Stage 1: Bulk Import ("Give us what you've got")

This is the very first screen after signup. The message is simple: drop in everything you have, and we'll take it from there.

**Supported inputs:**
- File uploads: PDF and .docx resumes (multiple files supported — someone might have different versions)
- Links: LinkedIn profile URL, personal website, GitHub profile
- Text paste: raw text area for copy-pasting content from anywhere

All inputs go through the existing fact-extraction LLM pipeline. The UI shows progress as each input is processed. Once everything is ingested, the user sees the extracted facts for a quick review — they can remove anything obviously wrong before proceeding.

A "Skip" option is available for users who'd rather just start talking.

**Link ingestion specifics:**
- Fetch page content via HTTP (Req library)
- Extract readable text from HTML
- Pass through the same LLM fact-extraction pipeline used for voice transcripts and uploads
- LinkedIn and GitHub profiles are the most common cases — LinkedIn especially tends to have comprehensive career data
- Auth-walled pages (common with LinkedIn if not public): detect gracefully and suggest the user copy-paste the content or upload an exported PDF instead

### Stage 2: AI-Driven Conversation ("Let's fill in the gaps")

After the bulk import (or if skipped), the agent takes over. It reviews whatever facts exist and conducts a dynamic, adaptive interview. This is NOT a fixed script — the agent decides what to ask based on what it already knows.

**How it works:**
1. LLM receives the current facts list and a system prompt explaining what a complete resume needs
2. LLM identifies gaps — missing sections, thin areas, vague accomplishments
3. LLM generates a targeted question (e.g. "You mentioned you worked at Company X but I don't have details on what you accomplished there — can you tell me more?")
4. User responds via voice or text
5. Response goes through transcription (if voice) → fact extraction → appended to facts
6. Loop: LLM reviews updated facts, asks next question or determines it has enough
7. Conversation ends when the agent is satisfied or the user says they're done

**What makes this better than the guided flow:**
- If someone uploaded a detailed resume, the conversation might only be 2-3 questions about missing accomplishments
- If someone started from scratch, it becomes a longer but still adaptive interview
- Questions are contextual — "you mentioned leading a team of 4, what project was that for?" rather than generic "tell me about your skills"

**Closing prompt:** At the end of the conversation, ask "anything you want me to always keep in mind when building your resumes?" This seeds initial user directives (see P0: Resume Adjustments doc).

### Fallback

Keep the original multi-step guided onboarding as an option. Some users may prefer the structure of being walked through each section explicitly. Surface it as something like "prefer a guided walkthrough instead?"

## Implementation Tasks

- [ ] Build the bulk import LiveView page
  - [ ] File upload drop zone (LiveView uploads, accept PDF and .docx)
  - [ ] Link input fields with URL validation
  - [ ] Text paste area
  - [ ] Progress indicators for each input being processed
  - [ ] Extracted facts review/confirm step
  - [ ] Skip button
- [ ] Build link ingestion pipeline
  - [ ] HTTP fetch with Req
  - [ ] HTML text extraction (strip tags, get readable content)
  - [ ] Feed extracted text through existing LLM fact-extraction pipeline
  - [ ] Handle failures gracefully (auth walls, timeouts, empty pages)
- [ ] Build the AI conversation flow
  - [ ] LLM prompt that receives current facts and identifies gaps
  - [ ] LLM generates one question at a time (not a list)
  - [ ] Voice + text input for responses (reuse existing recording infrastructure)
  - [ ] Fact extraction from responses and append to master record
  - [ ] Loop logic: re-analyze after each response, ask next question or finish
  - [ ] "I'm done" detection (user says they're finished, or agent determines sufficient coverage)
  - [ ] Closing directive prompt
- [ ] Route new users to the new onboarding flow after signup
- [ ] Keep old guided flow accessible as alternative

## Open Questions

- Should the AI conversation have a maximum number of questions to avoid feeling endless? Maybe cap at 10 and let the user opt into more.
- How do we handle the case where someone uploads a resume and it extracts 95% of what's needed — do we still force the conversation step, or let them skip straight to resume generation?
- Should the closing directive prompt be its own step, or just part of the conversation flow?
