# Play Console In-Browser — Setup to Production

## 0. Invocation — "just ship it"

The user only says **"set up the store listing" / "ship it to internal testing" /
"take this to production"**. The agent does the rest — no step-by-step
hand-holding expected. On any such trigger:

1. Run the `release.md` checklist first (version, signing, artifact, URLs live).
   Red items become blockers reported up, never skipped.
2. Attach to the user's logged-in browser (§0.1) via the Playwright MCP (or any
   CDP-capable browser tool available). If no browser tool exists, say so
   immediately and fall back to `store-release.md` manual path.
3. Work §2 top-to-bottom, applying §3 rules, until the requested gate is green:
   "internal" stops at §4, "production" continues through §5.
4. Report per §Evidence; blockers as Blocked / Evidence / Needs / Default.

### 0.1 Attach to the logged-in browser

1. Confirm the browser binary and its profile dir (default profile holds the login).
2. Quit the browser, relaunch it with remote debugging on the **same profile**:
   `--remote-debugging-port=9222 --user-data-dir=<PROFILE_DIR>
   --profile-directory=Default <CONSOLE_URL>`.
3. Verify: `curl localhost:9222/json/version` returns browser JSON.
4. Connect Playwright over CDP (`connect_over_cdp`), never launch a fresh browser.
   Isolated contexts always land on the Google sign-in wall — that means you
   attached wrong, not that the user must log in again.
5. Keep a private venv for the driver scripts outside the repo (`/tmp` is wiped
   on reboot — recreate it; scripts themselves stay out of the skill).

## 1. Pre-flight evidence (local, before touching Console)

- `pubspec.yaml` version `X.Y.Z+N` → Android `versionCode = N`.
- Release signing configured (`key.properties` + keystore, gitignored).
- Built artifact exists: `flutter build appbundle --flavor <flavor>`.
- `AndroidManifest.xml` permissions inventoried (each one must be defensible in
  Data safety + declarations).
- Privacy-policy and contact/deletion URLs probed with `curl -L` — anything not
  HTTP 200 is fixed **before** review, never during.

## 2. Section order (cheapest first, gates last)

Dashboard → View tasks exposes the setup list. Complete in this order:

1. Privacy policy, Ads, Government, Financial, Health, Advertising ID — one
   screen each, mostly No/None. Dismiss the "send for review" dialog each time.
2. Content rating (IARC): pick the honest category (Social vs Communication),
   answer block/report/location/purchase questions from the **code**, not guesses.
3. Sign-in details **before** Target audience (Console blocks the latter until
   the former is saved). Provide a real reviewer account; open registration
   still needs written access instructions.
4. Target audience (age bands drive which follow-ups appear; 18+ skips most).
5. Data safety (5 steps: Overview → Collection/security → Types → Usage →
   Preview). Derive types from the manifest + SDKs + backend, never from memory.
6. Child safety standards — mandatory for social/dating: live standards URL,
   contact email, both compliance boxes.
7. Store settings: category + contact email/website.
8. Store listing texts first (name 30 / short 80 / full 4000), graphics when the
   owner supplies them (icon 512², feature 1024×500, 2–8 phone screenshots).

After every save, re-read the App content summary: `Need attention` must shrink.
Track unlocks are gated on setup completion — internal testing needs the least.

## 3. Form-fighting rules (learned the hard way)

- Tutorial carousels block pointer events: click through every dot (or
  force-click the modal button via JS) before touching the form.
- Category accordions collapse on navigation: assert state via counters
  (`5/9 data types selected`), never via "was expanded".
- Play validates URLs live (404 warning inline): swap dead links for a live one
  immediately and flag the site fix — review **will** fail on dead links.
- Duplicate/ambiguous controls: scope locators to `[role=dialog]` or the open
  pane; match rows by their own short label, never by header text.
- Disabled Save means an unanswered required question — screenshot, read, answer.
- Prefer accessible-role locators; drop to JS `elementFromPoint` + overlap check
  only when the framework markup defeats roles.

## 4. Ship to Internal testing

1. `versionCode` must exceed every code ever uploaded (Console → Releases →
   Latest bundles). Bump pubspec `+N` and rebuild — Play rejects reused codes.
2. New apps must upload **AAB** (APK is rejected); keep an APK only for sideload.
3. Create release on the Internal track → upload AAB → release notes → save.
4. Testers tab → new email list (`<GROUP>`) → add addresses → rollout.
5. Hand over the opt-in link; verify install + login + one core flow on device.

## 5. To production

11/11 setup tasks green (listing graphics are mandatory here, not for
internal), promote internal → closed → open → production with staged rollout;
watch Android vitals before ramping. Review outcomes and device installs are
manual — report as Not verified unless actually done.

## Evidence before claiming done

Per section: page URL + saved-state text (`Change saved`, counters, summary
`Need attention` count) + screenshot path. Blockers reported as
Blocked / Evidence / Needs / Default-you-would-use, never silently skipped.
