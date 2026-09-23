# Evaluations — behavior tests for the skill

These test **behavior**, not whether a string exists in `SKILL.md`. An agent passes a case only
if the produced diff and report satisfy every `Must`, violate no `Must-not`, and the verify
commands pass.

## Protocol

1. **Deterministic base** — scaffold a throwaway app so every run starts identical:

   ```bash
   scripts/new_app.sh eval_app --dir /tmp/eval_app --title "Eval App"
   ```

   For cases that need a defect or a second feature, apply the case's *Setup* first
   (small, scripted edits described in the case).

2. **Run the agent** — in `/tmp/eval_app`, give the agent the case's *Task* verbatim, with the
   skill installed. Do not hint at the expected implementation.

3. **Verify** — run the case's `Verify` commands, then inspect the diff against `Must` /
   `Must-not`. A green analyze/test run does not by itself pass a case.

4. **Score** — PASS requires all of:
   - every `Must` observable in the diff,
   - no `Must-not` present,
   - `Verify` commands green,
   - the agent's report contains the evidence block (Implemented / Files changed /
     Verification / Not verified).

5. **Record** — case id, date, model, pass/fail, and the exact violation when failing.
   Failures are skill bugs: fix the reference the agent should have followed, then re-run.

## Case index

| # | Case | Primary reference under test |
|---|---|---|
| 01 | New feature end to end | playbooks, architecture |
| 02 | Add an API endpoint | networking-and-errors |
| 03 | Google sign-in flow | auth-social |
| 04 | Fix a cubit bug | debugging, state-and-di |
| 05 | Fix a routing bug | routing |
| 06 | Refactor a giant screen | ponytail, senior-mode |
| 07 | Add pagination | state-and-di, performance |
| 08 | Handle an API failure | networking-and-errors |
| 09 | Loading/empty/error states | theme-and-design-system |
| 10 | Add a reusable widget | theme-and-design-system, ponytail |
| 11 | Fix an architecture violation | architecture, senior-mode |
| 12 | Debug an Android build issue | native |
| 13 | Debug an iOS build issue | native |
| 14 | Firebase notification flow | app-bootstrap, native |
| 15 | Modify a shared repository | senior-mode (impact analysis) |
| 16 | Add missing tests | testing |
| 17 | Optimize a slow screen | performance |
| 18 | Reject an unnecessary dependency | dependencies, ponytail |
| 19 | Implement localization | localization |
| 20 | Tablet/responsive layout | accessibility, performance |

## Honest limits

- Evals require an agent under test; there is no automated judge. The protocol is manual by
  design — the checks are objective, the running is not.
- Keep cases independent: one behavior each, small enough to review in one diff.
