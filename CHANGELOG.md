# Changelog

All notable changes will be documented here. This project follows Semantic
Versioning once 1.0.0 is released.

## [Unreleased]

### Added

- Initial StagePane macOS application and brand system.
- Stable, chrome-free Share Stage plus one private Stage Workspace. A
  Docker-style sidebar brings Canvas & Sources, Stage Settings, Appearance,
  Permissions, Privacy, and About into that single working window.
- macOS ScreenCaptureKit system picker for local window/app/display preview.
  Each choice grants access only to the selected content for that capture
  session; StagePane does not request separate broad Screen Recording access.
- Independently consented window/app/display sources, added one at a time with
  per-source pause/resume, replace, and remove controls. Free supports two;
  StagePane Pro has no app-imposed plan limit, while the practical count depends
  on the Mac, ScreenCaptureKit, and selected content. Pausing stops that source's
  stream while retaining its last frame until resume or removal.
- A private Stage Workspace with a large live editor, drag, free resize,
  front-to-back ordering, and deterministic automatic arrangement.
- Mutually exclusive Arrange and Draw modes. Draw renders bounded, session-only
  vector ink in both the private Workspace and public Stage, with Pen,
  translucent Highlighter, and an
  undoable size-adjustable partial Eraser.
- A persistent Permissions view that explains picker-scoped screen sharing.
- Privacy Curtain with a customizable message, aspect presets, menu bar
  controls, Presentation Lock, all-Spaces and always-on-top options,
  system/laser/hidden pointer styles, adjustable laser color/size/glow,
  safe-area controls, and a default-on translucent lower-right StagePane mark.
- A destructive confirmation before per-source removal.
- Explicit one-shot screenshots of the clean audience Stage. The user can copy
  a lossless PNG or save it at the selected Stage dimensions; Curtain, ink,
  watermark, the safe-area guide when enabled, and pointer when visible are
  included, while private Workspace controls are not.
  StagePane never captures automatically, records, or sends screenshots.
- Japanese/English interface selection from the system language.
- Apache-2.0 licensing, trademark separation, SBOM, privacy manifest, release
  gates, CI, security and contribution documents.

### Fixed

- Prevented a crash when starting or reconfiguring capture by keeping the
  ScreenCaptureKit stream background color alive for its required lifetime.
- Follow live source-window aspect changes without double letterboxing, and
  preserve the last valid static frame across source, layout, and pointer
  configuration transitions.
- Separate checked-in Mac App Store Xcode target and tagged Xcode Cloud path
  with App Sandbox, strict concurrency, universal slices, localized metadata,
  icon, privacy manifest, help, and legal-resource verification.
- Restored the private Canvas preview by keeping its renderer on the live
  presentation timeline across source and layout reconfiguration.
- Kept the live Canvas renderer in one stable view while the source rail opens,
  closes, or adapts to window width, avoiding display-layer reattachment.
- Removed routine source-added and Curtain banners, kept actionable notices as
  non-layout overlays, and fixed the Curtain / Reveal Stage toolbar width.

### Changed

- Refreshed the bilingual website around the current two-window workflow, with
  deterministic Arrange, Draw, and Permissions screenshots generated
  by StagePane itself from privacy-safe synthetic content.
- Integrated source lifecycle controls beside the live Canvas and removed the
  separate Sources screen. The list now runs from frontmost at the top to
  backmost at the bottom, with Stop All available in the same workflow.
- Laser pointer mode now draws one dot only for the frontmost Stage source.
  A paused frontmost source shows no dot and does not delegate pointer display
  to a source behind it.
- Draw mode now hides both captured system pointers and the local laser overlay,
  then restores the user's selected pointer style when returning to Arrange.
- Toggling the Privacy Curtain no longer brings the Stage window to the front.
- Removed repeated privacy slogans from the Stage dashboard and Workspace
  sidebar, and removed the redundant Important Limitation card from About. The
  full Privacy screen and privacy documentation remain available.
- Set a minimum content size for the Workspace so its navigation, Canvas, and
  settings remain usable at the smallest supported window size.
- Consolidated the former Control Room into the Stage Workspace. Canvas &
  Sources, Stage Settings, Appearance, Permissions, Privacy, and About now use
  one Docker-style sidebar; the only other window is the chrome-free Share
  Stage. The private-window label remains workflow guidance, not a security
  boundary, because application or full-display sharing can expose Workspace.
- Standardized the app, Store target, and release gates on the canonical bundle
  identifier `com.hinoshiba.stagepane`.
- Replaced local signing, notarization, DMG, archive, and upload steps with an
  Xcode Cloud workflow triggered by semantic-version tags.
