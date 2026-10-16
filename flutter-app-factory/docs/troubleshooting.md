# Troubleshooting

## `flutter: command not found`

Install Flutter stable and reopen the shell. `create`, `test`, and local
`build --execute` need it; `validate`, `metadata`, `release` (plan), and
`status` do not.

## `create` says the identifier collides

The derived `org + slug` matches another app's flavor ID. Pick a different
slug or org. List the registry first: `factory.py list`.

## `create` says configuration was preserved

The directory exists with different name/identity. Inspect
`apps/<slug>/app.yaml`; resume that app or remove the directory deliberately
(never blindly) before retrying.

## `validate` fails on `com.example` / `REPLACE_ME`

Expected before real identities exist. Set the real org at creation for
publishable apps, fill `team_id`, `codemagic_app_id`,
`app_store_connect_integration`, `apple_app_id`, AdMob prod IDs, `policy_url`,
and mark `assets.reviewed` / `store_declarations_reviewed` only after genuine
review. Development validation never proves release readiness.

## `test` fails in `flutter analyze` / `flutter test`

Run the failing command inside the reported package or app directory and fix
the code — do not weaken the gate. Shared-package failures block every app.

## `init` / export errors

- `Destination exists` — choose an empty new directory.
- `Export outside the starter directory` — the destination must not be inside
  the factory root.
- `Missing maintained export manifest` — `automation/export-manifest.txt` must
  exist; add new starter files to it when they are created.
- `unsafe path` — the manifest must never list credentials, keystores,
  provisioning profiles, or env files with real values.

## `ci-trigger` / `status --provider codemagic` fail

Needs `CODEMAGIC_API_TOKEN` in the environment and a real
`deployment.codemagic_app_id`. Triggering spends paid minutes and requires
explicit authorization. Timeouts: reconcile the existing build ID first,
never retrigger blindly.

## macOS path confusion (`/var` vs `/private/var`)

The CLI resolves symlinks before comparing paths. Always pass real paths;
when scripting, prefer `realpath`. Temp directories are affected most often.

## Publishing adapter errors

`play`/`apple` write actions need credentials plus explicit authorization
flags, production targets need fresh approval, and mismatched app IDs,
unsigned artifacts, or unknown versions are rejected before any network call.
A local receipt or accepted upload is not proof of store availability —
verify track/tester state in the consoles.

## Stale `codemagic.yaml`

Regenerate after app, flavor, or deployment changes:
`factory.py ci-generate`. Never hand-edit the generated file.
