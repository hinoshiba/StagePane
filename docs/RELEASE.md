# Release operations

StagePane has two separate shipping tracks: signed/notarized direct distribution
and a sandboxed Mac App Store Xcode archive. Never reuse a DMG build as a Store
submission. The default `./build.sh` output is a local development artifact and
is not a third shipping track.

## Fail-closed principles

- Distribution requires a universal `arm64` + `x86_64` binary.
- A Developer ID identity and `notarytool` keychain profile are mandatory.
- The app is sandboxed and signed with Hardened Runtime and secure timestamp.
- Both the app and DMG are notarized and stapled before a checksum is emitted.
- Contact/legal placeholders block distribution.
- Final direct and Store app binaries contain no absolute `LC_RPATH` entries.
- Tests, plist validation, narrow static guards for known forbidden API names,
  forbidden-entitlement checks, notices, SBOM version, and privacy manifest are
  release gates. They complement, but do not replace, Xcode validation, App
  Review, or a human binary/API audit.
- No auto-updater is bundled. This keeps the same source compatible with the
  Mac App Store build and avoids an additional supply chain.

## One-time setup

1. Install Xcode 16 or newer. The macOS 15 SDK declaration used by the optional
   share-handoff feature is required even though the deployment target is
   macOS 14.
2. Join the Apple Developer Program.
3. Create/import a **Developer ID Application** certificate.
4. Store notarization credentials in the Keychain:

   ```bash
   xcrun notarytool store-credentials stagepane-notary \
     --apple-id <APPLE_ID> \
     --team-id <TEAM_ID> \
     --password <APP_SPECIFIC_PASSWORD>
   ```

5. Register the explicit App ID `com.hinoshiba.stagepane` in the publisher's
   Apple Developer account. Keep this bundle identifier stable forever after
   the first public release.
6. Replace every `RELEASE_*_PLACEHOLDER`, finish trademark/legal review, and
   verify the privacy policy matches the exact shipping binary.
7. Store certificates and recovery instructions outside the repository. Define
   incident, revocation, rotation, and successor-maintainer procedures.

## Versioning

Before each release update all of the following in one reviewed change:

- `Info.plist`: `CFBundleShortVersionString` and monotonically increasing
  `CFBundleVersion`
- `CHANGELOG.md`
- `THIRD_PARTY_NOTICES.md` version, if dependency scope changed
- `docs/sbom.spdx.json`: name, namespace, version, and creation timestamp
- App Store metadata and privacy answers, if behavior changed
- `project.yml` plus the checked-in Xcode project build/version settings

Do not tag before the exact release commit has passed CI and manual acceptance.

## Local development bundle (never publish)

`./build.sh` creates `dist/StagePane.app` for local testing on the current Mac.
It is ad-hoc signed, not notarized, not guaranteed universal, and contains
`DEVELOPMENT_BUILD_DO_NOT_DISTRIBUTE.txt`. CI may build and inspect it, but it
must never be uploaded to a release, store, package manager, or customer.

## Build, sign, notarize, and package

```bash
export STAGEPANE_DIST_IDENTITY='Developer ID Application: Publisher (TEAMID)'
export STAGEPANE_NOTARY_PROFILE='stagepane-notary'
./build.sh --dist
```

Outputs:

- `dist/StagePane.app` — universal, signed, notarized, stapled
- `dist/StagePane-X.Y.Z.dmg` — signed, notarized, stapled
- `dist/StagePane-X.Y.Z.dmg.sha256`

The script exits before distribution if credentials or compliance fields are
missing. Do not weaken those checks to create a public build.
The checksum file records only the DMG filename, not a developer-machine
absolute path, so verification remains portable after download.

## Independent verification

```bash
codesign --verify --deep --strict --verbose=2 dist/StagePane.app
codesign -d --entitlements :- dist/StagePane.app
spctl --assess --type execute --verbose=4 dist/StagePane.app
xcrun stapler validate dist/StagePane.app
xcrun stapler validate dist/StagePane-*.dmg
(cd dist && shasum -a 256 -c StagePane-*.dmg.sha256)
```

Mount the DMG on a clean, non-developer Mac. Copy the app to `/Applications`,
launch it offline, verify Gatekeeper, then exercise first-run consent and every
privacy state.

## Signed manual acceptance

Required before each stable release:

