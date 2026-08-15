# Architecture

## Product boundary

StagePane is a presentation canvas implemented as a normal `NSWindow`. It is
intended to appear in meeting applications' *window* share pickers. It is not an
`NSScreen`, is not listed in macOS Display Settings, and cannot host or directly
control arbitrary application windows.

The project explicitly excludes undocumented `CGVirtualDisplay` APIs, kernel or
DriverKit display drivers, Accessibility event injection, audio capture,
recording, remote control, and a Finder/Dock-like alternate desktop.

## Components

```text
StagePaneApplication
└── StagePaneAppDelegate
    └── AppController ─────────────── settings / actions / lifecycle
        ├── ControlRoomWindowController
        │   └── ControlRoomView       private controls
        ├── StageWindowController
        │   └── StageView             public share surface
        ├── StatusItemController      menu-bar recovery path
        └── CaptureCoordinator
            ├── SCContentSharingPicker
            ├── SCStream              video only
            └── SampleBufferRenderer
                ├── AVSampleBufferVideoRenderer  serial render queue
                └── AVSampleBufferDisplayLayer   Stage layer hierarchy
```

`StagePaneCore` contains platform-light preset and message rules. It is tested
without creating windows. The executable target owns AppKit, SwiftUI, and
ScreenCaptureKit integration.

## Data flow and privacy invariant

1. A person invokes **Choose Source**.
2. `SCContentSharingPicker.shared` presents macOS-owned consent UI. StagePane's
   bundle identifier is excluded to prevent recursive self-selection.
3. The returned `SCContentFilter` configures a single `SCStream` at up to 30 fps.
   Audio and microphone capture are disabled.
4. Valid `CMSampleBuffer` objects are enqueued into the macOS 14
   `AVSampleBufferVideoRenderer` owned by the Stage's
   `AVSampleBufferDisplayLayer`.
5. There is no `AVAssetWriter`, `VideoToolbox` encoder, file writer, pasteboard
   path, OCR, network session, analytics SDK, or telemetry client.
6. **Stop Preview**, app termination, or stream failure flushes the display
   layer. Selected source metadata is not persisted.

The Privacy Curtain hides the layer but intentionally does not stop the stream;
the UI says so. This makes the curtain instant. **Stop Preview** is the explicit
capture-termination control.

## Window invariants

- Stage is an opaque, titled, resizable normal window with a stable instance and
  title. `sharingType = .readOnly` communicates shareability to compatible APIs.
- Control Room has an explicit “Keep Private” title. `sharingType = .none` is
  best-effort legacy behavior and is never treated as a security boundary.
- Meeting applications may still list Control Room. The user-facing workflow
  always instructs people to select the Stage by name.
- Aspect presets use `contentAspectRatio`; changing shape does not recreate the
  window or change its `CGWindowID`.
- Always-on-top and all-Spaces behaviors are opt-in. Defaults match a normal
  document window.
- Presentation Lock prevents accidental close/minimize; it never traps input.

## Threading

ScreenCaptureKit delivers video buffers on one dedicated serial queue. The
`AVSampleBufferVideoRenderer` is enqueued and flushed on that same render queue;
there is no per-frame hop to the main queue. Only AppKit view/layer hierarchy
work and observable UI state run on the main actor. Stream generations prevent
completion callbacks from an old source from overwriting a newer session.

## Failure behavior

- Picker cancellation keeps an existing preview, or returns to idle if there
  was none.
- Start and runtime errors become a visible **Needs Attention** state in Control
  Room. Stage falls back to a neutral background when no valid preview exists.
- Permission revocation is treated as an ordinary recoverable error, with a
  direct link to System Settings.
- A source that is minimized may stop producing frames because this is a
  ScreenCaptureKit limitation; StagePane does not misrepresent it as a virtual
  display.

## Compatibility test matrix

Release acceptance requires signed-app testing on current macOS 14, 15, and 26
updates, Apple Silicon and Intel where available, Retina and non-Retina screens,
multiple Spaces, Stage Manager, external display attach/detach, sleep/wake, and
at least Zoom, Microsoft Teams, Google Meet in Safari and Chrome, Webex, Slack
Huddles, Discord, and OBS.

TCC consent and third-party meeting pickers are not stable CI automation
surfaces. Core state and build checks run in CI; signed manual acceptance uses
the checklist in `docs/RELEASE.md`.
