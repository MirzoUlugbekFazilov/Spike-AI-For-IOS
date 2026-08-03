# Misuse and Risk Report

Date: 2026-05-25

## Fixed Abuse Cases

| Severity | Issue | Fix Implemented |
| --- | --- | --- |
| Critical | Shield extension could send a notification every time a blocked app rendered a shield. | Removed shield-render local notifications entirely. |
| Critical | Task alarms used `defaultCritical` without a critical-alert entitlement. | Replaced with standard sound and kept time-sensitive interruption only. |
| High | Active restrictions could survive logout. | Logout now deactivates focus mode and clears shields. |
| High | Previous-user tasks, goals, profile, progress, usage, milestones, and reminders could remain in memory after logout/account switching. | Added signed-out reset paths across user-scoped stores, cleared app-group shield goal counts, cleared local user-progress caches, and removed pending task reminder/alarm requests. |
| High | Remote sign-out failure could leave the app showing a stale signed-in session. | Local auth state is now cleared even when Supabase sign-out throws. |
| High | Active Screen Time mode could stay locally active after Screen Time permission was revoked. | Foreground refresh now deactivates Screen Time modes if authorization is no longer approved. |
| High | Screen Time mode could activate with no selected apps/categories/domains. | Activation now requires a valid selection. |
| High | DeviceActivity monitor reapplication covered Lock-in but not Sweat mode. | Monitor extension now applies shields for both `hard` and `sweat`, checks active state, validates selections, and clears stale shields when invalid. |
| High | Lock-in/Sweat could be bypassed from the shield action extension when all daily goals were complete. | Removed the completed-goals bypass for hard protection modes; Focus mode remains intentionally bypassable and Sweat only opens during an active movement unlock window. |
| High | Notification manager cancelled all pending app notifications when Chill mode changed. | It now cancels only Spike focus reminder IDs and the Chill morning ID. |
| High | Rapid task toggles/deletes could race local optimistic state and backend writes. | Added per-task pending mutation guards and delete rollback. |
| High | Rapid goal status/delete operations could race local optimistic state and backend writes. | Added per-goal pending mutation guards, status rollback, and delete rollback. |
| High | Repeated perfect-day triggers could duplicate backend writes and leave optimistic local streak state after a failed upsert. | Added per-day pending guards and rollback for focus-day/streak persistence. |
| High | AI progress-summary function could return successful synthetic output for malformed requests, missing server configuration, or unhandled failures. | Function now fails closed with explicit 400/500 errors for invalid request/server states. |
| Medium | Empty/oversized task titles could be persisted or shown in notifications. | Trimmed, rejected empty titles, and capped persisted titles. |
| Medium | Empty/oversized goal titles and oversized descriptions could be persisted. | Trimmed, rejected empty titles, capped goal titles, and capped descriptions. |
| Medium | Weekly summary calendar math used force unwraps. | Replaced calendar force unwraps with guarded fallbacks. |
| Medium | Past task reminders could be scheduled. | Past/near-past reminders are ignored. |
| Medium | Sweat Mode unlock could accumulate unbounded time. | Unlock bank capped at 15 minutes and individual claims capped at 5 reps. |
| Medium | Camera startup ran on the main actor. | Session start moved to the camera processing queue. |
| Medium | Auth mail button attempted to open `message://`. | Replaced with `mailto:` and removed unused query scheme. |
| High | Delete Account falsely claimed permanent deletion but only signed out. | Added a Supabase Edge Function and client flow for server-side auth user deletion. |
| Medium | Auth screen had non-clickable Terms copy. | Added in-app Terms and Privacy sheets before sign-in. |
| Medium | Google OAuth still used the legacy `linear://` redirect. | Switched Google OAuth to `spikeai://login-callback` while keeping legacy URL handling for migration. |
| Medium | No privacy manifest declared UserDefaults required-reason API usage. | Added `SpikeAI/PrivacyInfo.xcprivacy` with app-only and app-group UserDefaults reasons. |
| Low | Export-compliance metadata was ambiguous despite no custom cryptography being found. | Added `ITSAppUsesNonExemptEncryption = false` to the app Info.plist. |
| Medium | App advertised iPad support without iPad-specific QA for a phone-first Screen Time product. | Set all targets to iPhone-only and opted the app target out of Mac/XR compatibility surfaces for launch. |
| Low | UI test target contained placeholder boilerplate only. | Replaced it with a launch smoke test for known onboarding, auth, or main-app surfaces. |
| High | App icon catalogs declared required icon slots without backing image files. | Generated opaque 1024x1024 app icon PNGs and wired them into the app and Live Activity asset catalogs. |
| Medium | Email magic-link flow still used a legacy hosted redirect and generated `linear_user` fallback names. | Switched email magic-link redirect to `spikeai://login-callback` and changed fallback usernames to `spike_user`. |
| Low | Live Activity extension sources contained template/example copy. | Replaced sample widget/control strings with Spike AI-specific copy. |
| Low | Lock-in copy was overly harsh and amateur. | Reworded to professional blocked-state language. |

## Remaining Edge Cases and Risks

