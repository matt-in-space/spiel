# P3: Payments & Usage Limits

## Priority: P3 — Not needed until there are users beyond yourself

## Problem

Every voice transcription, fact extraction, resume generation, and tailoring call costs money (LLM API + transcription). If the app scales beyond personal use, there needs to be a way to cover those costs and prevent abuse.

## Essential Outcome

A simple billing system that lets users pay for access, with usage limits that prevent runaway API costs. A free tier lets people try before paying.

## Design

**Pricing model (TBD — options):**
- Monthly subscription (simple, predictable)
- Per-generation credit pack (pay for what you use)
- Hybrid: monthly with a generation cap, overage charges or upgrade prompts

**What counts as a "generation":**
- Resume generation or regeneration
- Resume tailoring from a job posting
- Cover letter generation
- Fact extraction (from voice, upload, or link)

**Free tier:** Allow a limited number of generations (e.g. 3-5) so users can experience the full flow before paying. Enough to onboard, generate one resume, and tailor it for one job.

## Implementation Tasks

- [ ] Integrate Stripe (Checkout Sessions + webhook for payment confirmation)
- [ ] Define plan/pricing model
- [ ] Add `generations` counter or `generation_events` table to track each LLM call per user
- [ ] Enforce limits in the generation pipeline — check before calling the LLM
- [ ] Clear upgrade/wait message when limit is hit
- [ ] Free tier implementation
- [ ] Billing management page: current plan, usage, cancel/upgrade
