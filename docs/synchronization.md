# How synchronization works

WorkHarbor creates and maintains **one-way copies** between calendars available through Apple's EventKit. It does not merge accounts, provide two-way synchronization, or replace your calendar provider.

## Two independent choices

**Agenda selection** controls which calendars appear in the menu. It does not authorize synchronization.

**Synchronization routes** define a source calendar, a writable destination, a copy mode, and optional buffers. You review and apply a route manually, or explicitly authorize that route for automatic synchronization.

Accounts are configured in Apple Calendar. WorkHarbor needs its own full Calendar permission. A calendar being visible in Apple Calendar does not guarantee that the provider allows WorkHarbor to write to it.

## Copy modes

### Busy

A Busy copy has the title `Busy`, with no original notes or location. Timed events can include configurable buffers before and after the event, each from 0 to 240 minutes. All-day events keep their original interval without buffers.

Busy hides the original event details, not the existence or timing of a commitment. Anyone with access to the destination calendar may see the resulting Busy block.

### Full details

A Full details copy includes the title, start and end, all-day status, time-zone information, notes, and location. An original event URL is appended to the copy's notes; the copy's own URL field is reserved for a WorkHarbor ownership marker. Buffers do not apply in this mode.

“Full details” does **not** mean a complete provider-native clone. Attendees, organizers, invitation responses, alarms, and recurrence rules are not copied. Recurring occurrences within the synchronization window are handled as individual copies. Created or updated copies are marked busy and have no alarms.

WorkHarbor does not write changes back to the source event. A destination copy is managed by its route, so later synchronization can overwrite edits made directly to that copy.

## Preview, then apply

A manual preview shows the proposed changes without applying those event changes. Before a write, WorkHarbor checks the reviewed configuration and current calendar snapshot again. A changed snapshot or an expired review requires another preview; a review is valid for less than five minutes.

The current write guard requires Calendar access, a writable destination, and an available network connection, including when a calendar appears local. A successful EventKit commit is not proof that every remote device has already received the change.

## Optional automatic synchronization

Automatic sync is off for a new route. Authorization is tied to the installation, rule identity, source, destination, mode, and buffers. Changing that configuration requires a new authorization. Pausing a route or removing its configuration does not delete its existing copies.

While WorkHarbor is open and the Mac is awake, authorized routes are checked on launch, after wake or calendar-change notifications, and on a two-minute timer. Work is coalesced to avoid overlapping triggers; the timer is not a guarantee of remote delivery within two minutes.

Automatic synchronization creates and updates copies only. It never deletes events.

## Scope and limits

- **Agenda:** up to 80 upcoming or in-progress events over the next seven days.
- **Synchronization:** the previous 30 days and next 180 days. Tracked destination copies may also be inspected outside that window.
- **Availability:** no synchronization while the app is closed or the Mac is asleep.
- **Providers:** your existing account providers handle remote transport. Account restrictions and provider behavior still apply; there is no certified provider compatibility list.
- **Cancellation:** a source event disappearing from the local view is not treated as proof of deletion. Its copy is preserved rather than automatically removed.

## Ownership and route safeguards

WorkHarbor marks copies with installation and rule identities and tracks their event identifiers locally. A matching title or time does not prove ownership. Unknown, modified, or ambiguous identities can block a route rather than cause a replacement copy to be created.

If a tracked copy cannot be located, manual confirmation is disabled and writes remain blocked. An unmatched copy whose source is absent is a different state: it is preserved, not automatically deleted. The interface reports these conditions separately.

Routes must form a one-way flow. Self-routes, cycles, and redundant paths to the same destination are rejected. A calendar receiving Busy copies cannot feed another route. Chaining supported Full details routes requires exact tracked upstream copy identity; this is not a general-purpose way to forward every mirrored event.

Copies with attendees, an organizer, or recurrence rules are protected from modification. This avoids turning synchronization into invitation management.

## Duplicate cleanup

The dedicated cleanup preview targets identified duplicates only when it can preserve the tracked, up-to-date copy. It requires explicit selection and confirmation. It does not guess ownership of unmarked events, clean other installations, or delete copies simply because their source is absent.

A normal manual synchronization preview may also propose duplicate deletions, which require the deletion option and final confirmation. Review the exact proposed events; cleanup is never part of background synchronization.

## Interrupted or uncertain writes

Before changing events, WorkHarbor persists a pending-write record. If a write or local bookkeeping step cannot be confirmed, subsequent writes remain blocked, including after restarting the app.

Do not delete the record, reset local identities, or repeat a batch to bypass this protection. Inspect the destination calendar and use the [support guide](../SUPPORT.md). Recovery must establish what actually happened before another write is attempted.

For data handling, see [Privacy](privacy.md). For implementation boundaries, see [Architecture](architecture.md).