| Severity | Risk | Current Status |
| --- | --- | --- |
| Critical | Family Controls entitlement may not be approved by Apple. | Unavoidable until Apple approves entitlement request. Metadata must explain exact use. |
| Critical | Full build/archive was not verified due local Xcode clang probe stall. | Must be resolved before TestFlight or App Store submission. |
| High | Bundle IDs and app group IDs still use `Linear`. | Preserved to avoid breaking provisioning. Rename only as a coordinated release task. |
| High | `linear://` remains supported for auth redirects. | Kept for compatibility. Test `spikeai://` in Supabase/Netlify, then remove legacy redirects after migration. |
| High | Supabase anon key is public in the app binary. | Acceptable only if RLS is correct. Verify production RLS and advisors before launch. |
| High | Public legal URLs still need to exist for App Store Connect. | In-app legal sheets exist; public hosted URLs still need to be created. |
| High | Account deletion depends on an Edge Function deployment. | `supabase/functions/delete-account` exists; deploy and test with `SUPABASE_SERVICE_ROLE_KEY`. |
| High | Progress summary generation depends on Edge Function deployment and `HF_TOKEN`. | Function now fails safely, but `generate-progress-summary` must still be deployed and tested. |
| High | Supabase redirect URL allow-list must include `spikeai://login-callback`. | Client now uses the Spike AI scheme directly; configure the hosted Supabase project before TestFlight. |
| High | Large SwiftUI files increase regression risk. | Not fully refactored in this pass to avoid destabilizing core behavior. |
| Medium | Local streak/progress can be influenced by device time changes. | Backend focus-day upsert helps, but true anti-tamper requires server-derived dates. |
| Medium | Sweat movement detection can still false-positive. | Capped unlock reduces damage; better validation requires more robust pose classification and real-device QA. |
| Medium | iPad/Mac/XR support is not part of the initial release surface. | Intentionally disabled. Re-enable only after dedicated layout, Screen Time, and metadata QA. |
| Medium | iOS 26+ deployment target limits install base. | Decide deliberately; lowering target requires availability audit. |
| Medium | Live Activity behavior has not been verified on a physical device. | Test enable/disable, stale state, and task updates. |
| Medium | Notification permission denial can still reduce Chill mode functionality. | UX communicates denied state; verify Settings recovery on device. |
| Low | Debug `print` calls remain behind `#if DEBUG`. | Acceptable for release, but a logger would be cleaner. |

## Invalid Flow Coverage

- Onboarding skip: app still allows later Screen Time onboarding and Focus tab permission recovery.
- Permission denial: Screen Time denied state exposes Settings path; activation remains disabled.
- Permission revocation: app deactivates active Screen Time protection on foreground.
- Sweat reapplication: DeviceActivity monitor now reapplies shields for Sweat as well as Lock-in.
- Lock-in/Sweat bypass: shield action extension no longer lets users through hard modes just because daily goals are complete.
- Logout: active restrictions, user-scoped stores, local progress caches, and task reminders are cleared.
- Account switch: previous account data is cleared before the next account's fetches populate the app.
- Duplicate task completion: rapid duplicate mutations now ignored per task while a write is pending.
- Duplicate goal status/delete actions: rapid duplicate mutations now ignored per goal while a write is pending.
- Duplicate focus-day completion: repeated same-day streak writes are ignored while pending and rolled back on failure.
- Platform availability: initial release is iPhone-only to avoid unverified iPad/Mac/XR behavior.
- Empty task creation: rejected.
- Empty goal creation: rejected.
- Past reminder creation: ignored.
- Delete Account: server-side delete path now exists; deployment and production verification are still required.

## Data Integrity Risks

- Task and goal data use Supabase RLS migrations locally. Production must be verified against the live database.
- Local usage/streak/milestone caches are now cleared on sign-out for privacy. This avoids account-to-account leakage, but cross-device authoritative history should still live on the backend.
- Focus-day streaks still rely partly on local day strings and device calendar. Client-side duplicate writes and failed upserts are now guarded, but stronger abuse resistance still requires server-derived dates.
- Progress summaries are generated by an Edge Function with user-provided request data. Request size/type validation now limits abuse, but AI summaries must remain informational rather than authoritative.

## App Store Review Risks

- Apple may reject or delay review if Family Controls use is not clearly justified as the core feature.
- Apple may reject if permission prompts imply functionality is unusable unless permission is granted. The app now has skip/recovery paths, but metadata must be honest.
- Apple may reject if public legal URLs are missing in App Store Connect, even though in-app legal sheets now exist.
- Apple may reject if screenshots/metadata imply hard device control beyond what Screen Time APIs actually do.

## Future Scalability Concerns

- Split `ContentView.swift` into feature modules: tasks, progress, settings, live activities.
- Split `SupabaseManager.swift` into auth, task, goal, profile, progress repositories.
- Add dependency protocols for testability rather than direct global `supabase` usage.
- Add crash reporting, analytics event deduplication, and privacy-safe logging.
- Move streak/focus success authority to backend to reduce local-time manipulation.
- Add integration tests around task mutation rollback and focus activation state transitions.
