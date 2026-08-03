# Spike AI — Launch Runbook (iPhone + iPad)

Date drafted: 2026-05-28
Target: App Store submission for iPhone **and** iPad
Project bundle id: `com.spikeai.spikeai`
Family Controls extensions: `.shield`, `.shieldaction`, `.monitor`
Live Activity extension: `.liveactivity`

This runbook covers everything that must happen outside the source code before
Spike AI can be submitted to the App Store. Work top-down. Steps marked
**[BLOCKER]** must complete before submission. Steps marked **[PARALLEL]** can
run alongside other work.

---

## 0. Code-level audit summary (what I already did)

- ✅ `Info.plist` and project `INFOPLIST_KEY_*` settings have iPad-correct
  orientation, scene manifest, and indirect input event configuration.
- ✅ Codebase already has full iPad layout adaptivity through
  `DeviceLayout.isPad`, `iPadReadable(maxWidth:)`, and dual sizing in
  Onboarding, Auth, and Content views.
- ✅ Live Activity correctly `guard`s on `iOS 16.2+` and no-ops on devices
  without ActivityKit (incl. iPad).
- ✅ Entitlements complete: Family Controls, Sign in with Apple, App Groups
  (`group.com.spikeai.spikeai` plus legacy `group.Mirzo-Ulugbek-Fazilov.Linear`
  for migration of existing installs).
- ✅ `PrivacyInfo.xcprivacy` declares no tracking, required UserDefaults
  reasons (`CA92.1`, `1C8F.1`), and collected data types (email, user id, name,
  product interaction, user content) all marked `AppFunctionality`, none
  linked to tracking.
- ✅ Edge Functions (`delete-account`, `generate-progress-summary`,
  `translate-quote`) are well-structured: input validation, fail-closed env
  checks, CORS, fallback paths.
- ✅ Migrations: every user-owned table has RLS enabled with scoped policies.
- ✅ Added missing migration `20260528000000_quote_translations.sql` — the
  `translate-quote` function was reading/writing this table but no migration
  created it. Without this, the function would fail in production.

No further code edits are needed before TestFlight. The remaining work is
outside the source tree.

---

## 1. [BLOCKER] Apple-side entitlement & account work

Order matters here — Apple's reviews are not instant.

### 1.1 Submit the Family Controls entitlement request
1. https://developer.apple.com/contact/request/family-controls-distribution
2. Choose the Spike AI App ID (`com.spikeai.spikeai`).
3. **Use this justification** (Apple reads this carefully — be specific about
   personal-use-only and per-user opt-in):
   > Spike AI is a personal productivity app where the user opts into focus
   > modes to restrict their own distracting apps. Family Controls is used
   > solely to: (a) collect the user's own Screen Time selection of apps,
   > categories, and web domains via `FamilyActivityPicker`; (b) apply the
   > resulting `ManagedSettingsStore` shield to the user's own device when
   > the user activates Focus, Lock-In, or Sweat mode; (c) reapply or clear
   > shields through `DeviceActivityMonitor`. No data leaves the device about
   > which apps the user selected — we only hold Apple's opaque tokens.
   > There is no parental control, no employee monitoring, no MDM-style use,
   > and no cross-account or remote control of any kind.
4. Mention that the app is iPhone + iPad universal.
5. Expect 1–4 weeks. Status checks: developer.apple.com/account.

### 1.2 Provisioning profiles
After approval, in developer.apple.com → Profiles, regenerate distribution
profiles for **all five targets**:
- `com.spikeai.spikeai` (App Store)
- `com.spikeai.spikeai.shield` (App Store)
- `com.spikeai.spikeai.shieldaction` (App Store)
- `com.spikeai.spikeai.monitor` (App Store)
- `com.spikeai.spikeai.liveactivity` (App Store)

All five must include the Family Controls entitlement except liveactivity
(which only needs App Groups + ActivityKit).

### 1.3 App Store Connect record
- developer name + display name "Spike AI"
- Primary language: English
- Bundle ID: `com.spikeai.spikeai`
- SKU: `spike-ai-ios-v1`
- Category: Primary = Productivity, Secondary = Health & Fitness
- Pricing: Free
- Availability: all territories (or restrict during launch)

---

## 2. [BLOCKER] Supabase production work

