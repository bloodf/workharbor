# Architecture

WorkHarbor is a macOS Swift package with two targets and a unit-test target. The package requires a Swift 6 toolchain, currently uses Swift 5 language mode, and targets macOS 14 or later. It has no third-party Swift package dependencies.

## Repository map

| Path | Responsibility |
| --- | --- |
| `Sources/WorkHarbor/` | SwiftUI interface, app lifecycle, EventKit integration, and localization |
| `Sources/HarborCore/` | Models, reconciliation, route validation, and local safety mechanisms |
| `Tests/HarborCoreTests/` | Synthetic unit tests for core behavior |
| `Resources/` | App metadata, icons, and localized permission text |
| `scripts/` | Local testing, app builds, and packaging tools |
| `docs/` | User and contributor documentation and fictional-data screenshots |
| `.github/` | Community templates and repository automation configuration |

## Application layer

`WorkHarborApp.swift` owns the SwiftUI menu-bar scene. Its app delegate manages the settings window, single-instance protection, periodic refresh, calendar-change notifications, and wake handling.

`AgendaPopover.swift` renders the upcoming agenda. `ContentView.swift` contains calendar selection, route configuration, previews, and confirmation flows. `Localization.swift` supplies the interface strings.

`AppModel.swift` coordinates observable UI state, settings persistence, reviews, and automatic synchronization. It separates agenda selection from route authorization.

`CalendarService.swift` is the EventKit boundary. It requests access, reads calendar snapshots, maintains the local copy inventory, validates reviews, and applies selected changes. It also monitors network availability and uses the durable pending-write journal around EventKit mutations.

## Core layer

- `Models.swift`: persisted settings, route configuration, and settings migration.
- `Reconciliation.swift`: event values, occurrence-to-copy markers, source/copy comparison, and planned changes.
- `RouteGraph.swift`: topological ordering, cycle/redundant-path rejection, and constrained tracked-copy recovery.
- `AutomaticSyncPolicy.swift`: exact-route consent and create/update-only automatic plans.
- `CleanupPlanner.swift`: duplicate candidates that preserve a known, current tracked copy.
- `CopyInventory.swift`: reconciliation of local copy identities after writes.
- `ReviewGuard.swift`: permission, freshness, network, and snapshot checks; occurrence identity and copy identity validation.
- `PendingWriteJournal.swift`: persistent intent that prevents blind retries after an uncertain write.
- `ProcessLock.swift`: single-instance protection.

## Write path

1. Read settings and explicitly selected calendar routes.
2. Validate calendar availability, writability, and route graph constraints.
3. Build a source-and-copy snapshot and a proposed change set.
4. Obtain a current manual confirmation or verify exact automatic consent.
5. Re-read and validate the snapshot, permissions, and review state.
6. Persist write intent before the first event mutation.
7. Stage and commit changes through EventKit.
8. Reconcile the copy inventory and complete the pending-write record only after the local bookkeeping succeeds.

A failure can leave the pending record in place and block later writes. This is intentional: uncertainty must not turn into duplicate writes on the next timer tick.

## Testing boundaries

`HarborCoreTests` exercises transformation, ownership, recurrence identity, route validation, consent, duplicate cleanup, persistence, and review guards with synthetic data.

These tests do not exercise live provider accounts, establish remote delivery timing, certify accessibility, or prove that every provider preserves EventKit identifiers and markers. Those need separate, carefully scoped manual validation using disposable calendars.

Use the app's synthetic demo for visual work. See [Contributing](../CONTRIBUTING.md) for commands and [Synchronization](synchronization.md) for user-facing semantics.
