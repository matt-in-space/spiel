# P2: Cover Letters

## Priority: P2 — Valuable addition but not core to the initial product

## Problem

When applying to jobs, most postings ask for a cover letter alongside the resume. Users are already providing a job posting and their facts for resume tailoring — generating a cover letter from the same inputs is a natural extension.

## Essential Outcome

Users can generate a tailored cover letter for any job posting using the same facts and directives that power their resumes. Cover letters are stored alongside the resume they were generated with.

## Design

The cover letter pipeline mirrors the resume generation pipeline: user's facts + job posting requirements + user directives → LLM generates a cover letter → persisted and renderable as PDF.

Cover letters should be associated with a resume record — when you tailor a resume for a job posting, you can also generate a cover letter for the same posting. They share context.

The same feedback loop from resume adjustments should work here — "make the tone more conversational", "emphasize my experience with distributed systems more", etc.

## Implementation Tasks

- [ ] Cover letter generation prompt: facts + job posting + directives → structured cover letter
- [ ] Store cover letters (new table or JSONB on resume record)
- [ ] Cover letter preview in LiveView
- [ ] Cover letter PDF export via WeasyPrint (simpler template than resume — mostly paragraphs)
- [ ] Link cover letter generation to the resume tailoring flow
- [ ] Support feedback/adjustments on cover letters (reuse resume feedback loop)
