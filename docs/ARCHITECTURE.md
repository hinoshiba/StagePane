# Architecture

## Product boundary

StagePane is a presentation canvas implemented as a normal `NSWindow`. It is
intended to appear in meeting applications' *window* share pickers. It is not an
`NSScreen`, is not listed in macOS Display Settings, and cannot host or directly
reparent arbitrary application windows. On macOS 15.2 or later, its optional
Press Buttons mode can perform one supported accessibility Press action on a pressable
control inside an explicitly shared single-window source after Accessibility
access is requested through Permissions **Continue Setup** and granted; it is
not a general remote desktop or alternate input system. That mode exists only
in the unsandboxed local development build. The
sandboxed Mac App Store build omits Press Buttons and its Accessibility permission and
action path, while retaining Arrange, Draw, source composition, pointer, Curtain,
and watermark features.

Apple requires App Sandbox for Mac App Store apps and identifies assistive use
of Accessibility APIs as incompatible with the sandbox. The build split follows
Apple's [App Sandbox compatibility guidance](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox),
rather than treating App Review as a way to waive that platform boundary.

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
        │       ├── StageLayoutEditor Arrange / Press Buttons / Draw
        │       ├── Sources           per-source lifecycle controls
        │       ├── Stage Settings / Appearance
        │       └── Permissions / Privacy / About
        ├── StageWindowController
        │   └── StageView             chrome-free public share surface
        ├── StageWindowSnapshotter    explicit clean Stage PNG copy/save
        ├── StatusItemController      menu-bar recovery path
        ├── StageAnnotationStore      session-only Stage-wide vector ink
        ├── PreviewInputForwarder     unsandboxed build only; consented Press
        └── CaptureCoordinator
            ├── SCContentSharingPicker
            ├── StageLayout           normalized frame / z-order by SourceID
            └── CaptureSession[0...4]
                ├── SCStream          one independently consented source
                └── CaptureSourceRenderers
                    ├── Stage SampleBufferRenderer
                    └── Workspace Preview SampleBufferRenderer
