# Contributing

WorkHarbor is currently a development preview. Discuss behavior changes before expanding the synchronization engine.

## Local checks

Use macOS with Xcode/Swift 6. Run `./scripts/test.sh` and `./scripts/build-app.sh`.

For visual review with sample data only, run the built executable with:

```sh
WorkHarbor --synthetic-demo --render-previews /tmp/workharbor-previews
```

This render mode uses a temporary data directory and does not request calendar permission. Never test deletion or migration against personal calendars as a shortcut.

## Non-negotiable invariants

- Preserve installation and rule identities across upgrades.
- Do not infer ownership from event titles or dates.
- A missing source is not proof of deletion.
- Do not retry an uncertain write without reconciliation.
- Automatic authorization is bound to the exact rule.
- No automatic deletions.
- No credentials, calendar exports, private fixtures, or machine-specific build logs in the repository.

Keep English, Brazilian Portuguese, and Spanish strings aligned. Use sample data for screenshots. Document limitations and distinguish unit tests from provider integration tests.

A license has not yet been selected; discuss contribution terms with the owner before submitting substantial changes.
