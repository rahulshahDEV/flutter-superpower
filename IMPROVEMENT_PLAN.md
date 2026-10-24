# Skill improvement audit and implementation plan

Scope: the reusable Flutter Superpower skill, its references, scaffold templates and tests.
The nested application factory is a separate project and was not redesigned in this pass.
Version: 2.9.0. Audit date: 2026-10-24.

## Findings and implemented corrections

| Area | Observed weakness | Correction |
|---|---|---|
| UI execution | Taste rules without a clear design-to-evidence loop | Brief, state inventory, vertical slice and visual verification workflow |
| Adaptive controls | Fixed button height, lost busy label/geometry, double-scaled gaps | Flexible controls, stable busy footprint/semantics, logical minimums, one scale |
| Typography | Runtime Google Font dependency and incomplete Material typography | Offline system baseline, TextTheme wiring, explicit bundled-font/licensing guide |
| Forms | Shared input could not validate or forward focus/autofill | Form-compatible input with required interaction APIs and a widget test |
| Startup | Undefined example types, default Firebase/portrait lock, timed splash | Template-backed ordered startup, opt-in integrations, visible failure, direct home |
| Permission/location flows | Generic permission table, conflated service/access failures, stale provider/health rules | Focused permission/capability/location/health guides with recovery and lifecycle tests |
| Platform UI | Missing system bar policy and modern orientation restrictions | Awaited edge-to-edge setup, explicit icon contrast, orientation/inset guide |
| Packages | Stale package list and incorrect SDK sharing claim | Source-based capability/compatibility evaluation and tested pubspec as baseline |
| Architecture | Contradictory core/router rule, duplicate provider examples | Explicit composition boundary, one owner per Cubit, lifetimes and preserved content |
| Data/errors | Lost Dio classification, silent bad-record filtering, raw error copy | Strict parsing, typed failure mapping, safe fallback and immutable snapshots |
| Security | Credential/body logging and preference token interceptor in starter | Unauthenticated baseline, secure-session guidance, no default payload logger |
| CI/CD | Thin/invalid snippets, signing/API-auth conflation, float toolchains | Focused Codemagic account/signing/workflows, fastlane, CI trust and artifact guides |
| OTA | Incomplete baseline targeting, staging, activation and recovery | Shorebird setup, explicit release/patch/track identity, promotion/rollback, CI |
| Native debugging | Short build checklist without runtime/platform ownership | Toolchain triage, crash/symbol diagnostics, bridge threading/lifecycle guidance |
| Agent tools | No discovery/runtime inspection loop | Optional official MCP and flutter_skill path; convert observations to tests |
| Reference follow-up | Stale layout-testing exclusion, duplicate-provider sample, minimal preview setup | Boundary-based testing guide, integration/preview recipes, adaptive state continuity |
| Verification | No regression coverage for these failures | Scaffold UI/network tests, generated-feature boundary tests, new behavioral cases |

## Implementation order

1. Audit shipped instructions against generated code and inspect primary platform/tool docs.
2. Correct generated behavior and explain ownership/decision rules in focused references.
3. Link every reference from SKILL.md and README, keep the entrypoint within its word budget.
4. Verify syntax, examples, installer, fresh app and feature generation; review contradictions.
5. Record evidence and limits. Commit/push only after the repository's private deny-list gate.

## Evidence and remaining limits

See evals/RESULTS.md for validation results. Static and scaffold checks establish those
specific behaviors; they don't establish native device, hosted account, store, or fleet OTA
operation. Behavioral evals need separate agent/baseline runs before claiming measured skill
improvement. No skill can diagnose an arbitrary incident without the relevant reproduction,
logs, symbols, hardware or access; the guides specify how to narrow that uncertainty.

Future improvements should be driven by failed evals and actual app outcomes rather than
adding more universal rules. Priorities: baseline comparisons, real-device platform coverage,
and a credentialed sandbox delivery rehearsal when those environments are available.

## Independent quality follow-through

The next pass corrected 10 concrete audit findings spanning installer containment/payloads,
existing-install preservation, false-success exit codes, command-result handling, relative
import scans, token storage, model update semantics, and contradictory scope/review rules.
Tests now include negative audit/release and installer contracts, and evidence has a frozen
matched baseline comparison (case 38). Both baseline/with-skill passed; no causal advantage
is claimed. A fresh Android debug scaffold also passed startup/rotation smoke checks.
Actual OS permission, iOS, credentialed signing/store and live OTA checks remain separate.

## Release privacy gate

The external private deny-list could not be located and was not run. After this limitation
was presented, the owner instructed continuation of the release. A best-effort scan of tracked
text for machine-specific paths, common credential shapes and known reference-app names
found no actual matches (the path detector definition was excluded). This is not a claim
that the unavailable private list passed.
