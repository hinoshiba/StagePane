# StagePane

> 見せたいものだけ、ひとつのステージへ。<br>
> A clean stage for everything you share.

StagePane is an open-source macOS app that creates a dedicated, ordinary
window for screen sharing. Keep its private **Control Room** on your Mac and
share only **StagePane Stage** in Zoom, Microsoft Teams, Google Meet, Webex,
Slack Huddles, Discord, OBS, or another app that can share a window.

StagePane is deliberately **not** a virtual display driver or alternate
desktop. It doesn't modify macOS display configuration and doesn't use private
`CGVirtualDisplay` APIs. With your explicit approval, Apple's public
ScreenCaptureKit picker can mirror a window, app, or display into the Stage.

## Why StagePane

- **A clean share target** — audience content and private controls live in
  separate windows with unmistakable titles.
- **Privacy Curtain** — cover the Stage instantly with `Shift-Command-H`.
- **Exact shapes** — switch between 16:9, 4:3, 9:16, and 1:1 while preserving
  the Stage window identity used by meeting apps.
- **Consent-preserving source picker** — StagePane uses the macOS system picker,
  not a hand-built list of private window names.
- **Local by construction** — no recorder, network client, account, telemetry,
  analytics SDK, advertising SDK, audio capture, or microphone capture.
- **Host controls** — menu-bar actions, all-Spaces mode, always-on-top
  compatibility, Presentation Lock, cursor control, safe-area guides, and
  neutral holding screens.
- **Public APIs and sandboxing** — SwiftUI, AppKit, AVFoundation, and
  ScreenCaptureKit; App Sandbox is enabled in the shipping entitlement file.

## Requirements

- macOS 14 Sonoma or later
- Apple Silicon or Intel Mac
- Xcode 16 or newer, including matching Swift command-line tools, to build

The app requests screen-capture consent only when you choose content to mirror.
Creating and sharing an empty/holding Stage does not itself capture your screen.

## Build and run

```bash
git clone https://github.com/hinoshiba/StagePane.git
cd StagePane
./build.sh
open dist/StagePane.app
```

The default command creates a current-Mac development build. It is ad-hoc
signed, not notarized, and marked **do not distribute** inside the bundle.
Never publish `dist/StagePane.app` from this command. Automated tests can be run
independently:

```bash
swift test
```

Distribution builds require a Developer ID identity and a saved `notarytool`
profile. See [`docs/RELEASE.md`](docs/RELEASE.md); the distribution path fails
closed if signing, notarization, legal contact fields, or release checks are
missing.

A checked-in `StagePane.xcodeproj` and shared `StagePane-AppStore` scheme provide
the separate Mac App Store archive path. XcodeGen is needed only when changing
`project.yml`, not to build the checked-in project. Store archives use the
canonical `stagepane.hinoshiba.com` bundle ID, require the publisher's Team ID,
and are never uploaded automatically. See the
[Mac App Store instructions](docs/RELEASE.md#mac-app-store-track).

## How to use it

1. Open StagePane. Leave **Control Room — Keep Private** on your screen.
2. Select **Choose Source** and approve a window, app, or display in the macOS
   system picker. You can also leave the Stage as a holding screen.
3. In your meeting app, share **StagePane Stage — Share This Window**.
4. Use `Shift-Command-H` whenever you need the Privacy Curtain.
5. Select **Stop Preview** to end ScreenCaptureKit capture and discard the
   displayed frame.

On macOS 15 and later, **Switch Active Share** can ask a compatible, already
active ScreenCaptureKit sharing session to switch to the Stage. It cannot start
or control every meeting app's sharing session.

## Architecture

```text
User-approved window/app/display
              │  ScreenCaptureKit (video only, up to 30 fps)
              ▼
      AVSampleBufferDisplayLayer
              │  memory only; no encoder or writer
              ▼
        StagePane Stage  ─────►  meeting app shares this window

        Control Room     (separate host-only controls)
```

The project is a Swift Package with a testable framework-free core and a native
AppKit/SwiftUI executable. Details and constraints are in
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Privacy and security

StagePane collects no data. Source frames are displayed from memory and are not
saved or sent by StagePane. The app has no network entitlement. Settings such as
theme and window behavior are stored in the app's sandboxed `UserDefaults`.

- Privacy details: [`docs/PRIVACY.md`](docs/PRIVACY.md)
- Security reporting: [`SECURITY.md`](SECURITY.md)
- Dependency and license audit: [`docs/LICENSE_AUDIT.md`](docs/LICENSE_AUDIT.md)

Your meeting app is a separate product with its own capture, transmission,
recording, and privacy behavior.

## Open source and commercial distribution

Source code is available under the [Apache License 2.0](LICENSE), which permits
commercial use, modification, redistribution, and sale subject to its terms.
Official signed binaries, support, and services may be sold even though the
source is open.

The source license does not grant rights to present a fork as an official
StagePane release. See [`TRADEMARKS.md`](TRADEMARKS.md). Official binary and
commercial distribution remain blocked until professional trademark clearance
and legal/support contacts are complete. This repository is product engineering
work, not legal advice.

## Clean-room origin and acknowledgements

StagePane was independently authored. The public MIT-licensed
[`hinoshiba/youyaku`](https://github.com/hinoshiba/youyaku) repository was
reviewed only as an operational reference for build, notarization, release, and
OSS documentation practices. No Youyaku code, assets, models, binaries, product
copy, keys, or brand elements are incorporated. See
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md), sign commits off under the Developer
Certificate of Origin, and follow [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

## 日本語概要

StagePaneは、画面共有で選択するための専用ウインドウを作るmacOSアプリです。
本物の仮想ディスプレイや別デスクトップではなく、Appleの公開APIだけを使った
プレゼンテーション・キャンバスです。操作用のControl Roomは手元に残し、相手には
Stageだけを見せます。録画、外部送信、アカウント、広告、解析はありません。
