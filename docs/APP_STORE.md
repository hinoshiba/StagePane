# App Store positioning and review notes

## Metadata draft

- **Name:** StagePane
- **Subtitle (EN):** Screen Share Stage
- **Subtitle (JA):** 画面共有専用のステージ
- **Primary category:** Productivity
- **Secondary category:** Utilities
- **Tagline (EN):** A clean stage for everything you share.
- **Tagline (JA):** 見せたいものだけ、ひとつのステージへ。
- **Privacy Policy URL (JA):** https://stagepane.hinoshiba.com/privacy/
- **Privacy Policy URL (EN):** https://stagepane.hinoshiba.com/en/privacy/
- **Support URL (JA):** https://stagepane.hinoshiba.com/#support
- **Support URL (EN):** https://stagepane.hinoshiba.com/en/#support

Suggested English keyword concepts: screen sharing, presentation, meeting,
workspace, privacy, 1080p, demo, presenter, window. Suggested Japanese concepts:
画面共有、プレゼン、会議、共有、ウインドウ、配信、発表. Re-check current
App Store character and duplication rules in App Store Connect before use.

Do not use competitor trademarks in metadata and do not use `virtual display`,
`second monitor`, `independent desktop`, `real display`, or equivalents. The app
creates a normal shareable window, not an `NSScreen`.

## Shipping build route

Push a reviewed `v<major>.<minor>.<patch>` tag and let the `App Store Release`
Xcode Cloud workflow archive the checked-in `StagePane.xcodeproj` with the
shared `StagePane-AppStore` scheme. The target is sandboxed, has no network
entitlement, grants read/write access only to locations the user explicitly
selects for Audience PNG export, and bundles the privacy manifest, English/Japanese usage strings,
`AppIcon.icns`, help, privacy policy, license, notices, trademark policy, and
brand-asset license. Xcode Cloud uses automatic signing for Team `94HVVWXLK3`
and the canonical `com.hinoshiba.stagepane` bundle identifier. See
`RELEASE.md` for workflow settings, tag/version gates, and handoff steps.

The submitted Mac App Store binary includes Arrange and Draw, but omits Control
mode and every cross-application Accessibility permission/action path. Control
is available only in the unsandboxed local development build and must not appear
in App Store metadata, screenshots, review media, or reviewer instructions. No
direct-distribution build currently ships.

## Screenshot story

1. **見せたいものだけ、このステージへ。** — the clean Share Stage beside the
   private Stage Workspace, making the share/private boundary unmistakable.
2. **最大4つを、追加・一時停止・確認して解除。** — the separate Control Room's
   source list and removal caution.
3. **配置・手書き・撮影を、大きな画面で。** — the private Workspace with the
   Mac App Store build's Arrange and Draw modes, bounded in-memory ink, and
   explicit Copy/Save Audience Image actions.
4. **レーザーとロゴを、発表に合わせる。** — laser color/size/glow and the
   default-on StagePane mark.
5. **ひと押しで隠し、終わったら完全停止。** — Curtain with the mark and Stop All.

Use real shipping UI, no unsupported claims, no meeting-service logos suggesting
partnership, and no “#1” or ranking guarantee. Export opaque 2880×1800 images
from the exact Store candidate, and localize screenshots and alt text for
Japanese and English.

## Review notes draft

