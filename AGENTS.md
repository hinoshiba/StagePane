# StagePane repository rules

These instructions apply to the entire repository.

## Public repository

- Treat every tracked file and Git history entry as public.
- Never commit, print, or transmit private keys, `.p12`/`.pfx` identity
  exports, export passwords, App Store Connect `.p8` keys, Apple Account
  credentials, notarization credentials, or provisioning profiles.
- An Apple Developer Team ID, certificate subject, and certificate fingerprint
  are public identifiers, not signing credentials. Their publication does not
  authorize exporting or disclosing the corresponding identity or private key.

## Apple identifiers

- The canonical StagePane bundle identifier and explicit Apple App ID are
  `com.hinoshiba.stagepane`.
- Top-level Hinoshiba app identifiers use
  `com.hinoshiba.<lowercase-app-name>`. Related helper and extension bundle
  identifiers must remain below the owning app identifier.
- `stagepane.hinoshiba.com` is the website host. Do not use it as a bundle/App
  ID, and do not replace it where a URL or DNS name is required.

## Apple code signing

- The official Apple Developer Team ID is `94HVVWXLK3`.
- For official releases, reuse the Team's existing approved distribution
  signing identity/private key across its apps, separately for each Apple
  certificate role. Do not create a per-app distribution identity during a
  normal build.
- Direct distribution outside the Mac App Store must use the approved
  `Developer ID Application` identity whose SHA-1 certificate fingerprint is
  `E4B85511B94B3161EC9EF0E6601AD8465D2A623D` and whose certificate subject is
  `Developer ID Application: Shungo Ichikawa (94HVVWXLK3)`.
- The 40-hex value above is the SHA-1 certificate fingerprint emitted by
  `security find-identity`; it is not SHA-256, a private key, or a credential.
- Mac App Store archives and submissions must use the same Team's existing
  approved `Apple Distribution` identity/private key. That identity is
  distinct from the Developer ID identity. Never use `Developer ID
  Application` for a Mac App Store build, and never invent or substitute an
  unverified Apple Distribution fingerprint.
- A build may inspect Keychain and select an already-installed approved
  identity. Do not generate, export, import, revoke, renew, or rotate signing
  identities without explicit maintainer authorization.
- Official distribution builds must use a clean worktree at the explicitly
  reviewed, CI-approved commit. They must fail closed unless the final artifact
  matches the approved Team, certificate role, and selected leaf fingerprint.
