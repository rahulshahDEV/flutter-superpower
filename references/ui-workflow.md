# UI Implementation Workflow

Use for a new screen, substantial redesign, or shared component change. For a small fix,
apply only the affected steps. Respect supplied designs and existing product conventions.

## Decide before widgets

Write a short implementation brief in the task plan: user job, primary action, content
priority, supported widths/locales/themes, reference design, and reachable states. Infer
reasonable defaults from the app; ask only about a product decision that blocks progress.
For a supplied design, inventory its hierarchy, type roles, spacing, assets, and interaction
states before reproducing it. For a new design, choose a coherent direction tied to the job;
"polished" is not a specification. Do not impose the same card dashboard on every product.

Describe behavior for initial loading, content, empty, error/retry, refresh with existing
content, submitting, disabled, and permission/offline states only where reachable. State
which content remains visible during refresh/failure. Define back, cancellation, and focus
behavior. A beautiful success screenshot does not specify a complete screen.

## Build a vertical slice

1. Reuse existing ColorScheme/TextTheme, semantic tokens, icons, and components. Identify
   missing roles; add the smallest reusable primitive. Don't create an unused design kit.
2. Establish data/state contracts for asynchronous UI. Local display/selection state does
   not need a repository or Cubit. Then implement layout and one primary interaction.
3. Structure by available constraints; cap reading width and change composition on wide
   windows. Scale spacing at most once. Touch-target minimums use logical pixels and must
   not shrink below the platform floor on small screens.
4. Prefer small private StatelessWidgets for sections with their own layout or rebuild
   boundary. Keep formatting, parsing, API calls, navigation effects, and validation rules
   out of build methods. Don't invent a controller/service for every visual section.
5. Use real controls with focus/semantics. A busy action disables duplicate submission,
   keeps its accessible name, and preserves content/geometry. Use minimum height plus
   padding instead of a fixed height around text. Input wrappers must forward needed focus,
   validation, autofill, enabled/readOnly, and keyboard APIs rather than blocking them.
6. Make loading/error/empty states part of the same composition; keep input after failure.
   Add intentional motion only when it clarifies a transition; respect reduced motion.

See `theme-and-design-system.md`, `adaptive-layout.md`, `forms-and-input.md`, and
`design-quality.md` for implementation details. Brand choices may override stylistic
preferences; accessibility and usable content remain requirements.

## Inspect and correct

Exercise the primary action and return path. Inspect changed states at the smallest
supported width, a wide layout, 2x text scale, and keyboard-open state where relevant; cover
supported themes and locales. Compare screenshots against the supplied reference at the
same viewport and content. Check hierarchy, alignment, text wrapping, image crop, safe
areas, focus, and contrast. Fix concrete differences before adding decorative polish.

Add targeted widget tests for behavior at risk (overflow, disabled duplicate actions,
validation, semantics, routing); golden tests only when stable visual comparison is useful.
Never use analyzer success as proof of visual quality. Record device/build, dimensions,
state, checks performed, and any missing visual inspection in the final evidence. If device
tools are unavailable, run layout tests and explicitly leave native/visual review unverified.
