# P0: Agent-Driven Onboarding & Core UX Flow

## Priority: P0 — Core product direction

## Problem

The current onboarding is a multi-step guided flow with fixed prompts. It works, but it's rigid and doesn't leverage what users already have. The broader issue is that the post-onboarding experience is form-heavy — the app needs a cohesive UX philosophy where conversation is the primary input method from signup through ongoing use.

## Essential Outcome

A new user goes from signup to their first generated resume in under 10 minutes. The experience feels like talking to a knowledgeable career advisor, not filling out forms. After onboarding, the app's home state is a single input: "What job are you trying to get?" — and that's it.

---

## Full User Journey

### 1. Signup

Standard email/password auth (already built). After signup, the user lands in the onboarding flow.

### 2. Onboarding: Contact Info (Structured Input)

A simple form for the things that must be exact and shouldn't be left to LLM parsing:

- Full name
- Email
- Phone number
- Location (city/state or city/country)
- Optional: LinkedIn URL, personal website, GitHub

This is the ONE form in the app. Everything else is conversational.

### 3. Onboarding: Bulk Import ("Give us what you've got")

Same screen or next step. The prompt is something like: "Drop in anything you have — old resumes, LinkedIn exports, whatever. We'll pull out the important stuff."

**Supported inputs:**
- File uploads: PDF and .docx (multiple files)
- Text paste: for copy-pasting from LinkedIn, a Google Doc, wherever
- Links: LinkedIn profile, personal site (stretch — depends on scrapeability)

All inputs go through the fact-extraction LLM pipeline. Show progress as each is processed. No review step here — facts just get appended. The user will have a chance to review and adjust after the conversation.

This step is skippable. Some people will want to just start talking.

### 4. Onboarding: The Interview (AI-Driven Conversation)

This is the core of onboarding. The agent reviews whatever facts exist (from bulk import or nothing) and conducts a dynamic, adaptive interview.

**Interface:** A chat-like view with a text input and a voice record button. The agent's questions appear as messages. The user responds by typing or recording. Voice responses get transcribed and the text is shown, then facts are extracted and appended.

**How the conversation works:**
- The agent is aware of what it already knows (the current facts list) and what a complete resume typically needs
- It asks targeted questions based on gaps — not a fixed script
- If bulk import covered work history thoroughly, the agent might skip straight to "tell me more about what you accomplished at Company X" or "what skills would you highlight?"
- If starting from scratch, it opens broader: "Tell me about your current or most recent role"
- Questions are one at a time, conversational tone
- The agent probes for accomplishments, metrics, and specifics — "you mentioned you led a migration, what was the scale of that?" — because those are what make resumes strong

**What the agent is NOT doing:** It's not trying to write the resume yet. It's gathering raw material. The output is just facts — atomic statements about the user's career. The structuring into resume format happens later, at generation time.

### 5. Onboarding: The Recap

