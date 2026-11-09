# Project memory

## Product intent & audience

- **Project:** Vastu_elegance — a Vastu-themed commerce/service platform (likely Indian market given Razorpay integration).
- Core features include product/service offerings, AI-powered quotation generation, online payments, and admin management.
- Audience: customers seeking Vastu-related products/services with self-service quoting and checkout.

## Brand personality & voice

- Elegant, refined aesthetic implied by name ("elegance").
- Production-grade, polished experience expected.

## Visual design & UX direction

- Tech stack: Vite + React, Tailwind CSS, Lucide React icons.
- No external UI theme/icon packages unless explicitly requested.

## Decisions, constraints & rationale

- **Backend:** Supabase (migrations + edge functions).
- **Payments:** Razorpay integration (key ID, key secret, webhook secret required).
- **Email:** Resend (API key required).
- **Edge functions (expected):** 17 total — 9 live, 8 missing:
  - 3× AI quotation functions
  - 2× payment functions
  - Quote payment functions
  - Razorpay webhook handler
- **Migration decision:** Admin migration with plaintext password was cancelled per user request — do not recreate it. 8 other migrations remain pending (migration tool rate-limited).
- **Deploy blocker:** Edge function deploy tool sees no source changes, so 8 functions won't deploy. Options: edit source files to force redeploy (needs user approval) or reset deploy record manually.

## Open questions & assumptions

- **Secrets needed from user:** `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`, `RESEND_API_KEY`.
- **Redeploy approach:** User has not yet approved editing function source files to force redeploy vs. resetting deploy record themselves.
- **Migration tool:** Rate-limited/refusing calls; status unknown for next session.
- Assumption: project database schema is partially migrated; baseline data counts and security checks cannot run until migrations complete.