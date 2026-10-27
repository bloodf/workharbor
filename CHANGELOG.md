# Changelog

User-visible changes are recorded below. Preview releases are ad-hoc signed and are not notarized by Apple.

## [0.2.4] — 2026-10-27

Build 16 · Preview release

- Secondary mouse/trackpad click and Control-click on the menu-bar icon open native quick options: Open agenda, Settings, Refresh and Quit.
- Primary click keeps the existing agenda content in a transient native popover; clicking again closes it.
- Opening or cancelling quick options executes no command. Refresh remains disabled without existing calendar access and never requests permission from the menu.
- Accessible status-button label/help and explicit Open agenda / Quick options actions supplement normal keyboard activation and native menu navigation.
- Synthetic AppKit QA exercises event routing, repeated popover/menu cycles, cancellation and deferred action selection without real calendars or global input injection.


## Earlier development builds

### 0.2.3 (build 15)

- Show the exact version and build from the running app bundle in General settings and the sidebar.
- Give Inspect copies its own labeled button in each sync rule, with guidance and a shortcut from sync warnings.
- Report duplicate markers and inconsistent unsafe observations even when the tracked ID still resolves.
- Keep previews read-only for tracking identities. Reconnection requires a separate confirmed inspection and an exact-byte backup.
- Block on a removed, unreadable, malformed or externally changed tracking inventory, and reject expired inspections after the fresh scan too.
- Treat detached recurrence copies consistently as unsafe for reconnection, forwarding and writes.


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
- GitHub Actions tests and app builds, with version-tagged ZIP preview releases and SHA-256 checksums.

### Fixed

- Manual write confirmation now blocks when tracked copy identities cannot be located, with a disabled confirmation control and explicit pending-state feedback. Regression tests cover missing identities in the reviewed and current snapshots.
- Synchronization status distinguishes unmatched copies from unlocated tracked identities rather than presenting them as one undifferentiated count.

### Current boundaries

- macOS 14 or later; Swift 6 tooling is required to build from source.
- The menu shows up to 80 events over the next seven days.
- Synchronization examines the previous 30 days and next 180 days while the app is running and the Mac is awake.
- Background synchronization never deletes events; missing source events do not trigger deletion of copies.
- Provider behavior, time-zone edge cases, accessibility, and remote synchronization timing need continued validation. Unit tests are not provider certification.
