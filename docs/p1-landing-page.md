# P1: Landing Page

## Priority: P1 — First thing visitors see, determines whether they sign up

## Problem

The current unauthenticated homepage is a centered heading, one-liner tagline, and two buttons ("Get Started" / "Log in"). There's nothing that shows what the product actually does, why someone should trust it, or what makes it different from uploading a resume to ChatGPT. A visitor who lands on `giveyourspiel.app` has no reason to create an account.

## Essential Outcome

An unauthenticated visitor immediately understands what Spiel does, sees it in action (screenshots, demo video, or animations), and feels confident enough to sign up. The page should feel polished, load fast, and work well on mobile.

---

## Design

### Structure

The landing page should be a single scrollable page with distinct sections. No separate routes needed — this replaces the current `home.html.heex` template.

**Hero section:**
- Headline that communicates the core value prop — something like "Talk about your career. Get a resume." or "Your experience, professionally packaged."
- Subheadline expanding on the voice-first angle: you speak or type naturally, the AI builds a structured, tailored resume
- Primary CTA: "Get Started — Free" (links to registration)
- Secondary CTA: "See how it works" (smooth-scrolls to the demo section)
- Hero visual: screenshot of the app in action (onboarding interview or resume preview), or a short autoplaying demo video/animation

**How it works section:**
- 3 steps, visually distinct:
  1. **Tell your story** — Have a conversation (voice or text) about your career. Spiel extracts the important details automatically.
  2. **Generate a resume** — Provide a job title or paste a posting. Get a tailored, structured resume in seconds.
  3. **Refine through feedback** — Chat to adjust. "Make the summary shorter." "Emphasize my leadership experience." Changes preview instantly.
- Each step paired with a screenshot or illustration showing that part of the app

**Feature highlights section:**
- Voice input (record on your phone, Spiel transcribes and extracts)
- Multiple templates (preview different styles, pick what fits)
- Job-tailored generation (same career data, different resume per application)
- Conversational refinement (natural language feedback, not form fields)
- PDF export (clean, professional output)
- Each feature as a card or alternating left/right layout with a supporting image

**Social proof / trust section (when available):**
- Placeholder for testimonials or usage stats
- For now, can be omitted or replaced with a simple "Built with care" message about the tech (Anthropic Claude, etc.)

**Final CTA section:**
- Repeat the primary call to action
- "Ready to give your spiel?" or similar
- Registration button

**Footer:**
- Minimal: copyright, link to login, maybe a contact email

### Visual Direction

Should match whatever design language comes out of the UI overhaul (see `p1-ui-overhaul.md`), but the landing page can lead that effort — design the landing page first, then propagate the style to the app.

Key considerations:
- **Speed:** Static content, no LiveView needed. Images should be optimized (WebP, lazy-loaded below the fold).
- **Mobile-first:** Many users will find this on a phone. The hero should look great at 375px wide.
- **Personality:** The page should feel approachable and slightly opinionated — not generic SaaS. The name "Spiel" is playful; the page can have a bit of character.

### Assets Needed

**Screenshots:**
- Onboarding interview (showing a conversation in progress with voice recording button visible)
- Resume generation (job title input + generated resume appearing)
- Resume preview (a finished resume rendered in-browser, showing template quality)
- Conversational refinement (feedback input with a preview change)

**Optional but high-impact:**
- Short demo video (30-60s screen recording walking through the flow)
- Animated GIF or autoplaying video of the interview → resume pipeline
- Before/after: raw career notes vs. finished resume

**Where assets live:** `priv/static/images/landing/` — served directly by Phoenix's static plug, no esbuild needed.

---

## Implementation Tasks

### Assets
- [ ] Capture screenshots of each major flow (onboarding, generation, preview, refinement)
- [ ] Crop and optimize screenshots (WebP, reasonable dimensions — ~1200px wide max for retina)
- [ ] Optionally record a short demo video/GIF of the end-to-end flow
- [ ] Place assets in `priv/static/images/landing/`

### Page Structure
- [ ] Replace current `home.html.heex` with the full landing page layout
- [ ] Hero section with headline, subheadline, CTA buttons, and hero image/video
- [ ] "How it works" section with 3 steps and paired visuals
- [ ] Feature highlights section with supporting images
- [ ] Final CTA section
- [ ] Minimal footer

### Styling
- [ ] Responsive layout — mobile-first, looks great from 375px to 1440px+
- [ ] Consistent typography hierarchy (large hero heading, medium section headings, body text)
- [ ] Generous whitespace between sections
- [ ] Subtle scroll animations (fade-in on scroll) if desired — keep it tasteful, not distracting
- [ ] Ensure the page works without JavaScript (progressive enhancement for any animations)

### Performance
- [ ] Lazy-load images below the fold (`loading="lazy"`)
- [ ] Use responsive images with `srcset` if providing multiple sizes
- [ ] Keep the page static (no LiveSocket connection needed for unauthenticated visitors)
- [ ] Test page load speed — aim for under 2s on a 3G connection

### Polish
- [ ] Open Graph meta tags (`og:title`, `og:description`, `og:image`) for social sharing
- [ ] Favicon and app icon if not already set
- [ ] Test on mobile (iOS Safari, Android Chrome) — especially the hero section
- [ ] Test with no images loaded (alt text should still convey meaning)

---

## Open Questions

- Should the landing page use the app layout (`Layouts.app`) or a custom layout without the nav bar? Probably a custom minimal layout — the nav bar with auth links doesn't make sense for a marketing page.
- Do we want a live demo or interactive element (e.g., type a job title and see a sample resume)? High impact but significant scope. Probably not for v1.
- How much do we invest in copy? The headlines matter a lot. Worth spending real time on the wording, or even getting outside feedback.
- Should we add a "How is this different from ChatGPT?" section? Could be powerful — emphasize structured data, memory across resumes, voice input, professional templates, and iterative refinement vs. one-shot prompting.
