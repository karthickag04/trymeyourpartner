# Product Backlog — Feature Implementations (HTTP + Supabase Parity)

This document lists high‑impact features to implement next. Each item includes value, minimal schema/API, and UI/UX notes to ship fast and iterate.

## Prioritized picks (start here)
1) Block & Report Users — trust & safety baseline, self‑contained
2) Saved Searches + Alerts — retention driver
3) Contact Exchange Handshake — clear user value, privacy‑first

---

## Server-side API migration plan (future changeover)
- Intent: Keep Flutter UI and shared service interfaces stable while we migrate from Supabase/HTTP-lite to a dedicated server API (Django/Spring Boot/ASP.NET Core). All new client logic must stay behind service interfaces to enable a drop-in backend swap.

- Principles
  - Stable client contracts: Do not leak backend details into UI. All data access goes through these interfaces:
    - AuthService, ProfileService, MatrimonialDomainService, RealtimeService, MessageService, NotificationService, StorageService, SafetyService, SavedSearchService.
  - HTTP-first parity: The HTTP implementations define the wire contracts we’ll formalize server-side. Avoid SDK-specific shapes in models.
  - Idempotency: Prefer idempotent endpoints for create/update actions where possible; include idempotency keys for client retries.
  - Pagination & filters: Cursor or page/page_size, consistent across endpoints. Lists return predictable envelopes where needed: `{ items, nextCursor? }`.
  - Auth: JWT access + refresh; 401 triggers refresh-and-retry (already implemented in ApiClient).
  - Errors: Structured errors `{ code, message, details? }`; preserve HTTP status codes.

- Endpoints to implement server-side (pending)
  - Saved searches: `POST /saved-searches`, `GET /saved-searches`, `DELETE /saved-searches/:id`, `POST /saved-searches/:id/toggle-alert`.
  - Trust & Safety: `POST /block`, `DELETE /block`, `GET /block/status`, `POST /reports`.
  - Presence/Typing (optional next): `POST /presence/heartbeat`, `GET /presence/:profileId`, `POST /typing`, `GET /typing?thread_id=...`.
  - Others per backlog: Contacts handshake, notifications, etc.

- Background jobs (pending)
  - Saved-search matcher: Periodically match new/updated profiles against `filter_json` of alert-enabled saved searches and enqueue notifications (push/email as applicable).

- Current status
  - Client: DI + HTTP/Supabase implementations in place; feature UIs call only through interfaces.
  - DB: SQL for reports and saved_searches with RLS added; safe to run repeatedly.
  - Server: Implement endpoints above when ready; no client changes required if contracts remain the same.


## Discovery & Matches

### Saved Searches + Alerts
- Value: Notify users when new profiles match their filters (retention).
- Backend:
  - Tables: `saved_searches(id, user_id, name, filter_json jsonb, alert_enabled bool, created_at)`
  - Job: nightly/periodic matcher compares new/updated profiles to filters → writes to `notifications`.
  - API: `POST /saved-searches`, `GET /saved-searches`, `DELETE /saved-searches/:id`, `POST /saved-searches/:id/toggle-alert`.
- UI: “Save search” button on results; toggle “Alerts on/off”; chip to re-run.
 - Status: Client UI (save button, list/manage, run) + DI + HTTP/Supabase services added; SQL `saved_searches` with RLS added. Server endpoints + background matcher pending.

### Compatibility Score + Why Match
- Value: Builds trust and explains results.
- Backend:
  - Function/materialized view: `compute_match_score(a,b)` → score 0–100 + top reasons.
  - API: include `{ score, reasons: ["age proximity", "same state", ...] }` in search/matches responses.
- UI: Badge with score; tap to see “Why” sheet.

### Advanced Filters & Boosts
- Value: Control for users and visibility monetization.
- Backend:
  - Columns: height, diet, mother_tongue, manglik, etc. + indexes (see Performance).
  - Boosts: `profile_boosts(profile_id, starts_at, ends_at, priority)`; apply ordering.
- UI: Filter chips, saved defaults; “Boost profile” CTA.

---

## Messaging & Engagement

### Icebreakers / Quick Prompts
- Value: Reduces cold starts in chat.
- Backend: Seed `icebreakers(id, text)`; API `GET /icebreakers`.
- UI: “Suggest prompt” in composer; 1‑tap insert.

### Voice Notes (lightweight)
- Value: Richer chats without complex infra.
- Backend: Upload via `StorageService` (mp3/ogg); messages carry `{ attachment_url, type: "voice" }`.
- UI: Record/play inline; duration chip.

### Presence + Last Seen
- Value: Feels live; sets reply expectations.
- Backend: `profile_presence(profile_id, last_active_at)` updated via heartbeat; HTTP poll fallback.
- UI: Online dot / "Last seen 5m ago".

