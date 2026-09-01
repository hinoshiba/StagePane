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
- Start every release from a clean local `main` equal to the canonical remote
  `main`. Prepare the version, build floor, metadata, and generated project on
  `codex/release-<version>`. Every release commit must be cryptographically
  signed and carry a valid DCO `Signed-off-by` trailer.
- Release changes must go through a non-draft pull request. Require review,
  passing pull-request CI, and the exact-candidate manual acceptance record
  before a normal merge commit; do not squash or rebase away the reviewed
  signed release commit. Before tagging, require the merged `main` tree to be
  identical to the accepted release tree and wait for merged-`main` CI to pass;
  if the tree differs, repeat review and manual acceptance on exact `main`.
- Official binaries are archived locally from a reviewed `main` commit carrying
  an annotated signed `v<major>.<minor>.<patch>` tag that is never moved or
  reused. Use only the checked-in
  `Scripts/archive-app-store.sh` entrypoint; it archives the shared
  `StagePane-AppStore` scheme and opens the verified archive in Xcode Organizer.
- Do not add another signing, notarization, DMG, archive, export, or upload path.
- Keep automatic signing enabled for the checked-in `StagePane-AppStore`
  scheme. Xcode manages distribution signing for Team `94HVVWXLK3`; do not add
  certificate fingerprints, profiles, or private signing material to the
  repository.
- The tag version must equal `MARKETING_VERSION`. Build numbers are assigned by
  the release owner in the checked-in project and, because this is a macOS app,
  must remain monotonically increasing across marketing versions.
- Opening Xcode Organizer does not authorize upload. When upload is separately
  authorized, the release owner must privately verify Distribution Summary and
  perform the upload manually from that same Mac. Do not add an automated,
  scripted, or alternate upload path.
- After upload, wait for the exact version/build to finish App Store Connect
  processing. Selecting the build, saving product-page metadata, adding the
  version for review, submitting it, and releasing it are auditable actions
  requiring explicit release-owner authorization. Set release mode before
  submission: manual release keeps public release as a later authorization;
  automatic release after approval requires approval of that future release at
  Submit-for-Review time. Never upload the same build again merely because it
  is still processing.
- Creating the verified local archive does not authorize upload, App Review
  submission, or public release. Those remain explicit Xcode Organizer and App
  Store Connect decisions.
