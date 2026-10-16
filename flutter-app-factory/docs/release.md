# Release guide

Testing targets: `play-internal` (Google Play internal track) and
`testflight` (TestFlight). There is no public-production target in the CLI:
production is prepared as a reviewable action and needs fresh explicit
approval. A plan is never a build; a build is never proof of deployment.

## 1. Prepare

```bash
python3 automation/scripts/factory.py release battery_analyzer --version 1.2.0 --build-number 12 --targets play-internal,testflight
```

This validates the project (release-validator: analyze, tests, flavors, IDs,
version, AdMob isolation, privacy declarations, signing requirements, store
metadata, assets), bumps `version`/`build_number` in `app.yaml` and
`pubspec.yaml`, generates notes from the journal, and writes a plan plus a
resumable journal ID under `.factory/`. Critical failures block the plan.
Review the printed plan: workflows, commit, version, destinations.

## 2. Execute (authorized testing only)

Only when the owner has authorized this testing deployment and its CI cost:

```bash
python3 automation/scripts/factory.py release battery_analyzer --version 1.2.0 --build-number 12 --targets play-internal,testflight --execute --authorize-testing
```

The flags attest to authorization already given; they do not create it.
Execution triggers the matching `*-prod-android-internal` /
`*-prod-ios-testflight` Codemagic workflows and records build IDs.

## 3. Track

```bash
python3 automation/scripts/factory.py status --provider release --id RELEASE_ID
python3 automation/scripts/factory.py status --provider codemagic --id BUILD_ID
```

Poll with bounded backoff; never retrigger because a poll timed out —
reconcile the existing build first. Verify workflow, commit, version, and
target on every status read.

## 4. Confirm deployment

CI success ends the journal's visibility. Confirm each platform separately:

```bash
python3 -m automation.publishing.play --help
python3 -m automation.publishing.apple --help
```

Play status inspects a supplied edit or local receipt; Apple status queries
build processing and beta details. Neither is proof a tester can install the
build — check track/tester state in the consoles for that. Do not re-upload
through an adapter what CI already delivered.

## 5. Production

Prepare the same way, then stop: present the concrete action (app, version,
build, artifact hash, destination) and require fresh explicit approval
immediately before the production mutation. Store review cannot be bypassed;
rejections are addressed in metadata or binary and re-planned, never forced.

Manual prerequisites live in `docs/credentials.md`,
`docs/android-publishing.md`, and `docs/ios-publishing.md`.
