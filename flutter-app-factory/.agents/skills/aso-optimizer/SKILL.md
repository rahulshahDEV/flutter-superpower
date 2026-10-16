---
name: aso-optimizer
description: Research evidenced keyword opportunities and write accurate localized Play/App Store metadata and screenshot copy with platform limit checks.
---

# aso-optimizer

Work from the factory root. Inspect `AGENTS.md`, the app's `app.yaml`, registry,
existing implementation and working tree first. Reuse existing settings; make the
smallest changes and never replace important configuration without reviewing its
diff. Ask only for essential missing identity or account information. Run relevant
checks, report failures with redacted evidence, and distinguish completed, blocked,
and unverified work. Never fabricate build or publishing success.

Read [shared operating rules](../../../docs/skills.md) and run
`python3 automation/scripts/factory.py --help` before using unfamiliar options.

Read the app's store metadata, actual feature set and target audience, then
[Android publishing](../../../docs/android-publishing.md) or
[iOS publishing](../../../docs/ios-publishing.md). Reuse existing localization.

1. Inspect available first-party store analytics, search performance and any
   authorized keyword data. Browse current official store listing guidance before
   changing limits or policy-sensitive wording.
2. Separate verified metrics (source, locale, collection date and definition)
   from qualitative keyword hypotheses. If no measurement source exists, say so.
   Never invent search volume, ranking, installs, conversion or competitor facts.
3. Draft Play title/short/full descriptions and iOS name/subtitle/keyword/
   promotional fields only for real app capabilities. Suggest screenshot copy
   aligned to actual screens and avoid repetitive keyword stuffing or guarantees.
4. Keep translations locale-specific; preserve placeholders requiring product,
   support or legal input. Do not call machine-drafted translations reviewed.
5. Run `python3 automation/scripts/factory.py metadata battery_analyzer`.
   Inspect the validator's supported fields and current official limits; validate
   additional locale fields when necessary. Count characters rather than bytes,
   and respect field-specific semantics and prohibited content.
6. Save a reviewable metadata diff and cite the sources of any research. Explain
   uncertainty and review needed. Do not publish metadata under an optimization
   request unless that external mutation was separately authorized.

The CLI validates metadata; it does not supply keyword market data or guarantee
ranking. Use an available browser/search or authorized analytics API for research.
When none is available, provide clearly labeled unverified keyword ideas.

