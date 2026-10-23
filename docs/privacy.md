# Privacy and data handling

WorkHarbor is a local macOS application. The current app has no WorkHarbor account, analytics, advertising SDK, AI endpoint, or project-operated calendar backend. It reads and writes calendars through Apple's EventKit after you grant Calendar access.

“Local” does not mean that calendar copies never leave your Mac. Existing calendar accounts and their providers continue to synchronize data according to their own settings and policies.

## What the app reads

WorkHarbor reads calendar identifiers, names, colors, writability, and event data needed for the agenda and configured synchronization routes. Depending on the route, this includes event titles, times, notes, locations, URLs, and identifiers. It also checks participant and recurrence metadata to protect events that should not be modified.

Calendar permission is broader than the set of calendars selected for the menu. Selecting fewer agenda calendars changes the view; it is not a macOS permission boundary.

## What the app writes

You choose each destination calendar and the content mode:

- **Busy:** a generic title and event timing, including optional buffers for timed events. Original titles, notes, locations, and URLs are not included in the copy.
- **Full details:** titles, timing, notes, locations, and original URLs included in notes. See the [field-level limitations](synchronization.md#full-details).

Copies also contain a WorkHarbor marker in the event URL field. It includes an installation identifier, a route identifier, and a hash derived from the source identity. This marker supports ownership tracking; it is not a credential or a guarantee of anonymity.

Copies are subject to the destination calendar's sharing permissions and provider policies. Check who can access that calendar before choosing Full details. Removing details later cannot undo information that another person or provider has already received or retained.

## Data kept on your Mac

WorkHarbor keeps application data in its macOS Application Support directory:

- Settings, including installation identity, rules, language, agenda selections, and automatic-sync consent.
- A copy inventory linking WorkHarbor markers to local event identifiers.
- A pending-write record when a write is in progress or its outcome has not been reconciled.
- A settings backup when applicable and a single-instance lock.

The inventory and write journal store identities and bookkeeping rather than event titles, notes, or locations. They can still reveal relationships between calendars and must not be treated as public diagnostic files. Current settings fields do not require account passwords.

Existing unknown settings fields are preserved when saving an older configuration. An upgrade should not be assumed to remove every historical value. WorkHarbor does not provide encrypted storage of its own; local file protections and your Mac's security settings remain important.

## Control and removal

You can select agenda calendars, pause automatic routes, remove route configurations, quit the app, or revoke Calendar permission in macOS settings. Pausing or removing a route does not remove its copies from destination calendars. Removing the app does not by itself revoke provider access to copies already synchronized.

Do not erase the copy inventory or pending-write record as a troubleshooting shortcut. Losing those identities can prevent safe reconciliation. See [Support](../SUPPORT.md) before attempting recovery or a reset.

## Screenshots and issue reports

Use fictional events whenever possible. Never upload real calendar exports, account identifiers, invitation links, participant details, credentials, settings, inventory files, or pending-write journals to a public issue.

The built-in `--synthetic-demo` mode uses temporary app data and blocks real calendar access. Repository agenda screenshots use fictional events.

For a privacy vulnerability, follow the [security policy](../SECURITY.md).
