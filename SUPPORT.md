# Getting help

WorkHarbor is a community-maintained development preview. Support is provided through [GitHub Issues](https://github.com/bloodf/workharbor/issues/new/choose), without a guaranteed response time.

English, Brazilian Portuguese, and Spanish are welcome. Please search existing issues before opening a new one.

## Start here

- [Build and first-run instructions](README.md#get-started)
- [Synchronization behavior and limitations](docs/synchronization.md)
- [Privacy and local data](docs/privacy.md)
- [Release and packaging guide](docs/RELEASING.md)
- [Contributing](CONTRIBUTING.md)

For a suspected vulnerability, follow [SECURITY.md](SECURITY.md) instead of posting the details publicly.

## Troubleshooting

### The app opens, but there is no Dock window

WorkHarbor is a menu-bar app. Look for the calendar-and-clock icon in the macOS menu bar. Open Settings from the panel to configure calendars and synchronization routes.

### No calendars appear

Confirm that the accounts and calendars are available in Apple Calendar. Then grant WorkHarbor its own Calendar permission from the app's settings. Apple Calendar's permission does not transfer to WorkHarbor. If access was denied, review WorkHarbor's Calendar permission in macOS System Settings.

Refresh the calendar list after changing accounts. Provider restrictions still apply, and a read-only calendar cannot be a destination.

### An event is missing from the menu

Check the agenda's calendar selection. The panel shows up to 80 events over the next seven days, excluding canceled events and events that have ended. Refresh the panel, then check whether the event is visible in Apple Calendar itself.

### Automatic synchronization is not running

Check that:

- WorkHarbor is open and your Mac is awake.
- Calendar access is granted and the destination is writable.
- Automatic synchronization is enabled for the exact route you are using.
- The source, destination, mode, and buffer settings have not changed since approval.
- The app is not displaying an unresolved write, identity, or storage error.
- A network connection is available; the current write guard blocks offline writes.

WorkHarbor periodically checks authorized routes and responds to wake and calendar-change notifications. The destination provider determines remote delivery timing. See [the synchronization guide](docs/synchronization.md).

### A preview expired or a calendar changed

Generate a new preview and review it again. Manual reviews expire after five minutes, and a changed configuration or calendar snapshot invalidates a previous review.

### A write is blocked or its result is uncertain

Stop and read the error. Check the destination in Apple Calendar before making further changes. Do not repeatedly retry the same batch, reset the app, erase its local inventory, or delete its pending-write record to force progress. Those records help prevent duplicate writes after an interrupted operation.

If needed, open a report with a sanitized description and fictional reproduction. Never attach your settings, copy inventory, or pending-write journal publicly. There is no documented self-service “force retry” recovery procedure.

### Tracked copy identities cannot be located

In Settings → Calendar sync, choose **Inspect copies** for the affected route. This read-only operation looks up stored IDs and exact WorkHarbor markers in the intended destination, over the displayed two-years-before/two-years-after window using one-year query chunks. It does not modify events or the tracking inventory, and does not read event titles or descriptions for the report.

If exact, unique, safe matches exist, **Reconnect exact identities** offers a separate confirmation. Recovery freshly validates the result, preserves a local backup of the original tracking file, and changes only local identity bindings. Calendar events are not created, updated, or deleted by recovery. Previously authorized automatic routes may resume afterward.

Unknown absence, changed markers/calendars, multiple matching copies, participants, and recurrence are not repaired by guessing. Copies outside the finite search window may remain unresolved. A pending write journal blocks this recovery path; do not remove it. Share only anonymized counts when asking for help.

### A source event was deleted, but its copy remains

This is intentional. A missing source is not reliable proof of deletion, so WorkHarbor preserves the copy. It does not perform automatic cancellation propagation. Review the event in Apple Calendar; duplicate cleanup is not a general-purpose deletion tool.

### macOS blocks an app download

Do not bypass a security warning for an untrusted download. Check the source and signing information. Local development builds are ad-hoc signed, which is different from Developer ID signing and Apple notarization. The [packaging guide](docs/RELEASING.md) explains the distribution path.

### A second instance will not start

Quit the existing WorkHarbor instance using its menu-bar panel, then open the intended build. Do not remove the process lock while another instance is running.

## Write a useful report

Include:

1. The WorkHarbor version or commit, installation method, macOS version, and Mac architecture.
2. What you expected and what happened.
3. Steps to reproduce with fictional events.
4. Relevant mode, buffers, and whether automatic synchronization was enabled.
5. A provider type if relevant, never the account address or calendar identifier.
6. A sanitized screenshot or short error excerpt, if needed.

Avoid calendar exports, event titles or notes from real calendars, participant names, meeting links, credentials, local state files, and full machine-specific logs. Use the fictional demo for screenshots whenever possible.


### Find Inspect copies and confirm the running build

Open the menu-bar panel, choose Settings, and read **Version / Build** in General or the sidebar. Version 0.2.3 / build 15 shows **Inspect copies** as a separate button under every rule in **Calendar sync**. In Portuguese the button is **Diagnosticar cópias**; in Spanish it is **Diagnosticar copias**. A sync warning also has a button to open Calendar sync.

If the expected button or full version/build is absent, quit the old instance from its own menu before opening the intended app. Do not delete the instance lock or local inventory to force a second instance.

Inspection searches a finite, displayed date range. A direct ID can still identify a copy outside that range. A missing result is not proof of deletion or cancellation. Previews preserve unknown IDs; only separately confirmed exact, unique and safe matches can reconnect local tracking. Each reconnection preserves the original file bytes in a new private backup. A changed or unreadable inventory blocks further writes rather than replacing it with an empty file.