> StagePane is a focused screen-sharing utility with three normal macOS windows:
> “StagePane Stage” is the clean window to share, “Stage Workspace” is the
> private live canvas for arranging, drawing, and taking an Audience Stage PNG,
> and “Control Room” is the private source-management and settings window. It
> does not add a display, replace or imitate the macOS desktop, provide an app
> launcher, modify Finder or the Dock, install a driver, use private APIs, or
> continue running after the user quits.
>
> The app can be tested without permission by sharing its neutral Stage window.
> To test source composition, choose “Add Source,” approve exactly one test
> window, app, or display in the macOS ScreenCaptureKit system picker, and
> repeat for up to four sources. Each source appears in the private source list,
> where “Pause” stops only that stream while its last frame stays visible,
> “Resume” starts it again, “Replace” reopens the picker for only that item, and
> “Remove” asks for confirmation, ends only its stream, and discards its frame.
> In Stage Workspace, drag or resize tiles in Arrange mode, or use “Auto
> Arrange.” These gestures change only StagePane's composition. The Mac App
> Store build provides Arrange and Draw modes only. It does not include Control
> mode, perform actions in another application, or request macOS Accessibility
> or Input Monitoring permission. Draw mode adds bounded in-memory vector ink to
> both the private Workspace and public Stage; the Curtain hides it and Stop
> All/final-source removal clears it. The StagePane process does not record,
> encode, automatically save, or transmit frames. Only an explicit “Copy
> Audience Image” or “Save Audience Image…” action creates one local PNG of the
> clean Stage; Copy uses the pasteboard, and Save writes only to the location the
> user chooses in the macOS save panel. Audio and microphone capture are
> disabled. “Stop All” ends every source and flushes the final frames from both
> local display surfaces. “Curtain” hides only the public Stage and does not
> bring its window to the front. It does not pause any source; unpaused streams
> continue and the private Stage Workspace remains available for preparation.
> Control Room contains source management and settings, not a live preview.
> Stage Workspace and Control Room must remain private.
>
> Under “Appearance,” the pointer can remain standard, appear as a local red
> laser dot in the Stage, or be hidden. Its color, size, and glow are adjustable,
> and the dot appears only on the frontmost
> source; when that source is paused there is no dot and no fallback to a source
> behind it. Laser pointer mode does not request an additional permission and
> does not retain pointer coordinates. A translucent
> StagePane mark is enabled by default at the lower-right of the holding screen,
> shared content, and Curtain, and is mirrored in the private Workspace.
>
> StagePane uses SwiftUI, AppKit, AVFoundation display layers, and
> ScreenCaptureKit public APIs. It is sandboxed and has no network entitlement,
> analytics, ads, account, external updater, license-key mechanism,
> cross-application control feature, or Accessibility permission request.

Attach a short reviewer video showing all three window titles and roles, adding
two sources, per-source pause/resume, replace, removal confirmation, drag,
resize, all four Quick Layout presets, the Arrange/Draw switch, unchanged physical pointer,
Draw/Clear/Curtain behavior, explicit Copy/Save Audience Image actions, the
watermark, and Stop All. The video must use the exact Mac App Store candidate
and must not show Control mode or an Accessibility permission prompt. Provide
current Zoom, Teams, and Meet test results only as compatibility evidence, not
as affiliations.

## Review-risk checklist

- Guideline 2.3.1: metadata matches the normal-window implementation.
- 2.5.1: documented public APIs only. The submitted sandboxed binary contains no
  Control mode, cross-application Accessibility action path, raw mouse/keyboard
  event synthesis, keyboard/drag forwarding, or event tap.
- 2.5.8: no alternate desktop/home-screen environment.
- 2.5.14: explicit user consent and visible preview status/stop control.
- 4.1: original name, icon, copy, UI, and screenshots.
- 4.2: material utility beyond a blank window: source composition, confirmation
  and pause controls, Arrange and Draw modes, presets, Curtain, drawing, laser/
  watermark appearance, safe-area, holding screen, and window behavior.
- 5.1: accessible privacy policy and accurate Data Not Collected answers.
- Mac Store rules: sandboxed, self-contained, no self-update or license screen.

Always re-read the live App Review Guidelines before submission; this checklist
is a dated engineering interpretation, not approval or legal advice.

## Accessibility declaration gate

Only claim an App Store Accessibility Nutrition Label feature after all common
tasks pass with it. The release gate covers VoiceOver, Voice Control,
keyboard-only control, sufficient contrast, non-color state cues, Reduce Motion,
Increase Contrast, and text scaling. The Stage Workspace canvas must expose
stable editor/source-tile controls and must not announce individual video
frames.

## Ratings and ranking ethics

Rank cannot be guaranteed. Optimize for first-stage success, retention, honest
metadata relevance, crash-free sessions, accessibility, privacy trust, and
support quality. Request a rating only after at least three successful sessions
and a clean Stop All/close boundary using Apple's standard API. Do not offer
rewards, gate features, route low ratings away, or manipulate discovery.
