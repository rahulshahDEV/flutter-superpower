# Security Policy

## What this repo is

This repository is a documentation/skill bundle plus local shell scripts and Dart templates.
It is not a deployed service, and it does not ship credentials. The realistic risks are:

- A secret, token, or client identifier accidentally committed (docs, examples, templates).
- A script or template that, when run, does something unsafe (writes outside the target dir,
  executes untrusted input, weakens a project's security posture).
- Guidance that would lead a user's app into an insecure pattern (logging tokens, plain
  HTTP, insecure storage).

## Reporting

**Do not open a public issue for a security problem.** Report privately:

- Email the maintainer at the address on their GitHub profile
  ([github.com/rahulshahDEV](https://github.com/rahulshahDEV)), or
- Use GitHub's private vulnerability reporting (Security → Report a vulnerability) on this repo.

Include: what you found, where (file/line or script), how it can be abused, and any suggested
fix. You'll get an acknowledgement promptly and a status update on the fix and disclosure
timing.

## Supported versions

Only the latest tagged release is supported. Fixes ship as a new patch tag.

## For users of the skill

- Never commit real `.env` files, keystores, `key.properties`, `google-services.json`,
  `GoogleService-Info.plist`, or store credentials; the skill's templates gitignore them.
- Review scripts before running them: `install.sh` symlinks/copies into your home directory;
  `new_app.sh`/`new_feature.sh` write only inside the target app.
- If you believe the skill's guidance is insecure (see `references/security.md`), report it —
  guidance bugs are security bugs.