### 2.1 Auth redirect URLs
In Supabase dashboard → Authentication → URL Configuration:

```
Site URL:               https://mirzoulugbekfazilov.github.io/SpikeAI-website
Additional Redirect URLs:
  spikeai://login-callback
  linear://login-callback    (keep for legacy installs during migration)
```

### 2.2 OAuth providers
- Google: redirect URI in Google Cloud → OAuth client → must include
  `spikeai://login-callback`.
- Apple: configured via "Sign in with Apple" service ID. Confirm domain
  associations are still valid.

### 2.3 Deploy database migrations
```bash
cd "/Users/mirzo-ulugbekfazilov/Desktop/Spike AI/SpikeAIProject"
supabase link --project-ref <your-prod-ref>
supabase db push
```
This will apply the new `20260528000000_quote_translations.sql` along with
any other pending migrations.

### 2.4 Deploy Edge Functions

```bash
# Requires Docker Desktop running locally for supabase-cli.
supabase functions deploy delete-account
supabase functions deploy generate-progress-summary
supabase functions deploy translate-quote
```

### 2.5 Set function secrets
```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
supabase secrets set HF_TOKEN=<your-huggingface-token>
```

> `SUPABASE_URL` and the publishable key are injected automatically by the
> platform — you do not need to set those.

### 2.6 Verify production security
Run Supabase advisors and fix anything flagged red:

```bash
supabase db lint
# Then in dashboard: Database → Advisors → run Security + Performance audits
```

Manual checks to confirm:
- [ ] RLS is enabled on `profiles`, `tasks`, `goals`, `focus_days`,
      `coaching_messages`, `progress_summaries`, `quote_translations`.
- [ ] No publicly-readable tables besides the public-profile slice.
- [ ] `delete-account` actually deletes a test user's auth record + cascades
      through dependent tables. Test with a throwaway email.

### 2.7 Smoke test from `curl`
Replace `<jwt>` with a real session JWT from a signed-in test user.

```bash
# generate-progress-summary should respond 200 with a summary object
curl -X POST "https://<your-ref>.supabase.co/functions/v1/generate-progress-summary" \
  -H "Authorization: Bearer <jwt>" \
  -H "Content-Type: application/json" \
  -d '{
    "period_start":"2026-05-21",
    "period_end":"2026-05-27",
    "current_streak":3, "best_streak":7,
    "monthly_consistency_percent":62,
    "monthly_focus_days":12, "monthly_missed_days":7,
    "completed_tasks":["Inbox zero"], "missed_tasks":[],
    "screen_time_trend":"down 12%", "average_screen_time_minutes":180,
    "goals":["Ship Spike AI"], "language":"en"
  }'
```

```bash
# translate-quote should respond 200 with translated_text + translated_author
curl -X POST "https://<your-ref>.supabase.co/functions/v1/translate-quote" \
  -H "Authorization: Bearer <jwt>" \
  -H "Content-Type: application/json" \
  -d '{"quote_index":1,"text":"Discipline equals freedom","author":"Jocko Willink","language":"es"}'
```

```bash
# delete-account — use a THROWAWAY test account. This is irreversible.
curl -X POST "https://<your-ref>.supabase.co/functions/v1/delete-account" \
  -H "Authorization: Bearer <test-account-jwt>"
```

---

## 3. [BLOCKER] Local Xcode build & archive

You previously hit a `clang -v -E -dM` env-probe stall. To unblock:

```bash
sudo xcode-select --reset
sudo xcode-select -s /Applications/Xcode.app
xcrun --find clang   # should print a path, no stall
xcodebuild -version  # confirm tooling
```

If still stalled:
```bash
sudo rm -rf ~/Library/Developer/Xcode/DerivedData
# Then quit Xcode, reopen, let it re-index, try again.
```

Then in Xcode:
1. Open `Spike AI.xcodeproj`.
2. Select scheme `SpikeAI` → Any iOS Device (arm64).
3. Product → Archive.
4. Distribute → App Store Connect → Upload.
5. The archive must validate without warnings about Family Controls,
   privacy manifest, or missing icons.

---

## 4. [PARALLEL] Real-device QA matrix

You must do this on hardware. Simulators do not exercise Family Controls
correctly.

