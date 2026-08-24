# Architecture

## Product boundary

StagePane is a presentation canvas implemented as a normal `NSWindow`. It is
intended to appear in meeting applications' *window* share pickers. It is not an
`NSScreen`, is not listed in macOS Display Settings, and cannot host or directly
reparent arbitrary application windows. It is not a general remote desktop or
alternate input system: StagePane never forwards clicks, keys, or drags to a
source application and does not request Accessibility or Input Monitoring
permission.

The project explicitly excludes undocumented `CGVirtualDisplay` APIs, kernel or
DriverKit display drivers, raw mouse/keyboard event synthesis, keyboard/drag
forwarding, event taps, audio capture, recording, unattended remote control, and
a Finder/Dock-like alternate desktop.

## Components

```text
StagePaneApplication
└── StagePaneAppDelegate
    └── AppController ─────────────── settings / actions / lifecycle
        ├── StageWorkspaceWindowController
        │   └── StageWorkspaceView    private unified working window
        │       ├── StageLayoutEditor Arrange / Draw
        │       ├── Sources           per-source lifecycle controls
        │       ├── Stage Settings / Appearance
        │       └── Permissions / Privacy / About
        ├── StageWindowController
        │   └── StageView             chrome-free public share surface
        ├── StageWindowSnapshotter    explicit clean Stage PNG copy/save
        ├── StatusItemController      menu-bar recovery path
        ├── StageAnnotationStore      session-only Stage-wide vector ink
        └── CaptureCoordinator
            ├── SCContentSharingPicker
            ├── StageLayout           normalized frame / z-order by SourceID
            └── CaptureSession[0...4]
                ├── SCStream          one independently consented source
                └── CaptureSourceRenderers
                    ├── Stage SampleBufferRenderer
                    └── Workspace Preview SampleBufferRenderer
```

`StagePaneCore` contains platform-light preset, message, pointer
projection, bounded annotation, and normalized multi-source layout rules. It is
tested without creating windows.
The executable target owns AppKit, SwiftUI, and ScreenCaptureKit integration.

## Data flow and privacy invariant

1. A person invokes **Add Source**. Only one picker request may be active.
2. `SCContentSharingPicker.shared` presents macOS-owned consent UI. StagePane's
   bundle identifier is excluded to prevent recursive self-selection. The
   returned approval is scoped to the chosen content and capture session;
   StagePane neither requests nor models a separate broad Screen Recording
   permission.
3. The returned `SCContentFilter` represents one window, application, or
   display. StagePane creates one independent `SCStream` for it at up to 30 fps.
   Repeating this flow adds up to four sources; multiple-selection picker modes
   are deliberately disabled so every source can be configured and removed
   independently. Audio and microphone capture are disabled.
4. Each valid `CMSampleBuffer` is enqueued into two macOS 14
   `AVSampleBufferVideoRenderer` surfaces: one in the public Stage composition
   and one in the private Stage Workspace editor. Both consume the same
   ScreenCaptureKit buffer; there is no pixel copy or encoded preview path.
   Each stream uses a source-aspect IOSurface capped to its tile's pixel budget,
   so the display layer performs the only letterbox fit and four sources do not
   each allocate a full-Stage surface. Complete-frame `contentRect`,
   `contentScale`, and display-scale metadata are debounced to follow live
   source-window aspect changes. A dimension-only reconfiguration keeps the
   last valid frame visible until its replacement arrives instead of flushing
   a static slide to black.
5. `StageLayout` maps each stable source ID to a top-left-origin normalized
   rectangle and ordered z-position. Arrange-mode drag and resize update only
   this local composition.
6. Draw mode stores one bounded, normalized vector-ink document in memory. Both
   the private Workspace and public Stage render that document, while the Curtain
   covers it on the public Stage. Undo/Clear mutate the document; Stop All or
   removal of the final source clears it. No ink is serialized or logged. Draw
   also applies an effective hidden pointer style without replacing the saved
   preference; Arrange restores the latest user-selected style.
