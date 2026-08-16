# App Store release operations

StagePane is distributed through the Mac App Store. Official binaries are
built and uploaded by Xcode Cloud from immutable semantic-version tags; there
is no local signing, notarization, DMG, archive, or upload procedure.

`./build.sh` remains available only for local development. Its ad-hoc-signed
`dist/StagePane.app` is marked as a development build and must never be
published.

## Xcode Cloud workflow

Complete the app's initial Xcode Cloud setup from Xcode. Edit the suggested
workflow to use a non-Archive **Build** action and run it once from `main`;
the release guard intentionally rejects an Archive without a release tag.
After that setup build, edit the workflow in Xcode or App Store Connect:

- **Name:** `App Store Release`
- **General:** enable **Restrict Editing** and limit workflow administrators to
  the designated release managers
- **Product:** StagePane (`com.hinoshiba.stagepane`), Team `94HVVWXLK3`
- **Repository:** `hinoshiba/StagePane`
- **Start condition:** Tag Changes; include `v*`
  and add no branch, pull-request, or schedule start condition; in this tag
  condition's **Options**, set **Auto-cancel Builds** to **Off** so a later tag
  cannot cancel an in-progress release archive
- **Environment:** the latest released macOS and Xcode; enable **Clean**
- **Action:** Archive, macOS, scheme `StagePane-AppStore`
- **Deployment Preparation:** `TestFlight and App Store`
- **Post-actions:** none by default. Add TestFlight distribution only after an
  intended tester group exists and the release owner approves automatic
  distribution to that exact group.

Keep automatic signing enabled. Xcode Cloud manages the distribution signing
assets; do not store certificates, profiles, App Store Connect keys, or Apple
Account credentials in this repository or in non-secret workflow variables.

After the non-Archive setup build succeeds, remove the generated branch/PR
start conditions from this release workflow and retain only the tag condition
above.

Xcode Cloud assigns the build number used by App Store Connect. Because this is
a macOS app, the build number must increase across all marketing versions. For
an existing app, open **App Store Connect > StagePane > Xcode Cloud > Settings
> Build Number** and set **Next Build Number** to an integer greater than the
largest build already uploaded for StagePane before the first tagged build.

## Protect release authority

Before enabling the release workflow, create an **Active** tag ruleset in
GitHub **Settings > Rules > Rulesets** for the `v*` target pattern. Enable
**Restrict creations**, **Restrict updates**, and **Restrict deletions**, and
allow bypass only for the designated release manager. Create a release tag only
on a reviewed `main` commit. Never move, replace, or reuse it. A permitted tag
creation authorizes Xcode Cloud to build and upload a signed candidate.

## Prepare a release change

Update and review these values in one pull request:

- `Info.plist`: `CFBundleShortVersionString`
- `project.yml`: `MARKETING_VERSION`
- the checked-in Xcode project regenerated with XcodeGen 2.45.4
- `CHANGELOG.md`, App Store metadata, privacy answers, and review notes when
  behavior or claims changed
- `THIRD_PARTY_NOTICES.md` and `docs/sbom.spdx.json` when their inventory or
  version changes

After changing `project.yml`, regenerate and verify the checked-in project:

```bash
/opt/homebrew/bin/xcodegen generate
./Scripts/check-xcodegen-drift.sh --print-lock > Config/XcodeGen.lock
./Scripts/check-xcodegen-drift.sh
```

Run the source gates and manual acceptance matrix before merging:

```bash
./Scripts/release-check.sh
swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
```

Manual acceptance must cover supported macOS versions and architectures,
permission allow/deny/revoke flows, source selection and stopping, all Stage
shapes, Curtain behavior, Spaces/full-screen/display changes, accessibility,
and the currently claimed meeting-app workflows. Record the exact commit,
hardware, OS/app versions, results, and approved exceptions in the release
record.

## Start the cloud build

Only tag the reviewed commit after GitHub CI and manual acceptance pass. The tag
must be exactly `v<major>.<minor>.<patch>` and its version must equal
`MARKETING_VERSION`:

```bash
git tag -s v0.1.0 -m "StagePane 0.1.0"
git push origin v0.1.0
```

`ci_scripts/ci_pre_xcodebuild.sh` rejects an Archive without Xcode Cloud, a
release tag, or a positive Cloud build number, as well as malformed tags,
tag/version mismatches,
or a cloud action configured with the wrong platform, scheme, bundle ID, or
team. It applies the Cloud build number to the temporary Xcode project. A
passing tag build archives the Release configuration and makes the
build available in App Store Connect for TestFlight/App Store use.

## Verify and submit

In the completed Xcode Cloud build and App Store Connect, verify:

- source tag and commit, Xcode/macOS versions, version/build, and archive logs;
- bundle ID `com.hinoshiba.stagepane`, Team `94HVVWXLK3`, App Sandbox,
  Hardened Runtime, privacy manifest, icon, localizations, and legal/help
  resources;
- no unexpected entitlement, embedded executable/framework, absolute
  `LC_RPATH`, updater, analytics, recording, or network path; and
- metadata, screenshots, privacy answers, export compliance, review notes,
  pricing, territories, and release mode against the exact build.

Xcode Cloud artifacts are retained for a limited period, so preserve the
release archive and logs in the private release record.

Tagging authorizes the Xcode Cloud build and upload only. Selecting a build for
an App Store version, distributing to testers, adding it for review, submitting
for review, and releasing it are separate App Store Connect actions. Do not
perform any of them without the release owner's explicit approval.
