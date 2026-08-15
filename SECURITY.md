# Security policy

## Supported versions

Until 1.0, only the latest published release is eligible for security fixes.
After stable launch, this table must be replaced with an explicit support
window.

## Reporting a vulnerability

Do not open a public issue for a vulnerability or attach sensitive screen
content, permission databases, crash dumps, signing details, or exploits.

Before accepting external security reports or distributing binaries, enable
GitHub private vulnerability reporting and replace
`RELEASE_SECURITY_CONTACT_PLACEHOLDER` with a monitored private reporting
channel. Publish an acknowledgement target, triage target, disclosure
coordination process, encryption key if offered, and safe-harbor terms.

Include the affected version/macOS/hardware, consent state, minimal synthetic
reproduction, impact, and whether source frames or another person's data may be
exposed. Remove unrelated private data.

## Security invariants

- Screen frames are memory-only and never encoded, persisted, logged, copied,
  uploaded, or analyzed.
- Capture starts only from the macOS system picker after user action.
- Audio and microphone capture remain disabled.
- No network entitlement or third-party runtime dependency ships in 0.1.0.
- App Sandbox, Hardened Runtime, notarization, stapling, and release checks stay
  enabled.
- Private APIs, input injection, privilege escalation, and downloaded code are
  prohibited.

If an invariant changes, treat it as a security architecture change, not a
routine feature.
