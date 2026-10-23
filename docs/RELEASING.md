# Packaging and releases

WorkHarbor can be distributed as a custom drag-to-install DMG. It includes the app, an Applications link, a branded background and a volume icon. The installer does not change security settings, start the app, or grant Calendar access.

## Local packaging

On macOS with Swift 6 tooling:

```sh
./scripts/test.sh
./scripts/build-app.sh
brew install create-dmg
./scripts/package-dmg.sh
```

The packager uses the official Homebrew `create-dmg` formula. It requires a working Finder session for the custom layout; if Finder customization fails, packaging fails instead of silently claiming a customized result. It refuses to overwrite an existing DMG. Move prior output aside before packaging the same version again.

Outputs are `dist/WorkHarbor-VERSION-ARCH.dmg` and its SHA-256 checksum. Architecture is the build host's architecture, not a claim of universal-binary support. Mount and visually check the layout on a Mac before distributing a new template.

## Automation

- Pushes to `main` and pull requests run tests and build an app ZIP as a short-lived Actions artifact. They do not publish a release.
- A tag matching `vMAJOR.MINOR.PATCH` runs tests, builds, packages and publishes a **prerelease** with a DMG and checksum only if all preceding steps pass.
- The tag must exactly match `CFBundleShortVersionString` in `Resources/Info.plist`. Increment `CFBundleVersion` with each distributed build.
- Do not reuse tags or replace existing release assets. A failed or already-created release is not blindly overwritten.
- A manual workflow invocation must select an existing version tag; running it on a branch skips publication.
- Pull-request builds have read-only repository access. Only the tag release job receives `contents: write` for its existing GitHub Actions token. No personal access token is needed.

Before tagging, review the source, run real-world calendar checks with disposable calendars, verify the customized DMG, and write release notes. A green unit-test run is not proof of production reliability.

## Signing and notarization

The current build script uses **ad-hoc signing**, not Developer ID signing. The preview workflow says so explicitly and marks releases as prereleases. It does not claim Gatekeeper approval or notarization, and never disables Gatekeeper or removes quarantine for the user.

For a trusted public distribution, the maintainer needs an active Apple Developer Program membership, a Developer ID Application certificate with its private key, a hardened-runtime signing configuration, and an approved notarization credential. Those credentials are not included in this repository and must not be committed or pasted into issues. Their creation or deployment is a separate setup step.

After that setup, sign the app and DMG, submit to Apple's notary service, require an accepted result, staple and validate the ticket, and only then publish. This signed path is **not configured yet**; an existing web login alone is not a signing identity.

References: [create-dmg](https://github.com/create-dmg/create-dmg), [GitHub release CLI](https://cli.github.com/manual/gh_release_create), [Apple notarization documentation](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).
