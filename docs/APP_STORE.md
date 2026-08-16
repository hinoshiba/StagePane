# App Store positioning and review notes

## Metadata draft

- **Name:** StagePane
- **Subtitle (EN):** Screen Share Stage
- **Subtitle (JA):** 画面共有専用のステージ
- **Primary category:** Productivity
- **Secondary category:** Utilities
- **Tagline (EN):** A clean stage for everything you share.
- **Tagline (JA):** 見せたいものだけ、ひとつのステージへ。

Suggested English keyword concepts: screen sharing, presentation, meeting,
workspace, privacy, 1080p, demo, presenter, window. Suggested Japanese concepts:
画面共有、プレゼン、会議、共有、ウインドウ、配信、発表. Re-check current
App Store character and duplication rules in App Store Connect before use.

Do not use competitor trademarks in metadata and do not use `virtual display`,
`second monitor`, `independent desktop`, `real display`, or equivalents. The app
creates a normal shareable window, not an `NSScreen`.

## Shipping build route

Use the checked-in `StagePane.xcodeproj`, shared `StagePane-AppStore` scheme,
and `Scripts/archive-app-store.sh`. The target is sandboxed, has no network
entitlement, bundles the privacy manifest, English/Japanese usage strings,
`AppIcon.icns`, help, privacy policy, license, notices, trademark policy, and
brand-asset license. The script requires a publisher-controlled Team ID and the
canonical `stagepane.hinoshiba.com` bundle identifier, verifies the resulting
archive, and deliberately performs no upload. See `RELEASE.md` for the exact
commands and gates.

## Screenshot story

1. **見せたいものだけ、このステージへ。** — Stage and Control Room side by side.
2. **共有する内容を、すばやく選ぶ。** — macOS system picker consent.
3. **相手に見やすい16:9で。** — preset choices and audience frame.
4. **ひと押しで、共有内容を隠す。** — Curtain before/after.
5. **ローカル処理。ソースも公開。** — privacy data flow and OSS proof.

Use real shipping UI, no unsupported claims, no meeting-service logos suggesting
partnership, and no “#1” or ranking guarantee. Localize screenshots and alt text
for Japanese and English.

## Review notes draft

> StagePane is a focused screen-sharing utility. It provides a normal macOS
> window named “StagePane Stage” and a separate Control Room. It does not add a
> display, replace or imitate the macOS desktop, provide an app launcher, modify
> Finder or the Dock, install a driver, use private APIs, or continue running
> after the user quits.
>
> The app can be tested without permission by sharing its neutral Stage window.
> To test source preview: choose “Choose Source,” approve a test window in the
> macOS ScreenCaptureKit system picker, and observe it inside the Stage. The
> StagePane process does not record, encode, write, or transmit frames. Audio and
> microphone capture are disabled. “Stop Preview” ends the stream and flushes
> the final frame. “Curtain” hides output instantly but clearly states that it
> does not stop preview.
>
> StagePane uses SwiftUI, AppKit, AVFoundation display layers, and
> ScreenCaptureKit public APIs. It is sandboxed and has no network entitlement,
> analytics, ads, account, external updater, or license-key mechanism.

Attach a short reviewer video showing both window titles, the permission path,
Curtain disclosure, and Stop Preview. Provide current Zoom/Teams/Meet test
results only as compatibility evidence, not as affiliations.

## Review-risk checklist

- Guideline 2.3.1: metadata matches the normal-window implementation.
- 2.5.1: documented public APIs only.
- 2.5.8: no alternate desktop/home-screen environment.
- 2.5.14: explicit user consent and visible preview status/stop control.
- 4.1: original name, icon, copy, UI, and screenshots.
- 4.2: material utility beyond a blank window: source composition, presets,
  Curtain, safe-area, holding screen, window behavior, privacy controls.
- 5.1: accessible privacy policy and accurate Data Not Collected answers.
- Mac Store rules: sandboxed, self-contained, no self-update or license screen.

Always re-read the live App Review Guidelines before submission; this checklist
is a dated engineering interpretation, not approval or legal advice.

## Accessibility declaration gate

Only claim an App Store Accessibility Nutrition Label feature after all common
tasks pass with it. The release gate covers VoiceOver, Voice Control,
keyboard-only control, sufficient contrast, non-color state cues, Reduce Motion,
Increase Contrast, and text scaling. The video preview must expose one stable
summary rather than announcing every frame.

## Ratings and ranking ethics

Rank cannot be guaranteed. Optimize for first-stage success, retention, honest
metadata relevance, crash-free sessions, accessibility, privacy trust, and
support quality. Request a rating only after at least three successful sessions
and a clean Stop Preview/close boundary using Apple's standard API. Do not offer
rewards, gate features, route low ratings away, or manipulate discovery.
