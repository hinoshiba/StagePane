# StagePane repository rules

These instructions apply to the entire repository.

## Public repository

- Treat every tracked file and Git history entry as public.
- Never commit, print, or transmit private keys, `.p12`/`.pfx` identity
  exports, export passwords, App Store Connect `.p8` keys, Apple Account
  credentials, or provisioning profiles.
- Apple Developer Team IDs are public identifiers, not signing credentials.
  Their publication does not authorize exporting or disclosing an identity or
  private key.

## Apple identifiers

- The canonical StagePane bundle identifier and explicit Apple App ID are
  `com.hinoshiba.stagepane`.
- Top-level Hinoshiba app identifiers use
  `com.hinoshiba.<lowercase-app-name>`. Related helper and extension bundle
  identifiers must remain below the owning app identifier.
- `stagepane.hinoshiba.com` is the website host. Do not use it as a bundle/App
  ID, and do not replace it where a URL or DNS name is required.

## App Store distribution

- The official Apple Developer Team ID is `94HVVWXLK3`.
- Official binaries are built by the `App Store Release` Xcode Cloud workflow
  from immutable `v<major>.<minor>.<patch>` tags. Do not add another local
  release, signing, notarization, DMG, or upload path.
- Keep automatic signing enabled for the checked-in `StagePane-AppStore`
  scheme. Xcode Cloud manages distribution signing for Team `94HVVWXLK3`; do
  not add certificate fingerprints, profiles, or private signing material to
  the repository.
- The tag version must equal `MARKETING_VERSION`. Build numbers are assigned by
  Xcode Cloud and, because this is a macOS app, must remain monotonically
  increasing across marketing versions.
- Pushing a tag authorizes a cloud archive/upload, not App Review submission or
  public release. Those remain explicit App Store Connect decisions.