When the agent determines it has a solid foundation (or the user says they're done), it wraps up with a recap:

"Here's what I've got so far — you've worked at 3 companies over 8 years, primarily in backend engineering and infrastructure. You have a BS in Computer Science from NYU. Your strongest areas seem to be Elixir, distributed systems, and team leadership. Does that sound right? Anything I'm missing or getting wrong?"

The user can respond conversationally: "Yeah that's right but I also have a lot of DevOps experience" or "Actually I wouldn't say team leadership is a strength, I just happened to lead one project."

These responses get processed as facts or directives as appropriate.

**Transition:** "Great, you're all set. Ready to generate your first resume? Just tell me what kind of job you're going for."

This naturally flows the user into the home state.

### 6. Home State: "What job are you trying to get?"

After onboarding, the app's default view is a single input — text box with voice option. The prompt is something like "What job are you applying for?" or "Paste a job posting or describe the role."

**Inputs accepted:**
- A job posting URL → app fetches and extracts requirements
- Pasted job posting text → sent directly to LLM
- A freeform description: "Senior backend engineer at a fintech startup" or "general software engineering resume for a career fair"

The user hits generate, and the system takes their facts + any user directives + the job target and produces a structured resume.

**Below/alongside the input:** A list of previously generated resumes with their target/job posting and date. Quick access to view, download, or regenerate.

### 7. Resume Generation & Writer's Explanation

Once generated, the user sees the resume preview alongside a conversational explanation from the "writer":

"I focused on your Elixir and distributed systems experience since the posting emphasizes backend reliability. I highlighted your team lead experience at Company Y since they're looking for someone who can mentor juniors. I left out the frontend work at Company Z since it didn't seem relevant. Your AWS certification is listed prominently since they mention cloud infrastructure as a requirement."

This explanation is generated by the LLM as part of the resume generation step — it's not a separate call, just an additional output alongside the structured resume data.

### 8. Resume Adjustments (Conversational)

Below the preview and explanation, there's the same text + voice input. The prompt: "Want to make any changes?"

The user provides feedback conversationally:
- "Move the AWS stuff higher"
- "The summary is too long"
- "Add more detail about the database migration project"
- "I don't want EmberJS listed as a skill here"

**Flow:**
1. User provides feedback
2. LLM receives: current resume structured data + user's full facts + user's directives + the feedback
3. LLM returns: updated structured data + explanation of what changed
4. User sees updated preview + delta explanation ("Moved AWS certification to the top of skills, shortened summary from 4 sentences to 2")
5. Repeat until satisfied
6. Save / download PDF

### 9. Fact Management (Conversational + Manual)

Accessible from navigation — a view of "everything I know about you." This shows the user's facts as a readable list. Two ways to interact:

**Conversational:** Same text + voice input at the top. The user says things like:
- "I don't actually have a skill in EmberJS, it's just something I've used before" → agent adds a directive and/or adjusts facts
- "I got promoted to Staff Engineer in January 2025" → new fact appended
- "I left Company X in March, not February" → agent finds and updates the relevant fact
- "I also have a PMP certification I forgot to mention" → new fact appended

**Manual:** Individual facts can be deleted with a simple remove button. No editing — if a fact is wrong, the user corrects it conversationally and the old one can be deleted. This is the minimal manual UI.

**Directives** are also visible here (or in a nearby settings view) — the standing rules like "never list Ember as a skill." These can be removed manually or conversationally ("forget the rule about Ember").

### 10. Ongoing Use

The day-to-day flow is simple:

1. User comes back, lands on home state
2. Pastes a job posting or describes a role
3. Gets a resume + explanation
4. Adjusts if needed
5. Downloads PDF
6. If they have new experience to add, they go to facts and talk about it

Over time, the facts list grows. Periodically, a compaction service runs to deduplicate, reconcile superseded facts, and clean things up (see Future Considerations).

---

## Architecture Notes

### Facts as Unstructured Data

Facts remain unstructured natural language strings. The system does NOT try to maintain a structured "master record" with typed fields for each job, education entry, etc. Structure is imposed at resume generation time by the LLM, which reads the raw facts and produces the structured resume schema.

This is a deliberate choice:
- Adding new information is always append-only (simple, fast)
- The LLM handles the hard work of organizing, deduplicating, and prioritizing at generation time
- No schema migrations when you want to support a new kind of fact
- The same facts can be structured differently depending on the target role

### Directives vs. Facts

Both are stored on the user record. The key difference:
- **Facts** are statements about what you've done: "Built a distributed cache at Company X", "BS in Computer Science from NYU 2018"
- **Directives** are instructions about how to use those facts: "Don't list Ember as a skill", "Prefer 'Software Engineer' over 'Developer'"

The user doesn't need to know this distinction. When they say "I don't really know Ember," the system figures out that's a directive, not a fact correction. When they say "I actually worked there for 3 years," that's a fact update.

### Compaction (Future)

Over time, facts accumulate — duplicates, near-duplicates, superseded information. A periodic LLM compaction pass would:
- Merge duplicates ("Worked at Company X" appearing from both a resume upload and a voice session)
- Reconcile contradictions ("Left Company X in February" vs. later "Left Company X in March" → keep the latest)
- Consolidate related facts ("Used Elixir at Company X" + "Built Phoenix app at Company X" → could remain separate or merge depending on granularity preference)

Not needed for MVP but worth designing facts storage with this in mind.

---

## Implementation Tasks

### Contact Info Form
- [ ] Simple LiveView form: name, email, phone, location, optional links
- [ ] Save to user record (structured fields, not facts)
- [ ] Show after signup, before bulk import

### Bulk Import
- [ ] Drop zone for file uploads (PDF, .docx) — reuse existing upload infrastructure
- [ ] Text paste area
- [ ] Link input fields (stretch: LinkedIn, personal site)
- [ ] Process all inputs through existing fact-extraction pipeline
- [ ] Show progress per input
- [ ] Skip option
- [ ] Link ingestion: HTTP fetch → text extraction → LLM fact extraction
  - [ ] Handle auth-walled pages gracefully (suggest copy-paste instead)

### AI Interview Conversation
- [ ] Chat-like LiveView UI: agent messages + user text input + voice record button
- [ ] LLM prompt: receives current facts, identifies gaps, generates one targeted question
- [ ] User response processing: transcribe if voice → extract facts → append
- [ ] Loop: re-analyze facts after each response, generate next question or finish
- [ ] "I'm done" detection: user says they're finished, or agent determines sufficient coverage
- [ ] Consider a soft cap on questions (e.g. ~10) to avoid feeling endless

### Recap
- [ ] LLM prompt: receives all facts, generates a natural language summary of what it knows
- [ ] Show summary to user, accept conversational corrections
- [ ] Process corrections as facts/directives
- [ ] Transition prompt: "Ready to generate your first resume?"

### Home State Redesign
- [ ] Single input on the main authenticated page: text box + voice for job target
- [ ] Accept: job posting URL, pasted text, or freeform description
- [ ] Generate button
- [ ] Previously generated resumes listed below

### Writer's Explanation
- [ ] Update resume generation LLM prompt to also output a natural language explanation of tailoring decisions
- [ ] Display explanation alongside resume preview
- [ ] Explanation for adjustment iterations should be a delta ("here's what I changed") not a full re-explanation

### Flow Integration
- [ ] Route new users to onboarding after signup
- [ ] Route returning users to home state
- [ ] Keep old guided onboarding accessible as fallback

---

## Open Questions

- Should the AI interview have a hard cap on questions, or just a soft suggestion? ("I think I have enough, but feel free to keep going")
- For link ingestion, LinkedIn profiles are often behind auth. Is it even worth building URL fetching for LinkedIn, or just tell users to export their profile as PDF and upload that?
- Should the writer's explanation be collapsible/dismissable for users who don't care and just want to see the resume?
- When the user provides feedback on facts ("I don't know Ember"), should the system respond confirming what it understood? ("Got it — I won't list EmberJS as a skill on future resumes. The fact that you worked on an Ember project at Bonusly is still recorded.") That feels right but adds another LLM call per interaction.
