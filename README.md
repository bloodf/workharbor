<p align="center"><img src="docs/images/banner.png" alt="WorkHarbor — Your calendars. In harmony." /></p>

<p align="center"><a href="README.md">English</a> · <a href="docs/README.pt-BR.md">Português (Brasil)</a> · <a href="docs/README.es.md">Español</a></p>

<p align="center">macOS 14+ · Native SwiftUI · Apple EventKit · MIT licensed</p>

# Your day, in view. Your calendars, in sync.

WorkHarbor brings your upcoming events to the macOS menu bar and helps your calendars work together. See what is next, keep separate schedules visible, and block personal time on a work calendar without sharing the details.

Built for people whose day does not fit in a single calendar. No new calendar account. No extra calendar passwords. Just the calendars already on your Mac.

**[Download](https://github.com/bloodf/workharbor/releases)** · **[Get started](#get-started)** · **[How synchronization works](docs/synchronization.md)** · **[Contribute](CONTRIBUTING.md)**

> **Preview release:** download the app ZIP from [GitHub Releases](https://github.com/bloodf/workharbor/releases). Builds are ad-hoc signed and are not notarized by Apple. Source builds are also available.

## A calmer way to see your day

<p align="center"><img src="docs/images/agenda-en-light.png" width="320" alt="WorkHarbor agenda in light mode, with upcoming events grouped by day" /> <img src="docs/images/agenda-en-dark.png" width="320" alt="WorkHarbor agenda in dark mode, highlighting an event in progress" /></p>

<p align="center"><em>Native macOS interface, shown with fictional events.</em></p>

### One glance, less switching

Open the menu-bar panel to see upcoming events grouped by day, with calendar colors and an indicator for events happening now. Choose which calendars appear and keep configuration in a separate settings window. Secondary click or Control-click opens quick options for the agenda, settings, refresh, and quit. VoiceOver also exposes a Quick options action.

### Share your availability, not your personal plans

Create **Busy** copies in another calendar without the original title, notes, or location. Add time before and after timed events for travel, preparation, or a little breathing room.

### Keep the details where you need them

Choose **Full details** for routes that should carry event titles, times, notes, and locations. Each route has an explicit source and destination, so you decide what goes where.

### Start with a preview. Automate when ready.

Review proposed changes before applying them, then optionally enable automatic synchronization for that specific route. Background synchronization creates and updates copies; it never deletes events.

Light and dark appearances. English, Brazilian Portuguese, and Spanish. A native app that stays close without taking over your workspace.

## Make your calendars work together

1. **Use your existing calendars.** Configure accounts in Apple Calendar, then grant WorkHarbor its own Calendar access.
2. **Choose your view.** Show all calendars in the menu or select just the ones you need.
3. **Create a one-way route.** Pick a source, a writable destination, and Busy or Full details.
4. **Review the result.** Check the proposed copies before confirming changes.
5. **Keep it manual or enable automatic sync.** Automatic permission applies only to the exact route configuration you approve.

For example: keep a personal appointment visible in your own agenda while showing only a Busy block on your work calendar. WorkHarbor creates separate copies, not a two-way calendar merge.

## Get started

### Download the app

Download the ZIP for your Mac architecture and its matching `.sha256` file from [GitHub Releases](https://github.com/bloodf/workharbor/releases). Version 0.2.4 includes an Apple Silicon (`arm64`) build. Verify the checksum, extract the ZIP, quit any previous WorkHarbor instance, and move the app to Applications if you want to keep it installed.

The preview is ad-hoc signed and is not notarized by Apple. macOS may block opening it. Keep macOS security protections enabled; build from source if you prefer to inspect and compile the app yourself.

### Build from source

You need **macOS 14 or later** and **Xcode or Command Line Tools with Swift 6**. There are no third-party Swift package dependencies.

```sh
git clone https://github.com/bloodf/workharbor.git
cd workharbor
./scripts/test.sh
./scripts/build-app.sh
open dist/WorkHarbor.app
```

The build script creates `dist/WorkHarbor.app` and `dist/WorkHarbor.zip`. Quit any existing WorkHarbor instance before opening the new build. Do not bypass macOS security warnings for an untrusted download. For distributable packages, see the [release and packaging guide](docs/RELEASING.md).

Prefer to explore without connecting a calendar? After building, launch the sample-data mode:

```sh
dist/WorkHarbor.app/Contents/MacOS/WorkHarbor --synthetic-demo
```

This mode uses fictional events and blocks access to real calendars.

## Local by design. Explicit about sharing.

WorkHarbor uses Apple's EventKit on your Mac, with no WorkHarbor account, analytics, or calendar backend. Your existing calendar providers still handle remote synchronization, and copies are shared according to the destination calendar's access settings.

- **Your choice of detail:** Busy hides the original title, notes, and location; Full details shares them.
- **Your choice of automation:** enable or pause each route independently.
- **Conservative changes:** tracked copies, route validation, and reviewed duplicate cleanup help avoid unintended changes.

The agenda shows up to 80 events over the next seven days. Synchronization covers the previous 30 and next 180 days, while the app is open and the Mac is awake. Provider compatibility and remote delivery timing need testing; this is not an always-on cloud service.

Read the [synchronization guide](docs/synchronization.md), [privacy notes](docs/privacy.md), and [troubleshooting guide](SUPPORT.md) for the boundaries that matter.

## Build it with us

Help make a focused, open-source calendar companion better. Useful contributions include reproducible bug reports, accessibility improvements, translations, tests, and native macOS polish.

- [Contribution guide](CONTRIBUTING.md)
- [Report a bug or suggest an improvement](https://github.com/bloodf/workharbor/issues/new/choose)
- [Architecture](docs/architecture.md) · [Changelog](CHANGELOG.md)
- [Code of conduct](CODE_OF_CONDUCT.md) · [Security policy](SECURITY.md)

If WorkHarbor fits your workflow, give the project a star and help others find it.

## License

[MIT](LICENSE) · Copyright © 2026 Heitor Ribeiro.
