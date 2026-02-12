# P1: UI Overhaul & Resume Template Library

## Priority: P1 — The app that makes professional resumes needs to look professional

## Problem

The app currently uses default Phoenix + DaisyUI styling. It's functional but looks like a developer's side project, not a polished product someone would trust with their career. This matters more for Spiel than most apps because the core output is a professional document — if the app itself looks amateur, users won't trust that the resumes it produces look good either. First impressions are everything, especially if we're asking people to pay.

Additionally, there's only one resume template right now. Even though more templates are a future consideration, the infrastructure for browsing and selecting templates needs to exist. Users should be able to see what their resume will look like before they generate it.

## Essential Outcome

The app feels clean, modern, and trustworthy. The UI reinforces the "just talk to us" simplicity — minimal chrome, focused interactions, nothing cluttered. Resume templates are browsable with visual previews so users can pick a style before generating.

---

## Design

### App Styling Overhaul

**Overall direction:** Minimal, confident, professional. Think Linear or Raycast — not flashy, not trendy, just clean and intentional. The app should feel like a tool built by people who care about design, because that signals the resumes will look good too.

**Key principles:**
- **Simplicity:** The core interaction is a single text input. The UI should get out of the way and let the conversation be the focus.
- **Typography first:** Good type hierarchy does most of the work. Pick a clean sans-serif (Inter, Plus Jakarta Sans, or similar), establish clear heading/body/caption sizes, and be consistent.
- **Restrained color palette:** One primary accent color, neutral grays for everything else, semantic colors for success/error/warning only. No rainbow of DaisyUI theme colors.
- **Whitespace:** Generous spacing. Let things breathe. A resume app should feel spacious, not cramped.
- **Dark mode:** Consider supporting it from the start since it's expected now, but don't let it drive the design. Design light mode first, adapt for dark.

**Specific areas to rework:**
- **Navigation:** Minimal top bar or sidebar. Logo, maybe 3-4 links max (Home, Facts, Resumes, Settings). Active state should be obvious.
- **Home state ("What job are you trying to get?"):** This is the hero screen. Single input, prominent, inviting. Previously generated resumes listed below in a clean card grid or list. This page should feel like opening a well-designed app, not a form.
- **Onboarding flow:** The chat-like interface needs to feel conversational, not like a support ticket. Agent messages styled differently from user messages. Voice record button should be prominent and satisfying to use. Progress indication that doesn't feel like a wizard/stepper.
- **Resume preview:** The in-browser preview should look like you're looking at a real document — maybe with a subtle paper shadow, proper margins, clear distinction from the app chrome around it.
- **Feedback/adjustment input:** Should feel integrated with the preview, not like a separate form bolted on below. Maybe a slide-out panel or an inline input that feels part of the viewing experience.
- **Facts view:** Readable list with subtle grouping. Not a database table. Each fact should feel like a note, not a row.

**What to move away from:**
- DaisyUI component defaults (rounded buttons, badge colors, card styles)
- Generic form styling
- Default Phoenix layout and scaffold CSS
- Any UI that looks like "Bootstrap but different"

**Tech approach:**
- Keep Tailwind CSS (already in the stack via Phoenix)
- Remove or minimize DaisyUI dependency — use it for logic-heavy components (dropdowns, modals) if needed but override all visual styling
- Build a small set of custom components: buttons, inputs, cards, layout containers
- Consider a component library approach — define styles once in reusable HEEx components

### Resume Template Library

**The problem today:** There's one template and you get what you get. Even when more templates exist, there's no way to browse or compare them.

**Template selection experience:**
- A gallery/grid view showing all available templates
- Each template shows a **thumbnail preview** — a miniature rendering of what a resume actually looks like with that template
- Thumbnails use the user's actual data (or sample data if they haven't onboarded yet) so it feels real
- Click a template to see a full-size preview
- Select a template as your default, or choose per-resume at generation time

**Generating thumbnails:**
- Render the resume HTML with the template → send to WeasyPrint → get PDF → convert first page to a PNG thumbnail
- Cache thumbnails and regenerate when the template or user's data changes significantly
- For the gallery view, thumbnails can be small (300-400px wide) — just enough to see the layout and style
- Consider pre-rendering thumbnails with sample data for the gallery, and only rendering with real user data on hover or click

