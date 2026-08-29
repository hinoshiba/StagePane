# Security policy

## Supported versions

Until 1.0, only the latest published release is eligible for security fixes.
After stable launch, this table must be replaced with an explicit support
window.

## Reporting a vulnerability

Do not open a public issue for a vulnerability or attach sensitive screen
content, permission databases, crash dumps, signing details, or exploits.

Send vulnerability reports privately to
[support@hinoshiba.com](mailto:support@hinoshiba.com) with `StagePane Security`
in the subject. If the report requires encrypted delivery, ask for a secure
transfer method before attaching exploits or sensitive data. Acknowledgement
and triage targets, disclosure coordination, any encryption key, and safe-harbor
terms will be published before binary distribution.

Include the affected version/macOS/hardware, consent state, minimal synthetic
reproduction, impact, and whether source frames or another person's data may be
exposed. Remove unrelated private data.

## Security invariants

- Screen frames are memory-only and never recorded, logged, uploaded, or
  analyzed. Only an explicit **Copy Audience Image** or **Save Audience Image…**
  action renders one clean Stage PNG to the clipboard or a user-selected file.
- Capture starts only from the macOS system picker after user action.
- Audio and microphone capture remain disabled.
- No network entitlement or third-party runtime dependency ships in 0.3.1.
- App Sandbox, Hardened Runtime, automatic App Store signing, and release
  checks stay enabled. StagePane contains no cross-application input or
  Accessibility permission/action path.
- Private APIs, raw mouse/keyboard event synthesis, unconsented or ambiguous
  input targets, keyboard/drag forwarding, event taps, privilege escalation,
  generic canvas/content control, and downloaded code are prohibited.

If an invariant changes, treat it as a security architecture change, not a
routine feature.
