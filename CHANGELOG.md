# Changelog

User-visible changes are recorded here. `Unreleased` describes the current development preview; it is not a claim that a packaged or notarized release has been published. Historical release dates are not reconstructed from development builds.

## [Unreleased]

### Added

- Read-only, in-app copy-identity inspection with bounded date searches, and separately confirmed metadata-only reconnection for exact unique safe matches. Unknown copies remain blocked; local tracking backups are preserved.

- Native macOS menu-bar agenda with calendar selection, day grouping, calendar colors, and in-progress event indicators.
- Light and dark appearances and English, Brazilian Portuguese, and Spanish interfaces.
- One-way calendar routes with Busy or Full details copies and configurable Busy buffers.
- Preview and confirmation before manual writes, plus optional automatic synchronization for explicitly approved routes.
- Reviewed cleanup of identified duplicate copies.
- Local copy tracking, route validation, single-instance protection, and durable pending-write records.
- Synthetic demonstration mode and multilingual screenshot rendering without real calendar access.
- Unit tests for synchronization, privacy transformations, route consent, copy inventory, cleanup, review validation, identity migration, and write-journal behavior.
- MIT license, product-focused multilingual READMEs, contribution and support guides, security and conduct policies, and structured issue and pull request templates.
- Custom drag-to-install DMG packaging with branded artwork, an Applications link, and a checksum.
- GitHub Actions configuration for tests and app builds, plus tag-triggered DMG prerelease publishing. These definitions do not establish that a workflow has passed or a release has been published.

### Fixed

- Manual write confirmation now blocks when tracked copy identities cannot be located, with a disabled confirmation control and explicit pending-state feedback. Regression tests cover missing identities in the reviewed and current snapshots.
- Synchronization status distinguishes unmatched copies from unlocated tracked identities rather than presenting them as one undifferentiated count.

### Current boundaries

- macOS 14 or later; Swift 6 tooling is required to build from source.
- The menu shows up to 80 events over the next seven days.
- Synchronization examines the previous 30 days and next 180 days while the app is running and the Mac is awake.
- Background synchronization never deletes events; missing source events do not trigger deletion of copies.
- Provider behavior, time-zone edge cases, accessibility, and remote synchronization timing need continued validation. Unit tests are not provider certification.