### 4.1 Devices
- iPhone (small): iPhone SE 3 or iPhone 13 mini
- iPhone (Dynamic Island): iPhone 15 Pro or 16/16 Pro
- iPad: any current iPad (11" iPad Air or iPad Pro 13" recommended)

### 4.2 Golden-path test, per device
1. Fresh install from TestFlight.
2. Onboarding: language, sign in with Apple, sign in with Google, email
   magic link via `spikeai://login-callback`.
3. Grant Screen Time → pick 3 distracting apps and 1 category.
4. Switch through all four modes: Chill → Focus → Lock-in → Sweat.
5. In Lock-in, try opening a blocked app — confirm shield appears.
6. In Sweat, do a verified rep — confirm 1-minute unlock window.
7. Schedule a task with a reminder 2 minutes out — confirm notification fires
   with default sound (not critical-alert).
8. Generate a weekly progress summary — confirm 200 from Edge Function.
9. Enable Live Activity on iPhone — verify it appears on lock screen.
   On iPad: confirm the toggle either hides or is disabled (no broken UI).
10. Force-quit the app — re-open — confirm shields still hold.
11. Restart the device — confirm shields still hold.
12. Cross the midnight boundary while a mode is active.
13. Revoke Screen Time in Settings — re-open app — confirm shields cleared
    and user sees the recovery flow.
14. Sign out — sign back in with a different account — confirm previous
    user's tasks/goals/streaks do not appear.
15. Delete account — confirm Supabase user is actually gone (admin
    dashboard).

### 4.3 iPad-specific
- All onboarding screens render at iPad readable width without truncation.
- Modes screen layout is balanced (no wide empty spaces or cut-off text).
- Sweat Mode camera preview is correctly oriented in both landscape and
  portrait.
- Live Activity toggle is gracefully hidden or labelled "iPhone only".
- Split View and Slide Over: app at least doesn't crash. (Family Controls
  is single-app, so multi-tasking just shouldn't break the UI.)

### 4.4 Edge cases
- Notifications denied: Chill mode should still show in-app reminders.
- Camera denied: Sweat mode should refuse activation with a clear message.
- Network offline: queued mutations sync when network returns.
- Background fetch during DeviceActivity window: shields reapply.

---

## 5. [BLOCKER] App Store Connect submission package

### 5.1 Required URLs (already hosted)
- Privacy Policy: https://mirzoulugbekfazilov.github.io/SpikeAI-website/privacy.html
- Terms & Conditions: https://mirzoulugbekfazilov.github.io/SpikeAI-website/terms.html
- Support URL: https://mirzoulugbekfazilov.github.io/SpikeAI-website/support.html
- Marketing URL: https://mirzoulugbekfazilov.github.io/SpikeAI-website/

Make sure GitHub Pages is enabled on the `main` branch of
`MirzoUlugbekFazilov/SpikeAI-website` (Settings → Pages → Source: `main` /
`/(root)`).

### 5.2 App Privacy questionnaire (matches PrivacyInfo)
Data collected, all "Linked to user", none used for "Tracking":
- Contact info → Email Address — App Functionality
- Identifiers → User ID — App Functionality
- Contact info → Name — App Functionality
- User Content → Other User Content — App Functionality, Product
  Personalization
- Usage Data → Product Interaction — App Functionality, Product
  Personalization

Data NOT collected: location, contacts, browsing history, financial,
health, biometric, search history, sensitive info, purchases, audio,
photos/videos, gameplay content, customer support content, advertising
data, performance data, other diagnostic data.

### 5.3 Age rating
- 4+ (no objectionable content)
- "Unrestricted Web Access" = No
- "Gambling and Contests" = No

### 5.4 Review notes (paste into "Notes to Reviewer")
> Spike AI is a productivity app that helps the user limit their own use
> of distracting apps. Sign-in is via Apple Sign-In, Google Sign-In, or
> email magic link. To exercise the focus features the reviewer needs to
> grant Screen Time access when prompted.
>
> Test account: <reviewer-test-account@email>
> Password: <if applicable — magic-link accounts do not need a password,
> explain how to receive the magic link in your TestFlight environment>
>
> Family Controls is used exclusively for the signed-in user's own device
> to: collect their own app selection via `FamilyActivityPicker`, apply
> `ManagedSettingsStore` shields they configured, and reapply via
> `DeviceActivityMonitor` background callbacks. No parental, employer,
> MDM, or remote-control use exists.
>
> Sweat Mode uses the front camera with Apple's Vision body-pose API
> entirely on-device. No frames leave the device.
>
> Live Activity is iPhone-only and is conditionally compiled behind the
> ActivityKit availability check.

