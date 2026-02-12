# P0: Agent-Driven Resume Adjustments

## Priority: P0 — Core product direction

## Problem

After a resume is generated, users need to refine it. The current approach is inline form editing. This contradicts Spiel's core philosophy — if the input is conversational, the refinement should be too.

The deeper issue is that some adjustments are one-time ("move AWS higher on this resume") and others are permanent preferences ("never list Ember as a skill"). The system needs to handle both through the same conversational interface without the user needing to think about the distinction.

## Essential Outcome

Users refine resumes by talking to the system. Feedback that represents a lasting preference is automatically remembered for future generations. The manual editing UI stays as a fallback but is not the primary path.

## Prior Work (Completed)

The onboarding rewrite and home state redesign are done (`p0-agent-onboarding.md`, now deleted). As part of that work:
- `directives` column added to users (array of strings, default `[]`)
- `User.directives_changeset/2` and `Accounts.update_user_directives/2` exist
- Directives are included in all resume generation prompts (`Generator.directives_section/1`)
- Home state at `/home` with job target input + resume list
- AI interview module (`Resume.Interview`) with adaptive questioning
- No directive creation/management UI yet — that's part of this ticket

---

## Design

### Resume Feedback Loop

**Where it lives:** On the resume view page, below the preview and writer's explanation.

**Interface:** Text input + voice record button. Same component used everywhere in the app.

**Flow:**
1. User provides feedback (text or voice → transcribed)
2. LLM receives: current resume structured data + full user facts + user directives + feedback
3. LLM returns: updated structured data + delta explanation ("Moved AWS to top of skills, shortened summary")
4. User sees updated preview + explanation of changes
5. User confirms, provides more feedback, or reverts
6. Confirmed version is saved

**Important:** Each iteration sends the full context — current structured data, all facts, all directives, AND the feedback. The LLM isn't doing incremental patches; it's regenerating with additional guidance. This is more expensive per call but far more reliable than trying to do surgical edits.

### Directive Detection

When the user provides feedback, the system needs to determine: is this just for this resume, or for all future resumes?

**Resume-specific examples:**
- "Move the AWS section higher on this one"
- "Cut the volunteer section"
- "Make the summary more tailored toward backend"

**Directive examples:**
- "I don't consider Ember a real skill"
- "Always emphasize cloud architecture"
- "Prefer 'Software Engineer' over 'Developer'"
- "Never include freelance work unless it's a contract role"
- "Keep resumes to one page unless I say otherwise"

**How it works:**
- The same LLM call that processes the feedback also classifies it
- If directive: save to user's directives list AND apply to current resume
- If resume-specific: apply only to current resume
- If ambiguous: apply to current resume, then confirm with the user — "Should I always do this, or just for this resume?"
- The confirmation response is part of the conversation, not a separate modal or form

### Directives Storage & Application

**Storage:** `directives` column on users table (JSONB array of strings). Each directive is a natural language string — no structured format needed since the LLM interprets them at generation time.

**Application:** Every resume generation prompt includes the user's directives. The LLM treats them as standing instructions alongside the facts and job target.

**Management:** Directives are visible in the facts/settings view. Can be removed manually (delete button) or conversationally ("forget the rule about Ember"). Can also be added directly from the facts view, not just during resume feedback.

### Fact Updates via Conversation

The same conversational interface supports modifying the user's facts, not just the current resume:

- "I actually was at Company X for 3 years, not 2" → agent identifies the relevant fact(s) and updates them
- "I got promoted to Staff Engineer in January" → new fact appended
- "I don't actually have a skill in EmberJS" → directive added (don't list as skill), fact about working on an Ember project remains

This can happen from two places:
1. During resume feedback — if the user corrects something that's a fact-level issue, the system should update the facts, not just the current resume
2. From the facts management view — dedicated place to talk about your career data

**Confirmation:** When the system modifies facts or adds a directive, it should confirm what it understood: "Got it — I won't list EmberJS as a skill on future resumes. Your work on the Ember project at Bonusly is still recorded." This adds an LLM call but prevents silent misinterpretations.

---

## Implementation Tasks

### Feedback UI
- [ ] Add feedback input component (text box + voice record button) to the resume show page
- [ ] Position below the resume preview and writer's explanation
- [ ] Wire up voice recording to existing transcription pipeline

### Feedback Processing Pipeline
- [ ] LLM prompt: current structured data + facts + directives + feedback → updated structured data + delta explanation + directive classification
- [ ] Parse updated structured data, validate against schema
- [ ] Generate delta explanation (what changed from previous version)
- [ ] Display updated preview + delta to user
- [ ] Confirm / iterate / revert controls
- [ ] Save confirmed version (overwrite current resume)

### Writer's Explanation (Prerequisite)
- [ ] Update resume generation LLM prompt to also output a natural language explanation of tailoring decisions
- [ ] Display explanation alongside resume preview on the resume show page
- [ ] For adjustment iterations, explanation should be a delta ("here's what I changed") not a full re-explanation

### Directive System
- [x] Migration: add `directives` JSONB column to users table (array of strings, default: [])
- [x] Include directives in all resume generation prompts
- [ ] Directive classification in feedback processing (resume-specific vs. persistent)
- [ ] Ambiguous case: ask user "always or just this resume?" within the conversation flow
- [ ] Directive CRUD:
  - [ ] Add via conversation (automatic from feedback classification)
  - [ ] View as list (in facts/settings area)
  - [ ] Remove via delete button or conversational ("forget the Ember rule")

### Fact Updates from Conversation
- [ ] Extend feedback pipeline to detect when feedback implies a fact-level change
- [ ] LLM determines which fact(s) to update, add, or annotate
- [ ] Apply changes to user's facts
- [ ] Confirmation message: explain what was understood and changed
- [ ] Same pipeline accessible from facts management view

---

## Open Questions

- Should directive classification be part of the same LLM call as the resume update, or a separate call? Same call is cheaper but the prompt gets complex. Separate call is cleaner but doubles latency.
- Can directives conflict with each other? ("Always emphasize leadership" + "Focus on individual contribution") If so, should the system detect and flag this, or just let the LLM figure it out?
- Should there be a limit on directives? 10? 20? Unbounded? Too many could make the generation prompt unwieldy.
- When feedback implies a fact change during resume iteration, should the system update facts immediately, or queue it and confirm after the resume iteration is done? Updating immediately means the next iteration already has corrected facts. Queuing avoids interrupting the resume refinement flow.
