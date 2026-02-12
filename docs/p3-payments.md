# P3: Payments & Usage Limits

## Priority: P3 — Not needed until there are users beyond yourself

## Problem

Every voice transcription, fact extraction, resume generation, and tailoring call costs money (LLM API + transcription). If the app scales beyond personal use, there needs to be a way to cover those costs and prevent abuse.

## Essential Outcome

A simple, honest billing system. Users pay only when they're actively using the app. No auto-recurring charges, no "cancel before you forget" dark patterns. Free tier is always available.

---

## Cost Basis

See `p1-telemetry.md` for detailed per-operation cost breakdowns. Summary:

**Estimated API cost per active user per month: ~$2-4** (assuming 10 tailored resumes with adjustments). With prompt caching implemented, this drops to ~$1-2.

**Cost per operation (Sonnet 4.5):**
- Fact extraction: ~$0.01
- Resume generation: ~$0.06
- Resume adjustment: ~$0.07
- Onboarding (full): ~$0.20-0.30

---

## Design

### Billing Model: Usage-Triggered Monthly Pass

This is NOT a subscription. There is no auto-renewal. The model is:

1. **Free tier (always available):** Sign up, complete onboarding, and use the app with hard limits. Enough to experience the full product and generate a resume.
2. **Monthly pass ($5-8):** When the user needs more, they buy a pass. This unlocks expanded limits for 30 days from purchase.
3. **Expiry without renewal:** When the 30 days are up, the user drops back to the free tier. No charge. No reminder emails trying to get them to re-subscribe. Next time they need more, they buy another pass.

**Why this model:**
- Resume tools are inherently bursty — intense use during a job search, then nothing for months. Charging monthly when someone isn't using the app is extractive.
- No "cancel before you forget" anxiety. Users pay when they need it, period.
- Builds trust and goodwill. Users recommend tools that don't feel like they're trying to trick them.
- Simpler to build than subscriptions — no recurring billing logic, no failed payment recovery, no proration, no cancellation flows.
- Honest pricing is a differentiator in a space full of $30/month auto-renewing resume tools.

### Free Tier Limits

Generous enough to experience the full product, tight enough that an active job searcher needs to upgrade:

- **Onboarding:** Fully free, unlimited. Bulk import, AI interview, recap — the whole thing. This is the conversion funnel; zero friction here.
- **Resume generations:** 1-2 per month (enough to see the magic)
- **Resume adjustments:** 2-3 per resume (enough to see the feedback loop work)
- **Fact management:** Conversational fact updates limited to 2-3 per month. Manual fact deletion always free.
- **Viewing, previewing, downloading:** Always free for existing resumes

Cost to Spiel per free user: ~$0.30-0.60. Negligible.

### Paid Pass Limits

- **Resume generations:** ~20-30 per month
- **Resume adjustments:** ~50 per month (users iterate a lot, don't make this the bottleneck)
- **Fact extraction / updates:** Unlimited within reason
- **Cover letters:** Included (when built)

At $5-8 per pass with ~$1-2 in API costs for an active user, margins are 60-75%.

### What Counts as a Billable Action

**Counted against limits:**
- Resume generation or regeneration
- Resume adjustment iteration
- Cover letter generation
- Fact extraction from voice, upload, or link (post-onboarding)
- Conversational fact updates

**Not counted (always free):**
- Onboarding (full flow — import, interview, recap)
- Viewing, previewing, or downloading existing resumes
- Manual fact deletion
- Viewing or removing directives
- PDF rendering of already-generated resumes

### User Experience Around Limits

**Free tier user hits the wall:**
- Clear, friendly message: "You've used your free generations for this month. Want to unlock more? A one-time $X pass gives you full access for 30 days. No auto-renewal, no surprises."
- Show what they get: "Up to 30 resumes, unlimited adjustments, cover letters"
- No guilt-tripping, no countdown timers, no "limited time offer" nonsense

**Paid pass approaching expiry:**
- Optional: gentle notification a few days before expiry ("Your pass expires in 3 days — you have 12 generations remaining")
- After expiry: "Your pass has expired. You're back on the free tier. Buy another pass anytime you need it."
- Their data, resumes, facts — everything stays. They just can't generate new ones beyond the free limit.

---

## Implementation Tasks

### Stripe Integration
- [ ] Stripe Checkout Session for one-time payment (NOT subscription mode)
- [ ] Webhook handler for payment_intent.succeeded
- [ ] Store Stripe customer_id on user record for future purchases

### User Model Updates
- [ ] Add fields: `pass_purchased_at` (datetime, nullable), `pass_expires_at` (datetime, nullable), `stripe_customer_id`
- [ ] Helper function: `User.has_active_pass?(user)` — checks if pass_expires_at > now
- [ ] Track action counts via `llm_events` table (from telemetry — reuse, don't duplicate)
- [ ] Helper function: `User.actions_this_period(user)` — counts LLM events in current month (free tier) or since pass_purchased_at (paid)

### Limit Enforcement
- [ ] Check before any LLM call: does user have capacity?
  - [ ] If active pass: check against paid limits
  - [ ] If no pass: check against free tier limits for current calendar month
- [ ] Return clear, friendly error with upgrade CTA when limit is hit
- [ ] Distinguish between "free tier limit" and "paid pass limit" messaging

### Purchase Flow
- [ ] "Get more" button/link visible when approaching or at limits
- [ ] Stripe Checkout redirect → payment → webhook → set pass_purchased_at and pass_expires_at (now + 30 days)
- [ ] Success page: "You're all set! Full access for the next 30 days."
- [ ] Repeat purchase: if user buys another pass while one is active, extend pass_expires_at by 30 days from current expiry (don't penalize early purchase)

### Account Page
- [ ] Current status: "Free tier" or "Pass active until [date]"
- [ ] Usage this period: actions used / limit
- [ ] Purchase history (from Stripe)
- [ ] Buy pass button (if not active)

---

## Open Questions

- Exact price: $5, $6, $8? Lower is more impulse-buy friendly. $5 feels like nothing when you're job hunting. Start at $5 or $6, can always increase later.
- Should the free tier reset monthly (calendar month) or on a rolling 30-day window? Calendar month is simpler to reason about for users.
- If someone buys a pass and barely uses it, should we do anything? Probably not — they got what they paid for (access), and they won't feel cheated because there's no auto-renewal coming.
- Should there be an option to buy multiple months at a discount for someone who knows they'll be job searching for a while? Maybe later, not at launch.
