# Localization & Formatting

Two accepted states — never mix them in one app:

1. **Single-language app** — all copy in `StringConstants` / `<feature>_text.dart` (house default).
2. **Localized app** — the project's `flutter_localizations` + ARB setup. Use it; do not add a
   second localization package.

## Detecting the project's state

```bash
grep -E "flutter_localizations|intl|gen_l10n" pubspec.yaml
ls lib/l10n 2>/dev/null || true
```

- ARB present → use `AppLocalizations.of(context)` and add keys to every locale.
- Only `StringConstants` → keep adding there; do not introduce ARB without being asked.

## Rules (both states)

- No user-facing string literals in widgets. Ever.
- No string concatenation to build sentences (word order differs by language).
  Use placeholders: `'Welcome, {name}'` / ARB `"welcome": "Welcome, {name}"`.
- Plurals go through the localization system (`{count, plural, ...}`), never `if (n == 1)`.
- Text expansion: assume +30–40% length. Buttons wrap, rows use `Flexible`, no fixed widths.
- Locale-aware formatting via `intl`:
  ```dart
  DateFormat.yMMMd(locale).format(date);
  NumberFormat.currency(locale: locale, symbol: currencySymbol).format(amount);
  NumberFormat.decimalPattern(locale).format(value);
  ```
  Never hardcode `$`, `Rs.`, or `dd/MM/yyyy`.
- Dates: parse ISO-8601 to `DateTime`, format at the edge (widget) with the active locale.
- Time zones: store UTC, convert for display (`flutter_timezone`/`timezone` when the app has it).

## RTL

- Use directional APIs everywhere: `EdgeInsetsDirectional`, `AlignmentDirectional`,
  `start`/`end` instead of `left`/`right`, `TextAlign.start`.
- Icons that imply direction (back arrows, chevrons) should mirror when the project supports RTL.
- Test: wrap a screen in `Directionality(textDirection: TextDirection.rtl)` and look for
  broken spacing, clipped text, and mirrored-broken layouts.

## Adding a localized string (ARB path)

1. Add the key + default English value to the ARB.
2. Run codegen (`fdev gen` or `flutter gen-l10n`).
3. Use it: `AppLocalizations.of(context).keyName`.
4. Translate into every other locale file — a missing key falls back silently, which is a bug.
5. For plural/placeholder keys, pass the placeholders; never rebuild the sentence in Dart.

## Checklist per change

```
[ ] No new hardcoded user-facing string
[ ] No string concatenation for sentences
[ ] Numbers/dates/currency use locale-aware formatting
[ ] Layout survives longer translations (test the longest locale if available)
[ ] RTL not broken (directional APIs used)
[ ] Every locale updated when ARB is used
```
