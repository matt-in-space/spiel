# P0: Agent-Driven Resume Adjustments

## Priority: P0 — Core product direction

## Problem

After a resume is generated, users inevitably want to make changes. The current approach is inline editing via forms — collapsible sections where you manually edit fields, add/remove items, etc. This works but it's the opposite of what Spiel is about. The whole point is "just talk" — so refining a resume should work the same way.

The deeper problem is illustrated by the Ember example: a user worked on an Ember project, so "Ember" shows up in both their work history AND their skills. But they don't consider Ember a real skill — it was incidental. Today they'd have to manually find and remove it from the skills section, and it would probably come back next time they generate a resume. There's no way to tell the system "I know about Ember but don't treat it as a skill."

## Essential Outcome

Users refine their resumes through natural language feedback — text or voice. The system applies changes intelligently, and when feedback represents a lasting preference, it remembers it for all future generations. The manual editing UI stays as a fallback but is no longer the primary interaction.

## Design

### Resume Feedback Loop

On the resume view page, below or alongside the preview, there's a simple input: a text box and a voice record button. The user provides feedback like:

- "Remove Ember from the skills section but keep it in the Bonusly work history"
- "Emphasize leadership experience more"
- "Make the summary shorter and more direct"
- "Move the AWS certification higher up"
- "The dates for my time at Company X are wrong — I was there from 2019 to 2022, not 2021"
- "This is too long, try to get it to one page"

**Flow:**
1. User provides feedback (text or voice → transcribed)
2. System sends the current resume structured data + the feedback to the LLM
3. LLM returns updated structured data
4. System shows the user what changed — ideally a visual diff or at minimum a summary like "Removed EmberJS from skills, updated Company X dates to 2019–2022"
5. User confirms or provides additional feedback
6. Updated resume is saved

This creates a tight loop: view → feedback → updated view → more feedback → done.

### Persistent User Directives

Some feedback is about this specific resume. Other feedback is about how the user wants ALL their resumes built. The system needs to distinguish between these.

**Resume-specific adjustments:**
- "Move the AWS section higher on this one"
- "Make this summary tailored more toward backend"
- "Cut the volunteer section from this resume"

**Persistent directives (apply to all future generations):**
- "I don't consider Ember a real skill — don't list it under skills"
- "Always emphasize cloud architecture and infrastructure"
- "Prefer 'Software Engineer' over 'Developer' in job titles"
- "Never include my freelance work unless the posting is for contract roles"
- "Keep resumes to one page unless I say otherwise"

**How directives work:**
- Stored as a list of natural language strings on the user record
- The LLM classifies incoming feedback: is this resume-specific or a general directive?
  - If general → save to directives list AND apply to current resume
  - If resume-specific → apply only to current resume
  - If ambiguous → apply to current resume and ask "should I always do this?"
- Every resume generation prompt includes the user's directives alongside their facts
- Directives can be viewed as a simple list and removed via voice or text ("forget the rule about Ember")

**Data model:**
- Add a `directives` column to the users table (JSONB array of strings, default: empty)
- Update all resume generation prompts to include directives

### Voice-Driven Updates Beyond Resumes

Extend the same conversational pattern to managing the master record:

- **Modifying facts:** "Actually I was at that company for 3 years, not 2" → agent finds the relevant fact and updates it
- **Requesting a resume:** "Make me a resume for a senior backend role focusing on Elixir and distributed systems" → generates resume with directives applied, no need to navigate to a form
- **Adding new experience:** Already works via the incremental addition flow, but should be accessible from anywhere, not just a dedicated page

## Implementation Tasks

- [ ] **Resume feedback UI**
  - [ ] Add feedback input (text box + voice record button) to the resume show/preview page
  - [ ] Wire up voice recording to existing transcription pipeline
- [ ] **Feedback processing pipeline**
  - [ ] Build LLM prompt: takes current resume structured data + user feedback → returns updated structured data
  - [ ] Parse and validate the LLM's updated output
  - [ ] Generate a human-readable summary of what changed (diff)
  - [ ] Show diff to user for confirmation
  - [ ] Save updated resume on confirm
- [ ] **Directive classification**
  - [ ] Build LLM prompt (or extend feedback prompt) to classify feedback as resume-specific vs. persistent directive
  - [ ] If directive: save to user's directives list AND apply to current resume
  - [ ] If ambiguous: apply to current resume, ask user if it should be a standing rule
- [ ] **Directives storage and application**
  - [ ] Add `directives` JSONB column to users table (migration)
  - [ ] Update all resume generation prompts to include user directives
  - [ ] Build a simple directives list view (viewable from settings or profile)
  - [ ] Support removing directives via the same feedback interface ("forget the rule about Ember")
- [ ] **Voice-driven fact updates**
  - [ ] Accept voice/text input that modifies existing facts (not just appends new ones)
  - [ ] LLM determines which existing fact(s) to update based on the input
  - [ ] Show the user what changed before confirming

## Open Questions

- Should the diff view show a before/after of the rendered resume (visual), or a list of structured changes? Visual is more intuitive but harder to build. A structured summary ("Changed X, removed Y, added Z") might be good enough.
- When the LLM classifies feedback as a directive, should it always ask for confirmation, or just do it and let the user see it in their directives list?
- Should there be a limit on the number of directives? Too many could make the generation prompt unwieldy and produce conflicting instructions.
- Can directives conflict with each other? If so, how do we handle that — last-one-wins, or flag it to the user?
