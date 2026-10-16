---
name: app-asset-manager
description: Organize per-app icons, splash and store screenshots, validate actual dimensions and native asset wiring, and use image generation only when available.
---

# app-asset-manager

Work from the factory root. Inspect `AGENTS.md`, the app's `app.yaml`, registry,
existing implementation and working tree first. Reuse existing settings; make the
smallest changes and never replace important configuration without reviewing its
diff. Ask only for essential missing identity or account information. Run relevant
checks, report failures with redacted evidence, and distinguish completed, blocked,
and unverified work. Never fabricate build or publishing success.

Read [shared operating rules](../../../docs/skills.md) and run
`python3 automation/scripts/factory.py --help` before using unfamiliar options.

Read [assets](../../../docs/assets.md) and inspect current assets, Android icon
resources, iOS asset catalogs, splash setup and metadata before editing.

1. Run `python3 automation/scripts/factory.py assets battery_analyzer` and read
   the actual findings. This prepares icon/splash generator configuration; it
   does not generate graphics. Record input file provenance and dimensions.
2. Keep app-specific source graphics, generated native variants and store assets
   in the app's own configured paths. Reuse shared tools, not another app's brand.
3. Preserve aspect ratio, platform masks/safe area, Android adaptive foreground/
   background/monochrome requirements and iOS AppIcon catalog wiring.
4. For splash changes, inspect the installed splash generator or native launch
   configuration. Android 12+ behavior and iOS launch screen constraints differ;
   test both platforms. Do not replace existing generators blindly.
5. Browse current official screenshot specifications for each selected device/
   orientation/store. Validate actual image size, format and alpha rules; avoid
   treating one phone screenshot as satisfying every required device family.
6. If graphics are requested and an actual image-generation tool is available,
   invoke it and inspect the output before claiming generation. Otherwise use
   provided assets, simple code-native assets where suitable, or report missing
   source artwork. Never imply a placeholder is final store artwork.
7. After reviewing configuration and supplying real source files, `assets APP
   --execute` invokes the installed icon/splash generators and resolves their
   dependencies. Run relevant validation and native builds when possible. Inspect
   home-screen icon, launch appearance and screenshots on a device or simulator.
   Report generated, reused, missing and visually unverified assets separately.

Asset validation checks files, not brand ownership or store acceptance. Preserve
source artwork and review generated changes before replacing important assets.

