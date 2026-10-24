# Health Records and Step Data

Select the API from the job: direct motion/pedometer sensing, HealthKit queries and Health
Connect records have different authorization/execution requirements. Don't treat Android
activity-recognition permission as a universal grant to read health records. General permission
and Settings behavior: mobile-permissions.md; platform matrix: permission-capabilities.md.

## Availability and scope

Inspect the current health plugin, OS, data-type support and native setup. Android needs
Health Connect availability plus requested record permissions; iOS needs HealthKit capability
and appropriate usage descriptions. Request read/write per data type and only request writes
when the feature writes. A read-only steps widget should not ask for all health types/writes.

Represent unsupported platform, provider unavailable/update required, authorization flow
cancelled, query failure, successful zero data and unavailable data separately where the
platform exposes that distinction. A simulator or new device may legitimately have no records.
Use an install/update/settings action only for the diagnosed cause.

HealthKit deliberately does not reveal whether read access was denied. Do not infer denial
from an empty query, show an endless reauthorization loop, or claim hasPermissions proves
all read scopes. A successful authorization request also isn't proof of readable records.
Preserve platform privacy semantics in feature state and user copy.

## Aggregation and lifetime

Use supported aggregate/deduplication APIs for a defined time interval and data sources.
Phone/watch records may overlap. Blind summing double-counts; blindly taking the maximum
across whole sources can undercount non-overlapping activity. Choose a documented source/
aggregation policy and test overlapping/disjoint records, timezone/daylight-saving boundaries,
manual entries and late syncs. Clarify whether the feature represents device steps or a
health-store aggregate. Backend reward/eligibility rules must not trust a UI count alone.

Cached values need timestamp, date/window and source metadata. Keep useful cached content
visible during refresh and indicate freshness; don't turn failed reads into a new confirmed
zero. Refresh only while the feature needs it and coalesce resume/request work. Don't read
or request authorization on every widget build. Background reads need separate OS capability
and feature justification; a resume observer isn't persistent background execution.

Never log health records, sensitive source metadata or personal measurements in permission
diagnostics. Coordinate account/logout/cache cleanup with the app's storage policy.

## Verification

Use fixtures for aggregation/window math and state preservation; use devices/test accounts
for availability, authorization UI, Settings changes and actual read/write behavior. Test
zero data, partial types, revoked access, provider failure, resume and duplicate refresh.
Report platform limitations without presenting opaque read authorization as a known denial.

Sources: [health package setup and API](https://pub.dev/packages/health),
[Apple health authorization privacy](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data).
