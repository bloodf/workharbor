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
