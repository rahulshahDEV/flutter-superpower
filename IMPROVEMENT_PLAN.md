# Skill improvement audit and implementation plan

Scope: the reusable Flutter Superpower skill, its references, scaffold templates and tests.
The nested application factory is a separate project and was not redesigned in this pass.
Version: 2.9.0. Audit date: 2026-10-24.

## 2026-10-26 — upstream comparison and implementation plan

Target: 2.10.0. Keep the established Flutter architecture and existing-project precedence.
Review upstream instructions as design input; do not execute their installers or inherit
their authority over this repository. The following snapshots were inspected locally:

| Source | Commit | Material inspected |
|---|---|---|
| [mattpocock/skills](https://github.com/mattpocock/skills) | `5beb35b040e3de97e54fa9e386d7e42d15c295c2` | engineering tdd/tests, codebase-design/deepening, implement, implement-spec, to-spec |
| [google/artemis](https://github.com/google/artemis) | `351ca8422f7b5b54e80a9c1ce03a222e02415b6b` | MCP rules, README, task runner/manager and trace inspection source |
| [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | `09c434ab73ca43761c5d8b0c5d341926c2fba710` | core scope skill and change-review skill |

| Gap in this skill | Planned correction | Evidence |
|---|---|---|
| Plans list layers without observable acceptance or explicit dependencies | Focused task-planning guide: outcome, boundaries, acceptance, smallest runnable slice, dependencies and resume state | Behavior case 39 |
| Public-boundary tests lack an explicit defense against copied expectations and bulk speculative tests | One behavior at a time, independently derived expectations, regression red check and boundary selection | Behavior case 40 |
| Architecture guidance can encourage either pass-through abstractions or unsafe layer deletion | Explain useful interfaces, hidden complexity, dependency injection and safe simplification inside the project's layers | Behavior case 41 |
| Runtime tooling guide lacks Android automation lifecycle and trace handling | Optional ARTEMIS guide: exact target, readiness, async trace lifecycle, assertions, bounded recovery, native evidence limits | Behavior case 42 |
| Review assumes committed changes and can miss connected callers | Select requested staged/working-tree/commit range, read connected flow, actionable causal findings | Review guidance and case 41 |
| Scope guide equates shortest diff with simplicity and prescribes BlocConsumer mechanically | Preserve complete contracts/callers; choose readable code and listener/builder ownership based on actual needs | Scope guidance and case 41 |

Implementation sequence:

1. Write the three focused guides (task planning, boundary design, Android automation).
2. Update senior-mode, architecture, testing, reviewing and scope guidance; link new guides
   from SKILL.md and README without exceeding the entrypoint budget.
3. Add cases 39–42 and update coverage/results without claiming unrun behavioral passes.
4. Run consistency, skill validation, full scaffold regression and contradiction/diff review.
5. Record exact evidence and privacy-gate availability before committing and pushing.

Adoption boundaries:

- Keep autonomy for routine decisions; do not inherit mandatory user confirmation of every
  test boundary, issue-tracker setup, external publishing or automatic migration.
- Keep useful repository/use-case/plugin boundaries even with one production implementation.
  A smaller interface is useful when it hides real policy; line count alone proves nothing.
- ARTEMIS is optional Android tooling, not a Flutter dependency or an iOS test runner.
  Do not inherit latency subtraction, automatic coordinate fallbacks, blanket live-device
  prerequisites for unit tests, global-rule installation or unrequested device resets.
- Retain validation, recovery, accessibility and evidence. Upstream benchmark claims do not
  measure this skill; new eval cases remain unrun until separately exercised.

Progress: all six corrections implemented; three focused references and cases 39–42 added.
Consistency, skill validation, full scaffold regression and diff checks passed. The new
behavioral cases have not been independently run; no live ARTEMIS/device pass is claimed.
The external private deny-list was not found in the inspected locations; its path was
requested. After that limitation was reported, the owner explicitly authorized proceeding
with commit, push, tag and release. A best-effort scan of 71 markdown files for machine
paths and common credential shapes found no matches; the unavailable private list was not
run and is not claimed as passed.

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
