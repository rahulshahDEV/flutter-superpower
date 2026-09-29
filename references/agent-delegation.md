# Parallel Agent Delegation

Use sub-agents to shorten repository exploration and broaden reviews when the editor offers
them. The lead agent still owns the plan, shared changes, verification, and final report.

## Decide whether to fan out

- First check whether the current editor/session actually provides parallel agents and how
  many can run at once. Do not assume a particular editor, tool name, or agent limit.
- Parallelize large repository profiles, broad audits, and reviews that split into distinct
  questions. Give each worker a bounded, independent area and a read-only task by default.
- Use as much available concurrency as there are useful independent tasks. Do not create
  extra workers for a small or sequential task, duplicate the same scan, or split work so
  finely that integration costs more than it saves.
- If agents are unavailable, continue with the same checklist as sequential passes. Do not
  install a plugin, switch editors, or pause the task just to obtain agents.

## Give every worker a clear contract

Each task states:

- the question or review axis it owns;
- the files, feature, or diff range in scope;
- whether the task is read-only or may edit a disjoint set of files;
- the evidence to return: paths and line references, concrete behavior, severity/confidence,
  and unresolved questions.

Do not give two workers the same broad assignment. For exploration, split by architecture
area (for example state/DI, networking/data, routing/native configuration, or tests/UI). For
review, keep Standards and Spec axes separate; add security, performance, or platform passes
only when the diff warrants those independent questions.

## Keep ownership and integrate evidence

- During exploration and review, workers report findings; they do not modify the shared tree.
  If implementation is explicitly delegated, assign non-overlapping files and have the lead
  inspect the resulting diff.
- Workers do not contact the user, publish changes, commit, push, or perform other external
  actions. The lead handles user communication and side effects under the user's request.
- The lead reconciles overlapping claims, checks high-risk findings against source and tests,
  and reports disagreements or unknowns instead of hiding them. Do not repeat every agent
  summary; deliver one concise, evidence-backed result.
- Keep agent output scoped to the question. Parallel work does not replace the lead's
  project profile, self-review, verification, or final ownership.