```

`StagePaneCore` contains platform-light preset, message, pointer/input
projection, bounded annotation, and normalized multi-source layout rules. It is
tested without creating windows.
The executable target owns AppKit, SwiftUI, and ScreenCaptureKit integration.
Only the unsandboxed local development variant owns the ApplicationServices
Accessibility control path; the Mac App Store variant must exclude it at build
time, not merely hide a control at runtime.

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
6. In the unsandboxed local development build on macOS 15.2 or later, Press Buttons
   mode accepts a selected point only in the visible content of the frontmost tile.
   The current picker-authorized filter must identify exactly one on-screen
    window. The preview renderer inverse-maps that point through a fresh,
    lifecycle-fenced complete frame presented in the Canvas, scoped by stream
    token and filter generation. After
   Accessibility access is requested through the persistent Permissions view's
   explicit **Continue Setup** action and granted, an application-scoped
   `AXUIElementCopyElementAtPosition` hit test must resolve to the same selected
   window. StagePane walks only that element's parent chain for a supported
   `kAXPressAction`, then invokes it with `AXUIElementPerformAction`. It does not
   synthesize raw mouse events, move the physical pointer, activate or focus the
   source application, or treat a generic canvas/content region as a click
   target. Application/display sources, padding, stale or ambiguous frames,
   keyboard input, and drag forwarding are rejected. StagePane does not enumerate
   unrelated windows. This entire step is absent from the Mac App Store build.
7. Draw mode stores one bounded, normalized vector-ink document in memory. Both
   the private Workspace and public Stage render that document, while the Curtain
   covers it on the public Stage. Undo/Clear mutate the document; Stop All or
   removal of the final source clears it. No ink is serialized or logged.
8. In laser-pointer mode, the native captured pointer is disabled for every
   stream. One local `CAShapeLayer` overlay is enabled only for the frontmost
   source in `StageLayout`; it maps the current pointer through that frame's
   `screenRect`, `contentRect`, and scale metadata into its aspect-fit
   rectangle. If the frontmost source is paused, no pointer overlay is enabled
   and ownership does not fall through to a lower source. Video frames remain
   on the zero-copy display path.
9. Per-source **Pause** stops that source's `SCStream` while leaving its last
   frame in both renderers and its tile in `StageLayout`. **Resume** restarts
   the same stream. Pause is therefore a frozen-frame state, not teardown.
10. A screenshot is created only after a person explicitly chooses **Copy
    Audience Image** or **Save Audience Image…** in the private Workspace.
    `StageWindowSnapshotter`
    rasterizes the clean Stage content view at the selected preset's exact pixel
    dimensions. It temporarily substitutes immutable images of the latest
    picker-authorized source frames while rendering, then restores the live
    layers synchronously. The result therefore includes the current audience
    Curtain or content, ink, watermark, safe-area guide, and pointer, but never
    Workspace navigation, controls, or title-bar chrome. Copy writes the one PNG to the macOS
    pasteboard; Save writes it only to the location selected in `NSSavePanel`.
    The Store sandbox grants user-selected read/write access solely for that
    explicit destination.
    Cancel writes nothing. No new screen-capture permission or unrelated-window
    enumeration is used.
11. There is no `AVAssetWriter`, `VideoToolbox` recording encoder, automatic
    screenshot or file writer, OCR, network session, analytics SDK, or telemetry
    client. The explicit one-shot screenshot path above is the only frame export.
12. Per-source **Remove**, **Stop All**, app termination, or stream failure first
   invalidates output, stops the corresponding stream, removes its output, and
   waits for both display renderers to drain and discard their last image.
   Selected source metadata and layout are not persisted.

The Privacy Curtain hides the public Stage but intentionally does not stop its
streams; the UI says so. The private Workspace remains visible so a layout can
be prepared safely. **Stop All** is the explicit
complete-capture termination control. Toggling the Curtain changes the public content in place;
it does not order the Stage window to the front.

## Permission model

The persistent Workspace **Permissions** view describes two deliberately
different access paths:

- Screen sharing is not represented as an app-wide allow/deny switch. Each
  `SCContentSharingPicker` interaction is the consent UI, and its returned
  filter authorizes only the selected window, application, or display for that
  capture session. Cancel grants nothing. The app does not request separate,
  broad Screen Recording access or expose a Screen Recording settings step.
  Removing the source or stopping all sources ends the scoped access.
- The unsandboxed local development build on macOS 15.2 or later can display a
  separate Accessibility card for Press Buttons. Merely opening Permissions or
  selecting Press Buttons does not prompt. Only the card's explicit **Continue Setup**
  action calls the Accessibility request path, and it does so at most once per
  persisted app preferences. Later untrusted checks route to repair instructions
  and System Settings instead of repeatedly prompting. Returning from system UI
  refreshes its status. `AXIsProcessTrusted()` remains authoritative; the app
  never caches or infers an allowed result. The default ad-hoc local bundle
  explains that each binary update changes its macOS code identity and may
  require removing a stale row before re-adding the exact running bundle path
  shown in the Permissions card. For repeated permission testing, `build.sh`
  can instead use the same caller-managed Keychain identity supplied through
  `STAGEPANE_LOCAL_SIGNING_IDENTITY`; this remains an unsandboxed,
  development-only Hardened Runtime build and does not affect the App Store
  target or Xcode Cloud signing.

The `STAGEPANE_APP_STORE` build compiles out the Accessibility card, AX request,
settings link, and cross-application Accessibility implementation. Shared pure
state types may remain in the binary, but no Store UI or executable path can
request permission or perform a cross-app action. Its Permissions view contains
only the picker-scoped screen-sharing explanation. Neither build requests Input Monitoring.

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
- Closing Workspace cancels pending preview-control work and ends an in-progress
  ink stroke, but does not close Stage, clear completed ink, or stop capture.
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

In the unsandboxed local development build with Press Buttons, preview interaction geometry is
stricter than pointer presentation geometry: only a fresh complete frame
successfully accepted by the private renderer is eligible. Replacement, pause,
dimension change, stop, blank/suspended output, or a stream/filter generation
mismatch invalidates it until a fresh frame is presented. Resolution happens
on the serial render queue and is revalidated on
the main actor immediately before the synchronous application-scoped
Accessibility hit test, selected-window check, and Press action.

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
- The unsandboxed local development build with Press Buttons reports unsupported source
  scope, missing Accessibility consent, stale display geometry, selected-window
  mismatch, unsupported Press action, or
  action failure without guessing a window or synthesizing a fallback click.
  Its Permissions card links to System Settings for reviewing or revoking only
  that Accessibility access.
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
that exposes no Press Buttons mode, contains no cross-application Accessibility
implementation, and requests no Accessibility permission on any supported OS.
Its persistent Permissions view must explain picker-scoped screen-sharing
access without requesting separate broad Screen Recording access, and it must
hide the Accessibility card entirely. Arrange and Draw must remain available.
The private Workspace must host those modes while the public Stage stays
chrome-free. Screenshot acceptance covers
every preset's exact dimensions, clean-Stage-only content, Curtain/content,
ink, watermark and pointer parity, Copy, Save, and cancel, without another
screen permission or any automatic/network path.
Separately, Press Buttons
acceptance for the unsandboxed local development build requires macOS 15.2+:
confirm that only Permissions **Continue Setup** triggers the system
Accessibility request; allow/deny/revoke that access; exact window versus
app/display filters; pressable controls versus generic canvas/text regions; selected-window
mismatch; black padding and overlap; pause/resume/replace/stop; negative display
origins; unchanged physical pointer and source-app focus; and supported Press
controls in PowerPoint Presenter View. On macOS 14 through 15.1, that build must
keep Press Buttons unavailable without requesting Accessibility access. Draw-mode
acceptance in both variants must cover Stage/Workspace alignment, Curtain
non-disclosure, Undo/Clear, bounds, intermediate-source removal preservation,
and final-source/Stop All clearing.

TCC consent and third-party meeting pickers are not stable CI automation
surfaces. Core state and build checks run in CI; signed manual acceptance uses
the checklist in `docs/RELEASE.md`.