### Typing Indicators (HTTP mode)
- Value: Liveness without sockets.
- Backend: `POST /typing { thread_id, expires_at }`, `GET /typing?thread_id=...`.
- UI: “Typing…” shown for ~5–7s.

---

## Trust & Safety

### Block & Report Users
- Value: Safety baseline.
- Backend:
  - `blocked_users(blocker_id, blocked_id, created_at)`; RLS hides blocked in search/messages.
  - `reports(id, reporter_id, reported_id, reason, details, created_at, status)`.
  - API: `POST /block`, `DELETE /block/:id`, `POST /reports`.
- UI: Overflow menu on profile/chat → Block, Report; confirmation and undo for block.
 - Status: Client UI + DI + Supabase implementation done; reports table + RLS added. HTTP endpoints and broader RLS enforcement (search/inbox) pending.

### Photo Moderation & Blur‑Until‑Mutual
- Value: Safety + control.
- Backend: `content_status` on media; serve blurred until mutual interest; admin review queue.
- UI: Blur overlay, tap to hint “Unlock on mutual interest”.

### Phone/Email Verification Badges
- Value: Increases trust.
- Backend: `verifications(user_id, method, verified_at)` + OTP endpoints.
- UI: Badges “Phone verified”, “Email verified”.

---

## Relationship Workflow

### Contact Exchange Handshake
- Value: Private info only after consent.
- Backend: `contact_requests(id, from_id, to_id, status, created_at)`; status in {pending, accepted, declined}.
  - API: request/accept/decline endpoints; reveal contacts after accept.
- UI: “Request contact” button; banner in chat to accept/decline.

### Shortlist Notes & Status
- Value: Lightweight CRM.
- Backend: Extend `shortlisted_profiles` with `note text, stage text`.
- UI: Add note dialog; stage chips (interested/contacted/paused).

### Calendar Planner for Calls
- Value: Moves matches to action.
- Backend: `appointments(id, proposer_id, invitee_id, starts_at, status)`; optional ICS/Google link.
- UI: Propose 2–3 time slots; accept/decline.

---

## Monetization

### Subscription Tiers
- Value: Revenue + upsell.
- Backend: `subscription_plans`, `user_subscriptions(user_id, plan_id, expires_at)`; entitlements gate features (filters, boosts, visibility, message quotas).
- UI: Paywalls/tooltips; upgrade flows.

### Spotlight/Boost Purchases
- Value: One‑off revenue.
- Backend: `purchases(id, user_id, sku, status)`, `profile_boosts(... )` consuming a purchase.
- UI: “Boost profile” card + timer.

---

## Notifications

### Web Push & Email Digests
- Value: Bring users back.
- Backend: store web push endpoints; server pushes on new messages/shortlists; weekly email digest of activity.
- UI: Opt‑in for push; settings for email frequency.

---

## Analytics & Admin

### Match Funnel Analytics
- Value: Data‑driven improvements.
- Backend: `events(user_id, type, entity_id, at)` for view→like→chat→contact.
- UI: Admin dashboard or SQL views feeding charts.

### Moderation Inbox
- Value: Quality and safety.
- Backend: Admin APIs to review `reports` and media; actions (warn/suspend/restore) with audit log.
- UI: Simple moderation queue.

---

## Performance & Scale

### Indexing Pass (hot paths)
- Add/guard with IF NOT EXISTS:
  - `profile_interactions`: (to_profile_id, created_at), (from_profile_id, created_at), partial by type
  - `messages`: (thread_key, created_at DESC)
  - `message_receipts`: (receiver_profile_id, read_at)
  - `shortlisted_profiles`: (by_profile_id), (target_profile_id)
  - `profile_views`: (viewed_profile_id, created_at), (viewer_profile_id, created_at)

### Cursor Paging Everywhere
- Use `(id, created_at)` cursors for search/matches/messages/shortlists; UI infinite scroll with pull‑to‑refresh.

---

## HTTP API Contracts (quick reference)
- Saved searches: `POST/GET/DELETE /saved-searches`, `POST /saved-searches/:id/toggle-alert`
- Block/Report: `POST /block`, `DELETE /block/:id`, `POST /reports`
- Contact exchange: `POST /contacts/request`, `POST /contacts/:id/accept`, `POST /contacts/:id/decline`
- Typing: `POST /typing`, `GET /typing?thread_id=...`
- Presence: `POST /presence/heartbeat`, `GET /presence/:profileId`

---

## Rollout Strategy
- Ship in slices with feature flags; add minimal tests and metrics per feature.
- Start with: Block/Report → Saved Searches/Alerts → Contact Exchange → Presence/Typing → Monetization.