7. In laser-pointer mode, the native captured pointer is disabled for every
   stream. One local `CAShapeLayer` overlay is enabled only for the frontmost
   source in `StageLayout`; it maps the current pointer through that frame's
   `screenRect`, `contentRect`, and scale metadata into its aspect-fit
   rectangle. If the frontmost source is paused, no pointer overlay is enabled
   and ownership does not fall through to a lower source. Draw mode removes the
   overlay, stops pointer-location sampling, and configures streams without a
   captured system cursor. Video frames remain on the zero-copy display path.
8. Per-source **Pause** stops that source's `SCStream` while leaving its last
   frame in both renderers and its tile in `StageLayout`. **Resume** restarts
   the same stream. Pause is therefore a frozen-frame state, not teardown.
9. A screenshot is created only after a person explicitly chooses **Copy
    Audience Image** or **Save Audience Image…** in the private Workspace.
    `StageWindowSnapshotter`
    rasterizes the clean Stage content view at the selected preset's exact pixel
    dimensions. It temporarily substitutes immutable images of the latest
    picker-authorized source frames while rendering, then restores the live
    layers synchronously. The result therefore includes the current audience
    Curtain or content, ink, watermark, the safe-area guide when enabled, and
    the pointer when visible, but never Workspace navigation, controls, or
    title-bar chrome. Copy writes the one PNG to the macOS pasteboard; Save
    writes it only to the location selected in `NSSavePanel`.
    The Store sandbox grants user-selected read/write access solely for that
    explicit destination.
    Cancel writes nothing. No new screen-capture permission or unrelated-window
    enumeration is used.
10. There is no `AVAssetWriter`, `VideoToolbox` recording encoder, automatic
    screenshot or file writer, OCR, network session, analytics SDK, or telemetry
    client. The explicit one-shot screenshot path above is the only frame export.
11. Per-source **Remove**, **Stop All**, app termination, or stream failure first
   invalidates output, stops the corresponding stream, removes its output, and
   waits for both display renderers to drain and discard their last image.
   Selected source metadata and layout are not persisted.

The Privacy Curtain hides the public Stage but intentionally does not stop its
streams; the UI says so. The private Workspace remains visible so a layout can
be prepared safely. **Stop All** is the explicit
complete-capture termination control. Toggling the Curtain changes the public content in place;
it does not order the Stage window to the front.

## Permission model

The persistent Workspace **Permissions** view describes the picker-scoped
screen-sharing access path:

- Screen sharing is not represented as an app-wide allow/deny switch. Each
  `SCContentSharingPicker` interaction is the consent UI, and its returned
  filter authorizes only the selected window, application, or display for that
  capture session. Cancel grants nothing. The app does not request separate,
  broad Screen Recording access or expose a Screen Recording settings step.
  Removing the source or stopping all sources ends the scoped access.
StagePane contains no cross-application input path and requests neither
Accessibility nor Input Monitoring permission.

## Window invariants

- Stage is an opaque, titled, resizable normal window with a stable instance and
  title. It contains no editing toolbar or private controls. `sharingType =
  .readOnly` communicates shareability to compatible APIs.
- Stage Workspace has an explicit “Keep Private” title. Its name and in-product
  warning, not an unsupported `sharingType = .none` capture-exclusion hint, are
  the boundary. Application sharing, full-display sharing, or a meeting app may
  include the private window.
- Stage Workspace enforces a 900×620-point minimum for its Canvas, Docker-style
  navigation, source management, and settings.
- The user-facing workflow always instructs people to select the exact Stage
  window by name, never the StagePane application or full display when the
  Workspace must remain private.
- Closing Workspace ends an in-progress ink stroke, but does not close Stage,
  clear completed ink, or stop capture.
  Closing the public Stage retains the stricter behavior: it covers output and
  stops active capture.
- Aspect presets use `contentAspectRatio`; changing shape does not recreate the
  window or change its `CGWindowID`.
- Always-on-top and all-Spaces behaviors are opt-in. Defaults match a normal
  document window.
- Presentation Lock prevents accidental close/minimize; it never traps input.

## Threading

