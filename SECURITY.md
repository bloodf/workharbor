# Security policy

WorkHarbor reads calendar data and can write copies to selected calendars. Privacy leaks, incorrect copy ownership, unintended calendar changes, unsafe persistence or recovery, and bypasses of synchronization approval are security-relevant concerns.

## Project status

WorkHarbor is a development preview, not a security-audited product. There is no long-term support branch or guaranteed security-response time. Reports should identify the affected version or commit and, when safe, whether the issue is reproducible on current `main` with fictional data.

## Report a vulnerability without disclosing it publicly

1. Open the repository's [Security advisories page](https://github.com/bloodf/workharbor/security/advisories).
2. **If GitHub shows “Report a vulnerability,”** use that private reporting form. Its availability depends on the repository settings; this document does not imply that it is enabled.
3. **If that option is unavailable,** open a minimal [contact-request issue](https://github.com/bloodf/workharbor/issues/new/choose) using the “Private contact request” form. Ask the maintainer for a private security reporting channel. Do not include the vulnerability, exploit steps, affected private data, or evidence in that public request. Wait for a verified channel before sending details.

This follows GitHub's [private vulnerability reporting guidance](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately). No private security email address is published here.

## What to include privately

Once a private channel is available, provide only what is needed:

- Affected WorkHarbor version or commit and macOS version.
- A concise description of the impact and relevant feature.
- Minimal reproduction steps using fictional calendars and events.
- Expected versus observed behavior.
- A proposed fix or mitigation, if you have one.

Do not send passwords, tokens, real calendar exports, private event content, account identifiers, or unredacted local state files. A synthetic reproduction is preferable to a real-data dump.

## While investigating

If the issue could cause unintended writes or disclose event details, pause the affected route or quit WorkHarbor. Do not repeatedly retry a failed operation, remove copy markers, or delete local identity and pending-write files to bypass a block. Preserve evidence privately and verify the destination calendar before attempting recovery.

Use only accounts and test calendars you are authorized to inspect. Coordinate disclosure with the maintainer rather than publishing sensitive details in an issue or pull request.

## Ordinary bugs and questions

For issues that do not expose a vulnerability or private information, see [SUPPORT.md](SUPPORT.md) and the [issue forms](https://github.com/bloodf/workharbor/issues/new/choose).
