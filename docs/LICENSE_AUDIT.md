# License and distribution audit

Audit date: 2026-08-15<br>
Scope: StagePane 0.1.0 source tree and macOS application bundle

This is an engineering compliance record, not a formal legal opinion.

## Conclusion

The source licensing design supports open-source publication and commercial
sale under Apache License 2.0, provided the license and NOTICE obligations are
preserved and every pre-release legal, trademark, Apple, consumer-law, and
signing gate below is completed. No current default `dist/StagePane.app`
development artifact is approved for public distribution.

There is no third-party runtime dependency in 0.1.0. The application dynamically
links Apple frameworks already present on macOS and bundles only original
StagePane code/artwork plus project legal/help documents. This substantially
reduces license, supply-chain, privacy, and notarization risk.

## Chosen source license: Apache-2.0

Apache-2.0 permits use, modification, reproduction, redistribution,
sublicensing, and commercial sale subject to its conditions. Compared with MIT,
it includes an express contributor patent grant and patent-litigation
termination clause. Redistribution requires the license, preservation of
applicable notices, prominent change notices in modified files, and maintenance
of relevant NOTICE content.

Open source does **not** mean official binaries must be free of charge. Revenue
can come from signed/notarized convenience builds, App Store distribution,
support, training, team features, or hosted services. A permissive license also
means others can lawfully redistribute compatible copies; exclusivity must not
be promised.

Apache Section 6 does not grant product trademark rights. `TRADEMARKS.md`
separates official identity from code rights, but professional clearance and an
identified rights owner are required before public launch.

## Dependency inventory

| Item | Status | Distribution consequence |
|---|---|---|
| Swift standard/runtime libraries | Apple toolchain/system | Governed by Apple toolchain terms; embedded components, if any, are produced by Apple's linker |
| AppKit, AVFoundation, Combine, CoreMedia, CoreVideo, Foundation, ScreenCaptureKit, SwiftUI | Apple system frameworks | Dynamically linked; not copied into app bundle |
| SF Symbols | Requested from macOS at runtime | No symbol artwork files are bundled |
| StagePane icon/mark | Original project artwork | Apache-2.0 covers copyright permission; `TRADEMARKS.md` separately reserves official brand identity |
| Local Swift package product | `StagePaneCore` from this repository | Project-authored code; linked into the Xcode App Store target, not an external dependency |
| External package dependencies | None | No third-party license notice required for runtime code |
| Analytics/ads/updater | None | No SDK or transitive notice inventory |
| XcodeGen 2.45.4 | Optional development-only generator, MIT | No executable or source is bundled; not required to build the checked-in Xcode project |
| `actions/checkout` at `11bd71901bbe5b1630ceea73d27597364c9af683` | CI-only GitHub Action, MIT | Commit-pinned workflow tool; executes on the CI runner and is not included in the app |

The machine-readable inventory is `docs/sbom.spdx.json`. Every release must
compare `Package.swift`, linked frameworks, bundle contents, generated SBOM, and
`THIRD_PARTY_NOTICES.md`.

Direct and Store bundles include `LICENSE.txt`, `NOTICE.txt`,
`THIRD_PARTY_NOTICES.md`, `TRADEMARKS.md`, `BRAND_ASSET_LICENSE.md`,
`PRIVACY.md`, and `HELP.md`. The Store archive script verifies that the legal
and help copies remain byte-identical to repository sources. XcodeGen is used
only to regenerate project metadata; its upstream MIT license is recorded at
<https://github.com/yonaskolb/XcodeGen/blob/2.45.4/LICENSE>.
The CI-only checkout action's MIT license is recorded at
<https://github.com/actions/checkout/blob/11bd71901bbe5b1630ceea73d27597364c9af683/LICENSE>.

## Reference repository review

The project reviewed `hinoshiba/youyaku` as an operational reference. Its source
is MIT-licensed and its current distribution includes separate notices for
llama.cpp, Sparkle, and model licenses. StagePane did not copy or adapt source,
scripts, text, icons, model catalogs, binaries, keys, bundle identifiers, or
product identity from Youyaku. It independently implemented general operational
ideas: Swift Package builds, Developer ID signing, notarization, DMG delivery,
privacy documentation, and OSS community files.

Because no copyrightable Youyaku material is incorporated, its MIT notice is
not a StagePane redistribution requirement. The acknowledgement in README and
`THIRD_PARTY_NOTICES.md` is factual and voluntary.

## Apple distribution analysis

StagePane uses only documented APIs. It does not use private
`CGVirtualDisplay`, install a driver, request root, inject input, or imitate an
alternate macOS desktop.

- **Direct distribution:** use Developer ID Application signing, Hardened
  Runtime, secure timestamp, Apple notarization, and stapling for both app and
  DMG. The build fails closed without credentials.
- **Mac App Store:** archive the checked-in `StagePaneAppStore` Xcode target with
  App Sandbox. The fail-closed archive script checks the final signature,
  entitlements, universal slices, resources, placeholders, and absolute
  `LC_RPATH` entries before Organizer validation. Do not add Sparkle, an external
  license-key system, or an independent updater. Apple approval is never
  guaranteed.
- **Marketing:** describe the product as a “screen share stage” or
  “presentation canvas,” never as a real/virtual display, second monitor, or
  alternate desktop. Misleading capability claims create review and consumer
  risk.

## Commercial release blockers

1. Replace publisher, privacy, support, security, and legal contact placeholders.
2. Obtain counsel review for intended sale countries and Apple agreements.
3. Complete J-PlatPat, USPTO, EUIPO/TMview, and WIPO/common-law trademark
   clearance for `StagePane`, `Stage Pane`, ステージペイン, and phonetic
   variants in relevant classes (at least 9 and 42; assess 38).
4. Confirm publisher control of `stagepane.hinoshiba.com`, register it as the
   explicit Apple App ID, and preserve it as the canonical bundle identifier.
5. For Japanese consumer sales, publish a Specified Commercial Transactions Act
   disclosure covering seller identity, address/phone, responsible person,
   price and extra costs, payment timing/method, delivery, system requirements,
   and cancellation/return terms.
6. Set final pricing, tax, refund, support, warranty, export/sanctions, and
   accessibility claims with professional review.
7. Run the signed compatibility matrix and App Review notes in `APP_STORE.md`.
8. Generate final SBOM/checksums, verify bundle notices, sign an annotated tag,
   and preserve release provenance.

## Contribution policy

Contributions are accepted under Apache-2.0 with Developer Certificate of
Origin sign-off. This supplies a contribution trail without a blanket copyright
assignment. A future proprietary dual-license program would require a separate,
explicit contributor agreement; do not assume DCO alone grants relicensing.
