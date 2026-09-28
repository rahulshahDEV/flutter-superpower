# Data Export and Restore

Backup files and human-facing exports are different products. A backup must round-trip the
user's data; a CSV or PDF may be designed for reading and should not silently become a
restore format.

## Portable format

- Put backups behind the existing repository/storage boundary. Do not make widgets or domain
  objects read files directly.
- Version the file format separately from the app's storage schema. Include enough metadata
  to identify the format, source schema, export time in UTC, and payload integrity.
- Store canonical values and stable record identifiers: machine-readable enum codes, UTC
  instants, integer minor units for money, and canonical physical units. Do not serialize
  localized labels, formatted dates, or display numerals as data.
- Treat a checksum as corruption detection, not encryption, authenticity, or protection from
  a malicious file. State clearly when a shared artifact contains plaintext personal data.
- Keep session tokens, credentials, and other secrets out of user backups unless the feature
  has an explicit security design for them.

## Restore safely

- Inspect size, format version, schema version, checksum, and required fields before changing
  user data. Refuse unknown or newer formats with a clear recoverable error; never guess.
- Validate IDs, types, ranges, relationships, duplicates, and resource limits before publish.
  Treat a picked file as untrusted input.
- Use the storage engine's transaction or an isolated staging store. Validate and write the
  complete import there, then publish it only after it opens successfully. Preserve the live
  data if any step fails. Do not clear the current store and then parse into it.
- Explain whether restore replaces or merges data before the user confirms. Make the loss
  and duplicate policy explicit and deterministic.
- Do not claim atomic rollback when the current storage engine cannot provide it. Choose a
  compatible staged strategy or report the limitation before implementing the flow.

## Human-facing exports

- Clearly label CSV/PDF reports as exports, not restorable backups. Localize only these
  human-facing values; machine backups remain canonical.
- For CSV, implement RFC 4180 quoting and separately neutralize spreadsheet formula cells
  beginning with `=`, `+`, `-`, `@`, tab, or carriage return. Quoting alone does not prevent
  a spreadsheet from evaluating a formula.
- Stream large exports through a temporary file where practical. Publish or share the file
  only after the write completes; remove partial files on failure.
- Use an injected platform gateway for file picking and sharing. Sharing requires an explicit
  user action; never upload a backup as an implicit side effect.

## Required checks

Test export → import → export round trips, older supported schemas, unknown/newer versions,
truncated and corrupted files, duplicate IDs, hostile text, and a failure partway through
restore. Confirm that failed imports leave the original data intact and that partial exports
are not offered to the user. See `security.md` and `models-and-storage.md` for adjacent rules.
