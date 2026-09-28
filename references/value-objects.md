# Domain Values: Money, Units, and Time

Use a value object when a primitive's meaning affects valid operations, comparison, or
storage. Keep the type small and immutable, and add it only when the feature needs the
stronger contract.

## Canonical representation

- Store money as integer minor units paired with an explicit currency. Never use `double`
  for stored money or totals. Resolve the currency's actual minor-unit exponent; do not
  assume every currency has two decimal places.
- Reject unknown currency codes as typed failures. Do not silently choose a default currency
  or default exponent.
- Prevent arithmetic across currencies unless an explicit exchange-rate operation performs
  the conversion. Define one rounding boundary and test that split amounts add back to the
  original total.
- Store physical quantities in one canonical unit per concept (for example, whole metres or
  millilitres). Convert for display at the UI boundary and record the unit in API/storage
  contracts when values cross systems.
- Distinguish an instant from a calendar date. Store instants in UTC; represent a date such
  as a birthday or billing day without inventing a timezone or midnight instant.
- Derive totals and display values from source fields when practical rather than persisting
  duplicate values that can drift.

## Parsing and arithmetic

- Normalize localized digits and separators before parsing user input; see `localization.md`.
- Keep rounding explicit at the boundary where a value becomes canonical. Do not round
  intermediate values repeatedly or sum independently rounded pieces when the pieces must
  equal a known total.
- Avoid adding a decimal arithmetic package for unrelated code. If exact decimal arithmetic
  is needed, evaluate the package against `dependencies.md` and keep conversions at a clear
  boundary.
- Give domain values equality and validation that match their meaning. Do not create wrapper
  types that only rename a primitive without preventing an invalid operation or clarifying a
  contract.

## Time-dependent behavior

- Inject the project's existing time seam when business logic reads the current time. If
  there is no seam, add the smallest constructor-injected source appropriate to the feature;
  do not add a global clock service by default.
- Keep UTC instants separate from local calendar rules such as “next day” or “9 AM”. Apply
  the user's timezone only when a calendar operation requires it.
- Test boundaries with a fixed clock or explicit input time. For randomized behavior, inject
  a seed/source only when reproducible output is part of the feature's contract.

Test equality, invalid input, rounding edges, unit conversion, timezone boundaries, and any
invariant such as “the allocated parts sum exactly to the whole.”