**Template metadata:**
- Each template should have: name, description, a style tag (e.g. "Classic", "Modern", "Minimal", "Technical"), and the thumbnail
- Eventually: popularity, "recommended for [industry]" tags

**Where template selection appears:**
- In the template library/gallery (dedicated page or section)
- During resume generation — before or after generating, user can switch templates and see the preview update
- On the resume view page — option to re-render with a different template without regenerating the structured data (since structure and presentation are separate)

---

## Implementation Tasks

### App Styling

#### Foundation
- [ ] Define design tokens: color palette, typography scale, spacing scale, border radii, shadows
- [ ] Pick and configure primary typeface (Inter, Plus Jakarta Sans, or similar via Google Fonts or self-hosted)
- [ ] Create a base Tailwind config with custom theme values replacing DaisyUI defaults
- [ ] Remove or scope DaisyUI — keep for utility components only (modals, dropdowns), override all visual defaults

#### Core Components
- [ ] Button component: primary, secondary, ghost, destructive variants. Consistent sizing and padding.
- [ ] Input component: text inputs, textareas. Clean borders, focus states, error states.
- [ ] Card component: for resume list items, fact cards, template previews
- [ ] Layout shell: nav bar/sidebar, main content area, consistent padding and max-width
- [ ] Voice record button: prominent, satisfying interaction (recording state animation, visual feedback)
- [ ] Chat message components: agent message vs. user message styling for the conversational UI

#### Page Redesigns
- [ ] **Home state:** Hero input for job target, resume list below as card grid
- [ ] **Onboarding:** Chat-like interface with proper message styling, progress indication, voice button
- [ ] **Resume preview:** Document-like presentation with paper shadow, proper margins, clear app/document boundary
- [ ] **Resume adjustment view:** Preview + feedback input as an integrated experience
- [ ] **Facts view:** Clean readable list, conversational input at top, delete buttons that don't dominate
- [ ] **Settings/directives:** Simple list view, minimal chrome
- [ ] **Auth pages:** Login/signup that match the new design language

### Resume Template Library

#### Template Infrastructure
- [ ] Template registry: a module that lists all available templates with metadata (name, description, style tag, HEEx component module)
- [ ] Ensure template rendering is fully decoupled from structured data — any template can render any resume's data

#### Thumbnail Generation
- [ ] Pipeline: structured data → HEEx render → WeasyPrint PDF → first page to PNG
  - [ ] Use ImageMagick or `pdf2image` (via `System.cmd`) to convert first PDF page to PNG
  - [ ] Resize to thumbnail dimensions (~400px wide)
- [ ] Cache thumbnails on disk or in storage, keyed by template + data hash
- [ ] Regenerate thumbnails when template changes or on-demand
- [ ] Generate sample data thumbnails for gallery view (don't require user data)

#### Template Gallery UI
- [ ] Grid view of template thumbnails with name and style tag
- [ ] Click to expand full-size preview
- [ ] "Use this template" action — set as default or apply to specific resume
- [ ] Indicate which template is currently the user's default

#### Template Selection Integration
- [ ] Add template picker to resume generation flow (select before or after generating)
- [ ] Add "Change template" option on resume view page (re-render, don't regenerate)
- [ ] Persist template choice per resume

---

## Open Questions

- How far do we go with the styling overhaul? Full custom design system, or "good enough" with cleaned-up Tailwind? Probably somewhere in between — custom components but not a full design system with documentation.
- Should we hire a designer or do this ourselves? For MVP, doing it ourselves with good taste and reference sites is fine. Can always hire someone later to polish.
- For template thumbnails, is real-time rendering fast enough, or do we need to pre-generate and cache? Probably cache — WeasyPrint + PDF-to-PNG is a multi-second operation.
- How many templates at launch? Probably just 2-3 to start. One clean modern template, one classic/traditional, one minimal. More can come later.
- Should users be able to customize templates (colors, fonts) or just pick from the library? Library only for now. Customization is a huge scope increase.
