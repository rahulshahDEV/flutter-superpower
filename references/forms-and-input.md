# Forms and Input

A form combines transient field values, validation, focus, and submission. Keep controllers
and focus in the widget layer, validation rules with the feature, and remote work in the
existing Cubit/repository path.

## Field ownership and validation

- Use the app's `KTextField`, string constants, and existing validator helpers before adding
  new widgets or packages.
- `TextEditingController`, `FocusNode`, and `GlobalKey<FormState>` are UI resources. Keep
  them in the owning `State` and dispose controllers/nodes there; never put them in a Cubit.
- Keep synchronous validators pure and quick. Return localized feedback for missing,
  malformed, or out-of-range input; do not call a network service from a validator.
- Remote checks such as username availability belong in a Cubit action and visible state.
  Debounce only when useful, cancel or ignore stale results, and distinguish an unavailable
  service from a value the user must change.
- Do not keep a second `isValid` flag that can drift away from the actual field values.
  Derive button availability from the form state or the feature's current state.
- Validate at the appropriate boundary too. A disabled button is not a substitute for
  Cubit/domain validation, and server validation remains authoritative for server-owned
  rules.

## Focus, keyboard, and accessibility

- Match keyboard type, capitalization, autofill hints, and input formatters to the field's
  meaning. Normalize localized digits and separators before parsing; see `localization.md`.
- Set a logical traversal order and a useful `TextInputAction`. Submitting one field should
  focus the next; submitting the final field should invoke the same validated submit action
  as the button.
- Make validation errors programmatically associated with their fields and readable by
  assistive technology. Do not communicate invalidity by color alone.
- Keep the primary action reachable when the keyboard is visible. Use scrolling and
  keyboard insets rather than fixed-height forms; do not cover the focused field with the
  submit button.
- Autofocus only when it supports the task and does not unexpectedly open the keyboard or
  steal focus on navigation.

## Submission and tests

- Prevent duplicate submissions while a request is in progress. Keep the progress and
  failure state visible in the feature's established state shape (sealed or freezed).
- Preserve safe user input after a recoverable failure. Clear secrets such as passwords
  only when the flow's security behavior requires it.
- Test field rules and important form flows through public behavior: invalid input blocks
  submission, valid input reaches the Cubit once, a server failure remains recoverable, and
  keyboard submission matches button submission.
- Dispose test-created Cubits and initialize any mocked storage before building the widget;
  see `testing.md`.
