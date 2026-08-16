# Third-party notices

StagePane 0.1.1 has no third-party runtime code, SDK, font, model, media, or
binary dependency.

It uses only Apple system frameworks supplied by macOS, including AppKit,
AVFoundation, Combine, CoreFoundation, CoreGraphics, CoreMedia, CoreVideo,
Foundation, QuartzCore, ScreenCaptureKit, and SwiftUI. Those frameworks are not
redistributed in the StagePane application bundle and remain governed by
Apple's applicable terms.

SF Symbols are requested from macOS at runtime and are not bundled as asset
files. The StagePane icon and vector mark were created specifically for this
project and are not derived from SF Symbols or third-party artwork.

The StagePane artwork is project-authored and distributed under Apache-2.0;
separate trademark rights are not granted. See repository file
`Assets/LICENSE.md` (bundled as `BRAND_ASSET_LICENSE.md`) and `TRADEMARKS.md`.

The project studied the public repository
[`hinoshiba/youyaku`](https://github.com/hinoshiba/youyaku) for operational
practices such as signed releases, documentation, and license
inventory. No Youyaku source code, brand asset, model, binary dependency, or
license notice is incorporated into StagePane.

XcodeGen 2.45.4 regenerates and verifies the checked-in Xcode project in
GitHub CI and may also be used during development. XcodeGen is MIT-licensed;
neither its executable nor source is bundled in StagePane, and it is not
required to build the checked-in project. Its license and non-runtime status
are recorded in `docs/LICENSE_AUDIT.md`.

CI uses the MIT-licensed `actions/checkout` action at the exact commit recorded
in `.github/workflows/ci.yml`. It runs only on the CI host and is not included
in any StagePane application or distribution artifact.