- macOS 14, 15, and current macOS; Apple Silicon and Intel where available
- clean install, update-over-existing install, and settings migration
- consent approved, declined, later revoked, and re-approved
- window, app, and display sources; minimized/closed source; child popover
- 16:9, 4:3, 9:16, 1:1; Retina/non-Retina; one/multiple displays
- Spaces, Stage Manager, full-screen source, sleep/wake, display unplug/replug
- Curtain latency and clear disclosure that it does not stop capture
- Stop Preview flushes the final image and system privacy indication ends
- Presentation Lock can always be disabled from Control Room/menu bar
- VoiceOver, keyboard-only, Voice Control, Increase Contrast, Reduce Motion,
  Differentiate Without Color, and large text
- two-hour 1080p run with CPU/GPU/memory/frame-drop observation
- share candidate title, thumbnail, aspect, source changes, and stop behavior in
  Zoom, Teams, Meet/Safari, Meet/Chrome, Webex, Slack Huddle, Discord, and OBS

Record results, OS/app versions, hardware, regressions, and waivers in the
release issue. A meeting application's behavior may change independently; never
claim universal compatibility without current evidence.

## Publication order

1. Freeze and review source, licenses, SBOM, policy, metadata, and release notes.
2. Pass CI and manual signed acceptance.
3. Build and independently verify final artifacts.
4. Create a signed annotated tag pointing to the reviewed commit.
5. Create a draft GitHub Release and upload DMG, checksum, SBOM, and notes.
6. Have a second maintainer verify tag/artifact hashes and Gatekeeper status.
7. Publish the release; only then update the website/Homebrew metadata.
8. Monitor crash/support channels and keep a rollback announcement ready.

Staging, committing, pushing, tagging, and creating a GitHub Release are separate
maintainer decisions and are not performed by `build.sh`.

## Mac App Store track

The checked-in `StagePane.xcodeproj` contains the `StagePaneAppStore` target and
shared `StagePane-AppStore` scheme. It builds the local `StagePaneCore` package
product, uses only public Apple frameworks, enables App Sandbox and Hardened
Runtime, treats warnings as errors under complete strict-concurrency checking,
and creates a universal macOS archive.

Before archiving, replace every release placeholder and confirm that the
publisher's Apple Developer account contains the explicit App ID
`com.hinoshiba.stagepane`. Then run:

```bash
export STAGEPANE_APPSTORE_TEAM_ID='TEAMID1234'
export STAGEPANE_APPSTORE_BUNDLE_ID='com.hinoshiba.stagepane'
./Scripts/archive-app-store.sh
```

The script creates an `.xcarchive` only. It does not validate with App Store
Connect, upload, submit for review, or publish. After it succeeds, an authorized
maintainer must use Xcode Organizer to validate and distribute the exact archive.

The archive gate verifies the requested bundle ID, signature, sandbox/no-network
entitlements, `arm64` + `x86_64` slices, absence of absolute `LC_RPATH` entries,
absence of release placeholders, and byte-identical legal/help resources. It
also requires `AppIcon.icns`, `PrivacyInfo.xcprivacy`, and localized English and
Japanese `InfoPlist.strings`.

The Store build must also:

- use the publisher-controlled `com.hinoshiba.stagepane` App ID and matching
  distribution provisioning;
- retain App Sandbox;
- contain no Sparkle, self-updater, license-key screen, driver, private API, or
  separately installed executable;
- use App Store purchase/StoreKit rules for digital features;
- provide an accurate privacy policy URL and App Privacy answers;
- be archived/uploaded with Apple-provided Xcode tooling;
- use the review notes and exact limitation copy in `APP_STORE.md`.

Submit an early feature-complete prototype before investing in Store-exclusive
commercial infrastructure. App Review approval cannot be guaranteed.

`project.yml` is the source for project-structure changes. It currently targets
XcodeGen 2.45.4. XcodeGen is an optional MIT-licensed development tool: its
executable/source is not bundled, and the checked-in `.xcodeproj` can be built
without installing it. If `project.yml` changes, regenerate with
`/opt/homebrew/bin/xcodegen generate` (or an equivalent verified installation),
review the generated diff, and run both CI build paths again.
Run `./Scripts/check-xcodegen-drift.sh` before committing. After an intentional
regeneration, refresh `Config/XcodeGen.lock` with
`./Scripts/check-xcodegen-drift.sh --print-lock > Config/XcodeGen.lock`, review
the lock diff, and rerun the check. CI verifies the locked input and generated
project even when XcodeGen itself is not installed.
