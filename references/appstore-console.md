# App Store Connect In-Browser — Setup to Production

Mirror of `play-console.md` for Apple. Same invocation contract: the user only
says **"ship it to TestFlight" / "submit for review" / "take this to the App
Store"** — the agent runs `release.md`, attaches to the user's logged-in
browser (§1), works top-to-bottom, and reports evidence. No hand-holding.

## 1. Attach to the logged-in browser

Identical to Play: quit the user's Safari/Chrome, relaunch on the **same
profile** with remote debugging, connect Playwright over CDP. Isolated contexts
land on the Apple ID wall — that means wrong attachment, not a login task.
`store-release.md` App Store section is the manual fallback.

## 2. Pre-flight evidence (local)

- `pubspec.yaml` `X.Y.Z+N` → Xcode `CFBundleShortVersionString` = X.Y.Z,
  `CFBundleVersion` = N (must rise on **every** upload, even same version).
- Bundle ID + team set; `flutter build ipa` (or `fdev ios prod`) artifact exists.
- Privacy manifest + purpose strings present for every permission the app uses.
- Support URL, marketing URL, privacy-policy URL all HTTP 200 (probe first).
- Demo account ready if login is required (reviewers use what you give them).

## 3. Section order (cheapest first, gates last)

My Apps → + → New App (platforms, name ≤30, language, bundle ID, SKU):

1. App Information: category, content rights, age-rating questionnaire (answer
   from the code: gambling? contests? user-generated content? messaging?).
2. Pricing and Availability: price tier, regions, pre-order if wanted.
3. App Privacy: nutrition labels per data type — purposes (functionality,
   analytics, personalization), linked-to-user yes/no, tracking yes/no (ATT).
   Must match code + SDKs; mismatches are the #1 rejection.
4. Screenshots + app previews per required device class (6.9"/6.5" iPhone, iPad
   if supported), subtitle ≤30, keywords ≤100, description.
5. Version release: manual vs automatic, phased release (7-day) for updates.
6. Review contact + demo account + notes (anything non-obvious: hidden gestures,
   test numbers, backend staging quirks).

## 4. TestFlight first, always

Internal group (≤100, no review) → install, smoke-test push, deep links,
purchases, login. External group (≤10 000) needs beta review — submit the same
build you intend to ship. Never submit to review a build no human has installed
from TestFlight.

## 5. Submit for review

App Store → + Version → fill What's New → Submit. Typical review 24–48 h.
Frequent rejections: broken demo account (**2.1**), purpose strings / undeclared
collection (**5.1.1**), digital goods outside IAP (**3.1.1**), third-party login
without Sign in with Apple (**4.8**), hidden features (**2.3**). Answer in the
Resolution Center with evidence, never with promises.

## 6. Form-fighting rules

Same as Play: tutorial/carousel overlays first, assert state via counters not
expansion, scope locators to the open sheet, screenshot every gate, live URLs
only. Apple-specific: expired distribution profiles and stale API keys fail
silently at upload — re-verify signing right before the release build.

## Evidence before claiming done

Per section: page + saved-state text + screenshot. External facts (review
times, installs, TestFlight feedback) are Not verified unless actually
observed. Blockers as Blocked / Evidence / Needs / Default.