ScreenCaptureKit delivers every source's video buffers on one dedicated serial
queue. Both `AVSampleBufferVideoRenderer` instances for a source are enqueued
and flushed through that queue; there is no per-frame hop to the main queue.
Only AppKit view/layer hierarchy, normalized placement, and observable UI state
run on the main actor. Stable source IDs are separate from stream-generation
tokens, preventing callbacks from a retiring stream from affecting another
source or replacement.

Content-filter and configuration updates are serialized per source. A later
system-picker update replaces any pending filter, and output-size changes keep
the last valid image visible until a frame from the new surface arrives. Removal
sets a durable output-suppressed state before asking ScreenCaptureKit to stop,
so no late completion can reveal a source after a failed stop.

Pause and resume use explicit transition states. A successful pause stops the
`SCStream` without flushing either renderer; resume starts that same stream and
new frames replace the held image normally. Removal and Stop All still suppress
output and flush the retained image whether a source is running or paused.

Pointer geometry is scoped to the same stream generation and cleared on stop,
blank/suspended frames, or flush. Source replacement updates that geometry only
when a replacement frame is actually displayed, preserving the prior image in
the meantime. A 60 Hz main-run-loop ticker runs only while a red-dot snapshot is
active and moves only the lightweight overlay layer. During a live
system-to-red-dot change, the overlay remains disabled until ScreenCaptureKit
accepts the cursorless configuration and a later complete frame is displayed;
the previous image remains visible instead of being flushed to black.
Front-to-back order alone selects the red-dot owner. Pausing that owner disables
its overlay without reassigning the dot to another source; resuming restores its
eligibility while preserving the same z-order.

Each renderer also retains a lock-protected reference to its latest complete
frame solely so an explicit screenshot can rasterize the already-authorized
pixels. The reference is replaced as playback advances, survives Pause with the
same held frame, and is cleared by deactivate/flush. Screenshot layer
substitution and restoration run synchronously on the main actor; the generated
PNG is independent before source removal or Stop All can drain the live layers.

## Failure behavior

- Picker cancellation keeps all existing sources, or returns to idle if there
  were none.
- Start and runtime errors become a visible **Needs Attention** state in
  Workspace. A failure in one source does not stop another healthy source.
- Removing a source hides its output immediately. If ScreenCaptureKit refuses
  to stop it, the row remains in a capture-active warning state for an explicit
  retry; StagePane does not silently claim that capture ended.
- Picker cancellation or loss of a selected source is treated as an ordinary
  recoverable session error; the user can choose that source again without a
  separate broad Screen Recording permission request.
- A source that is minimized may stop producing frames because this is a
  ScreenCaptureKit limitation; StagePane does not misrepresent it as a virtual
  display.
- Screenshot actions fail visibly rather than exporting a black source when a
  visible tile has not produced a complete frame. Canceling Save does not write
  a file or alter the clipboard.

## Compatibility test matrix

Release acceptance requires signed-app testing on current macOS 14, 15, and 26
updates, Apple Silicon and Intel where available, Retina and non-Retina screens,
multiple Spaces, Stage Manager, external display attach/detach, sleep/wake, and
at least Zoom, Microsoft Teams, Google Meet in Safari and Chrome, Webex, Slack
Huddles, Discord, and OBS.

Mac App Store acceptance requires a sandboxed, consistently signed candidate
that contains no cross-application input or Accessibility implementation and
requests no Accessibility permission on any supported OS.
Its persistent Permissions view must explain picker-scoped screen-sharing
access without requesting separate broad Screen Recording access. Arrange and
Draw must remain available.
The private Workspace must host those modes while the public Stage stays
chrome-free. Screenshot acceptance covers
every preset's exact dimensions, clean-Stage-only content, Curtain/content,
ink, watermark and effective pointer visibility parity, Copy, Save, and cancel,
without another screen permission or any automatic/network path.
Draw-mode acceptance must cover Stage/Workspace alignment, Curtain
non-disclosure, Undo/Clear, bounds, intermediate-source removal preservation,
and final-source/Stop All clearing.

TCC consent and third-party meeting pickers are not stable CI automation
surfaces. Core state and build checks run in CI; signed manual acceptance uses
the checklist in `docs/RELEASE.md`.
