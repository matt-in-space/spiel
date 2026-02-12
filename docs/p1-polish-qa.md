# P1: Polish & QA

## Priority: P1 — Required for the app to feel reliable

## Problem

The MVP works but hasn't been hardened. Errors during transcription, LLM calls, or URL fetching can leave the user in a broken state. PDF rendering hasn't been stress-tested across different resume lengths. Mobile experience (critical for voice recording on a phone) hasn't been verified.

## Essential Outcome

The app handles failures gracefully, gives clear feedback during async operations, produces correct PDFs regardless of resume length, and works well on mobile.

## Implementation Tasks

- [ ] **Error handling and retry logic**
  - [ ] Failed transcriptions: retry once, then show clear error with option to re-record
  - [ ] LLM timeouts: retry with backoff, show "taking longer than expected" state
  - [ ] Bad URLs during job posting fetch: show error, suggest pasting text instead
  - [ ] Unreadable uploads: show error with guidance on supported formats
- [ ] **PDF rendering QA**
  - [ ] Test with 1-page, 2-page, and 3-page resumes
  - [ ] Verify `break-inside: avoid` never splits a work experience entry across pages
  - [ ] Verify section headers never end up orphaned at page bottom
  - [ ] Test with edge cases: very long accomplishment lists, many short jobs, minimal data
- [ ] **Loading states and feedback**
  - [ ] Voice processing: show transcribing → extracting → done stages
  - [ ] Resume generation: show progress indicator during LLM call
  - [ ] PDF export: show generating state
  - [ ] File upload: show processing state per file
- [ ] **Cross-browser voice recording**
  - [ ] Test MediaRecorder API in Chrome, Firefox, Safari
  - [ ] Handle browser permission denials gracefully
- [ ] **Mobile responsiveness**
  - [ ] Voice recording on phone is a key use case — make sure the record button and flow work well on small screens
  - [ ] Resume preview should be readable on mobile (or clearly prompt to download PDF)
  - [ ] File upload should support mobile camera/file picker