### 5.5 Screenshots
Required sizes (Apple's current minimums for universal apps):
- iPhone 6.9" (iPhone 16 Pro Max) — 1320×2868
- iPhone 6.5" (iPhone 14 Plus) — 1242×2688
- iPad Pro 13" (M4) — 2064×2752
- iPad Pro 12.9" (3rd–6th gen) — 2048×2732

At least 3 screenshots per size class; 6 is ideal. Tip: use real device
recordings, not Figma mockups — Apple sometimes rejects mockup-only
screenshots when the UI doesn't match the build.

### 5.6 Demo video (optional but recommended for Family Controls apps)
A 15–30 second App Preview that shows: pick distracting apps → toggle
Lock-in → try to open a blocked app → see the shield. This single
sequence is the most common Apple-rejection-defuser for Family Controls
apps.

---

## 6. [PARALLEL] iPad-or-not decision gate

The current build settings include iPad (`TARGETED_DEVICE_FAMILY = "1,2"`),
and the codebase has full iPad layout adaptivity. So shipping universal is
**technically supported** — but ASC requires:
- iPad screenshots (see 5.5).
- Confirmation that Family Controls behaves identically on iPad in your
  real-device QA (Section 4.3).
- Live Activity toggle gracefully hidden on iPad (verify in 4.3).

If any of those slip, fall back to iPhone-only for v1.0 by changing
`TARGETED_DEVICE_FAMILY = "1,2"` → `"1"` on all targets and rebuilding.

---

## 7. [PARALLEL] Pre-submission final checklist

Before clicking Submit for Review:

- [ ] Family Controls entitlement approved by Apple
- [ ] All distribution provisioning profiles regenerated
- [ ] Migration `20260528000000_quote_translations.sql` applied to prod
- [ ] All three Edge Functions deployed
- [ ] `SUPABASE_SERVICE_ROLE_KEY` and `HF_TOKEN` set as function secrets
- [ ] Supabase advisors green
- [ ] Auth redirect URLs include `spikeai://login-callback`
- [ ] OAuth providers updated
- [ ] Clean archive uploaded to App Store Connect
- [ ] Build passes TestFlight processing (no privacy-manifest warnings)
- [ ] Privacy/Terms/Support URLs all return 200 on github.io
- [ ] App Privacy questionnaire submitted
- [ ] Age rating set
- [ ] Review notes pasted (includes test account)
- [ ] Screenshots uploaded for iPhone 6.9", 6.5", iPad 13" or 12.9"
- [ ] Real-device QA matrix (Section 4) all green on at least one of each
      device class
- [ ] `delete-account` Edge Function verified working with a throwaway
      account
- [ ] Sweat-mode camera tested on real device
- [ ] Live Activity tested on real iPhone

---

## 8. Post-launch (week 1)

- Monitor App Store reviews daily; respond to bug reports within 24h.
- Watch Supabase function logs for 5xx spikes.
- Confirm streaks survive the first user-experienced midnight rollover
  across timezones.
- If you decide to add crash analytics in v1.1, TelemetryDeck is the
  simplest privacy-label story; Sentry has richer breadcrumbs but needs
  three extra entries in the App Privacy section.

---

## Rollback plan

If a critical bug is found after submission but before approval:
- Reject the binary in App Store Connect ("Remove this build").
- Fix → re-archive → upload new build.

If a critical bug is found after approval is granted (live in production):
- Phased Release (set to 1 day) gives you a 24h window to halt rollout.
- Halt Phased Release in App Store Connect if needed.
- Use Expedited Review (https://developer.apple.com/contact/app-store/?topic=expedite)
  with a specific user-impact statement.

If Supabase has a data issue:
- All migrations are idempotent — re-running is safe.
- Edge Function rollbacks: `supabase functions deploy <name>` against a
  prior git ref.
