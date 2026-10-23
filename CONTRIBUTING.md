# Contributing to WorkHarbor

Thanks for helping build a focused, native calendar companion for macOS. You can contribute code, documentation, translations, accessibility feedback, or a clear bug report. English, Brazilian Portuguese, and Spanish are welcome in issues and pull requests.

Please follow our [Code of Conduct](CODE_OF_CONDUCT.md). For vulnerabilities, use the [security policy](SECURITY.md), not a public bug report.

## Find a useful starting point

- Improve keyboard navigation, VoiceOver behavior, or contrast.
- Refine the menu-bar experience and empty or error states.
- Keep English, Brazilian Portuguese, and Spanish translations consistent.
- Add synthetic test cases for dates, time zones, recurrence, and synchronization safeguards.
- Improve setup instructions and reproducible troubleshooting examples.

Before starting a large feature or changing synchronization behavior, [open an issue](https://github.com/bloodf/workharbor/issues/new/choose) to discuss the problem and intended scope. Small, focused documentation fixes can go straight to a pull request.

## Set up your development environment

Requirements: macOS 14 or later, Git, and Xcode or Command Line Tools with a Swift 6 toolchain. The package currently uses Swift 5 language mode. It has no third-party Swift package dependencies.

1. Fork the repository and clone your fork.
2. Create a descriptive branch for one change.
3. From the repository root, run:

```sh
./scripts/test.sh
./scripts/build-app.sh
```

The test script runs the `HarborCoreTests` suite. The build script produces a local app in `dist/WorkHarbor.app`. Quit another running instance before opening it. The default local build is ad-hoc signed, not notarized. See [release and packaging instructions](docs/RELEASING.md) for distribution work.

Do not commit build outputs, local configuration, credentials, or machine-specific logs.

## Develop with fictional events first

Explore the menu without granting Calendar access:

```sh
dist/WorkHarbor.app/Contents/MacOS/WorkHarbor --synthetic-demo
```

Render all three languages in light and dark appearances:

```sh
dist/WorkHarbor.app/Contents/MacOS/WorkHarbor \
  --synthetic-demo --render-previews /tmp/workharbor-previews
```

Synthetic mode uses temporary app data and blocks real calendar reads and writes. Use disposable calendars containing only fictional events for any manual EventKit integration testing. Never test deletion, recovery, or migration against important calendars.

## Make a reviewable change

- Keep changes focused and match the surrounding Swift style.
- Put deterministic synchronization logic in `HarborCore`; keep EventKit and UI work in `WorkHarbor`.
- Add regression tests for behavior changes, especially date, identity, privacy, and persistence cases.
- Update user-facing documentation when behavior or setup changes.
- Keep `Sources/WorkHarbor/Localization.swift` and permission descriptions in `Resources/*.lproj` aligned across supported languages.
- For UI changes, include light and dark screenshots with fictional data. Check keyboard interaction and VoiceOver where relevant; report what you actually tested.
- Add a concise entry under `Unreleased` in [CHANGELOG.md](CHANGELOG.md) for user-visible changes.

See the [architecture overview](docs/architecture.md) and [synchronization guide](docs/synchronization.md) before changing calendar behavior.

## Preserve the safety boundaries

Changes must preserve these properties unless a separately reviewed design explicitly replaces them with an equally protective approach:

- Persist installation and rule identities across upgrades.
- Never infer copy ownership from an event's title or date.
- Never treat a missing local source as proof of deletion.
- Never silently retry an uncertain write or discard its pending-write record.
- Bind automatic authorization to the exact source, destination, mode, and buffer settings.
- Never delete events during background synchronization.
- Keep Busy copies free of original titles, notes, and locations.
- Never modify unrelated events or turn copies into meeting invitations.
- Preserve local configuration when it cannot be read safely; fail closed rather than reset it.

## Open a pull request

Describe the problem, the approach, related issues, and the checks you ran. Include known limitations and any tests you could not run. A passing unit-test suite is not evidence of compatibility with a real calendar provider.

Before submitting:

- Run `./scripts/test.sh` and `./scripts/build-app.sh` on macOS for code changes.
- Check links and language consistency for documentation changes.
- Review the diff for credentials, calendar/account identifiers, private events, and machine-specific paths.
- Keep generated app bundles, archives, and local validation output out of the commit.

No fixed review or response time is promised. Smaller pull requests with clear evidence are easier to review.

## Contribution license

By submitting a contribution, you agree that it may be distributed under this repository's [MIT License](LICENSE). Submit only material you have the right to contribute, and identify any third-party material and its license. No separate contributor license agreement is required by this guide.
