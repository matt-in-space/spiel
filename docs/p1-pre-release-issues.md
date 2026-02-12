# P1: Pre-Release Issues

## Priority: P1 — Bugs and rough edges to fix before release

This is a running list of known issues and improvements. Items are grouped by area, not priority order within the list.

---

## Job Posting Fetch Failures

`JobPostings.fetch_text/2` does a plain `Req.get` and strips HTML tags. This breaks on many real-world job postings:

- **JS-rendered pages** (Greenhouse, Lever, many ATS platforms): the HTML body is a shell with a `<script>` that hydrates the actual content. After stripping tags we get nothing useful.
- **Login-gated pages** (LinkedIn, some company portals): returns a 200 with a login wall instead of the posting.
- **Anti-bot / Cloudflare challenges**: connection hangs or returns a challenge page.

### Potential fixes

- [ ] Detect empty/useless extraction (e.g. extracted text < 100 chars after stripping) and return a specific error like `{:error, :no_content}` so the UI can say "Couldn't read this page — try pasting the text instead"
- [ ] Consider a headless browser fallback (Playwright/Chrome via a sidecar or service) for JS-rendered pages — heavier but solves the majority of cases
- [ ] For known ATS domains (greenhouse.io, lever.co, workday), try their public API or known JSON endpoints before falling back to HTML scraping
- [ ] Show the fetched text in the textarea after fetch so the user can see if it looks right, and edit/replace before saving (this already happens, but consider adding a warning if the text is suspiciously short)

---

## Performance / Perceived Speed

LLM calls dominate wall time. Resume generation, feedback processing, and transcription all block on external API calls. The app feels slow.

### Areas to investigate

- [ ] **Feedback loop latency**: each feedback round-trip is a full LLM call with the entire resume + context. For simple tweaks ("capitalize AWS") this is overkill. Consider a fast-path: if the feedback looks like a simple text edit, apply it directly without an LLM call.
- [ ] **Resume generation**: initial generation sends all facts + profile + directives + schema instructions. For users with many facts this prompt is large. Consider whether we can trim or summarize facts before sending.
- [ ] **Streaming responses**: the LLM behaviour currently returns the full response at once. Streaming would let us show partial results (especially the explanation) while the rest generates. This requires changes to the `LLM` behaviour and adapter.
- [ ] **Transcription latency**: audio → base64 → server → Whisper API → text. Consider whether we can use browser-side WebSpeech API as a fast preview while the server transcription runs in parallel.
- [ ] **Optimistic UI**: show the user's message in the chat immediately (already done), but also consider showing a skeleton/placeholder for the resume preview while feedback processes.

---

## Other Known Issues

- [ ] **Orphaned EditPanel module**: `lib/resume_web/live/resumes_live/edit_panel.ex` is no longer referenced after removing inline editing. Delete it or repurpose it.
- [ ] **Conversation not cleared on confirm**: after confirming changes, the chat history stays. Should it clear, or persist so the user can keep iterating?
- [ ] **Multiple rapid feedback submissions**: no debounce — user can submit feedback while a previous call is still processing. The `processing_feedback` flag disables the submit button, but voice recording could still queue a second request.
- [ ] **Fact changes applied before confirm**: the plan says fact changes are applied immediately, but this means reverting the resume preview doesn't undo fact changes. Decide if this is the right behavior or if fact changes should also be part of the confirm step.
