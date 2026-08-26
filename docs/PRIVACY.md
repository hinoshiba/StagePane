# StagePane Privacy Policy

Effective date: 2026-08-26<br>
Product: StagePane for macOS

## Summary

StagePane does not collect personal data, create accounts, show advertising,
run analytics, or send telemetry. It has no third-party SDKs or
publisher-operated server. Every build uses App Sandbox and has no network
client entitlement. In the Mac App Store build, Apple StoreKit handles the
optional StagePane Pro product, purchase, entitlement, and restore flow.

StagePane can create one clean Audience Stage PNG only when the user explicitly
chooses Copy Audience Image or Save Audience Image. This local export is not
collection by StagePane or its publisher and is never automatic or transmitted.

## Screen content

StagePane accesses screen content only after the user opens Apple's system
content-sharing picker and explicitly adds one window, application, or display.
Choosing an application can include multiple windows owned by that application;
choosing one window provides the narrowest scope. Free supports two
independently pausable and removable sources. StagePane Pro removes StagePane's
plan-level source-count limit; Mac performance, ScreenCaptureKit, and the
selected content still determine the practical finite count. The chosen video
frames are rendered locally in parallel in the StagePane Stage window and the
private Workspace's integrated Canvas & Sources view. Its left source rail
provides lifecycle controls beside the live preview; settings remain in the
Workspace sidebar.

Each `SCContentSharingPicker` choice grants access only to the selected content
for that capture session. StagePane does not request separate, broad Screen
Recording access. Canceling the picker grants no source access; removing a
source or stopping all sources ends the corresponding streams and discards their
displayed frames.

StagePane does not:

- record or encode those frames;
- write them to disk, logs, the clipboard, or a database except for the
  explicit one-shot Audience Stage PNG described below;
- perform OCR, object recognition, or AI processing;
- transmit them to StagePane, its publisher, or any third party;
- capture system audio or microphone audio.

When the optional Laser pointer style is active, StagePane reads only the current
pointer location needed to place one dot over the frontmost Stage source. If that
source is paused, no dot is shown and StagePane does not use a source behind it
instead. Entering Draw mode hides the audience pointer and stops pointer-location
sampling until Arrange resumes. Laser pointer mode itself does not install an
event tap or request Accessibility/Input Monitoring permission. StagePane does
not retain pointer history or write pointer coordinates to disk; each sampled
position is discarded continuously and cleared when capture stops, the source
changes, or Draw begins.

## Workspace modes

StagePane provides **Arrange** and **Draw**. Arrange changes only the local Stage
composition. Draw creates the session-only ink described below. StagePane does
not forward clicks, keys, or drags to source applications, install an event tap,
or request Accessibility or Input Monitoring permission.

In **Draw** mode, StagePane keeps a bounded set of normalized vector strokes in
memory and renders the same ink in the private Workspace and public Stage. Ink is
not automatically written to disk, uploaded, analyzed, or attached to captured
source frames. An explicit Audience Stage screenshot includes the currently
visible ink as rasterized pixels. The Curtain hides it from the audience; Stop
All or removal of the final source clears the in-memory vector document.

Frames exist transiently in system/application memory for display and are
discarded as playback advances. Pausing one source stops its ScreenCaptureKit
stream but intentionally retains its last displayed frame in memory on both
local render surfaces; resuming restarts that source. Removing the source
flushes the retained frame, and **Stop All** does this for every source. The
Privacy Curtain visually covers the public Stage but does not stop or pause
capture. The private Workspace remains visible so the user can prepare the
composition; this is disclosed in the interface.

The “Keep Private” label on Stage Workspace is workflow guidance, not a privacy
or security boundary. Application or full-display sharing can expose it, and a
meeting app may still list or capture the window. StagePane tells the user to
select the exact Stage window, rather than the StagePane application or an
entire display, when the private Workspace must remain hidden.

## User-initiated screenshots

StagePane does not take screenshots on a timer, in the background, at launch,
or in response to capture changes. Only the user's **Copy Audience Image** or
**Save Audience Image…** action in Stage Workspace creates one lossless PNG of
the clean Audience Stage.
The PNG uses the selected Stage pixel dimensions and includes what the audience
Stage currently shows: shared content or Curtain, ink, watermark, safe-area
guide when enabled, and pointer when visible. It excludes Workspace navigation
and controls, title-bar chrome, and unrelated application windows.

The screenshot is composed locally from the latest pixels already approved by
the user through Apple's content-sharing picker and the Stage's own local
artwork. This path does not enumerate unrelated windows, request a new screen
permission, record video, or use the network. Copy places the PNG on the macOS
general pasteboard, where other local applications and clipboard managers may
access it according to their behavior. Save opens the macOS save panel and
writes the PNG only to the user-selected location. Canceling Save writes
nothing. After the copy or write finishes, StagePane retains no separate
screenshot history or screenshot file of its own.

## Settings stored on the device

StagePane stores interface preferences such as aspect preset, theme, pointer
style and appearance, drawing tool/color/ink width/eraser size, watermark/safe-area visibility,
curtain message, and window behavior in local `UserDefaults`. It does not persist the
chosen source, window title, application name, screenshot history, chosen
screenshot file path, or meeting information. The standard window-frame
preferences can include the positions and sizes of the Stage and Workspace
windows, but not their pixels. A PNG saved through the explicit screenshot action is the user's chosen
local file, not an app preference or hidden retained copy.
Source titles may be displayed transiently in the in-memory source list while
capture is active. Dragged positions and sizes are session-only in this version.

Users can remove settings by deleting the app's local container or using
available macOS app-data controls.

## Permissions

The persistent Permissions view explains that screen-sharing access is granted
per selection and per capture session by Apple's system picker. It does not
present a global Screen Recording allow/deny state, request separate broad
Screen Recording access, or require a System Settings step in the normal source
flow. Removing a source or stopping all sources ends its session-scoped access.
StagePane remains usable as an empty/holding share window before a source is
selected.

## Network and third parties

StagePane has no publisher-operated server and never uploads screen content,
copied or saved screenshots, source names, pointer data, drawings, or usage
analytics. For optional StagePane Pro commerce, StoreKit may contact Apple's
App Store to load localized product information, complete a purchase, verify
current entitlement, listen for transaction changes, or restore a purchase.
Apple handles Apple Account credentials. StagePane receives only the product
and verified transaction status needed to unlock Pro and operates no commerce
server of its own.

The meeting application that shares the
StagePane Stage is separate software. Its transmission, recording, accounts,
and data practices are governed by that provider, not by StagePane.

macOS and Apple frameworks are part of the operating system. Their behavior is
governed by Apple's terms and privacy information.

## Retention, disclosure, sale, and tracking

Because StagePane does not collect screen content or personal data, it has no
server-side retention, disclosure, sale, cross-context behavioral advertising,
or tracking process. A screenshot explicitly copied or saved by the user exists
only in the local pasteboard or chosen file location and is not retained by the
publisher. `NSPrivacyTracking` is declared false and collected data types are
empty in the privacy manifest.

## Children

StagePane is a general productivity utility and is not directed to children.

## Changes

This policy may be updated if StagePane's features or data practices change.
The updated policy will be published with a revised effective date. Material
changes will be communicated through an appropriate product or project channel.

## Contact

[support@hinoshiba.com](mailto:support@hinoshiba.com)
