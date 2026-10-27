# Packaging and releases

## App ZIP releases

Versioned preview releases contain an app ZIP and a matching SHA-256 checksum. The ZIP contains only WorkHarbor.app; settings, calendars, caches, test logs, and development reports are not distribution assets. Build architecture is included in the filename.

On macOS with Swift 6 tooling:

```sh
./scripts/test.sh
./scripts/build-app.sh
```

The app is built in a temporary directory and packaged as `dist/WorkHarbor.zip`. Verify a freshly extracted copy with `codesign --verify --deep --strict` before distributing it. The ZIP avoids metadata that a file provider may attach to the workspace copy of the app bundle.

## Automation

- Pushes to `main` and pull requests run tests and build an app ZIP as a short-lived Actions artifact.
- A version tag matching `vMAJOR.MINOR.PATCH` runs tests, builds and verifies the app, generates a checksum, and publishes a preview release.
- The tag must match `CFBundleShortVersionString`; increment `CFBundleVersion` for each distributed build.
- Release notes must exist at `docs/releases/VERSION.md` before tagging. Keep them focused on product changes, installation, signing and relevant limitations.
- Existing tags, releases and assets are not overwritten. Inspect any partial or uncertain publication before another attempt.
- A manual workflow run must select an existing version tag; branch runs skip publication.
- Release packaging does not require Finder, a DMG tool, or external signing credentials.

## Optional DMG packaging

`scripts/package-dmg.sh` remains available for maintainers who want a custom drag-to-install layout. It requires the Homebrew `create-dmg` tool and a working Finder session. It is not part of the ZIP release workflow. Inspect the resulting layout and verify the mounted app before distributing a DMG.

## Signing and notarization

Current preview builds use ad-hoc signing and are **not notarized by Apple**. They do not claim Gatekeeper approval, disable security protections, or remove quarantine. macOS may prevent them from opening; building from source remains available.

Developer ID distribution requires a Developer ID Application identity, hardened-runtime signing, notarization and validation of the accepted ticket. That path is not configured in this repository, and signing credentials must never be committed.

References: [GitHub release CLI](https://cli.github.com/manual/gh_release_create), [Apple notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).
