# Changelog

All notable changes will be documented here. This project follows Semantic
Versioning once 1.0.0 is released.

## [Unreleased]

### Changed

- The Mac App Store Free tier now supports four simultaneous sources, while
  StagePane Pro removes StagePane's source-count limit. The number of sources
  that can run in practice still depends on Mac performance and operating-system
  constraints.

### Fixed

- Cropped layers no longer reveal pixels outside the selected region when a
  Stage tile's aspect ratio leaves horizontal or vertical margins.

## [0.3.1] - 2026-08-29

### Fixed

- Mac App Store archives now give non-root users read and traversal access to
  every file and directory in the app bundle, allowing Apple's installer
  package validation to verify the code signature when the app runs.

## [0.3.0] - 2026-08-29

### Added

- Per-layer Crop actions on every Canvas tile and source row edit that exact
  layer in a private full-source Canvas, with a draggable frame, four corner
  handles, keyboard and VoiceOver actions. The target layer remains named and
  highlighted throughout editing. Changes, including Reset to Full Source, remain a draft
  until Apply Crop; Cancel discards them and the public Stage keeps its
  previously applied crop meanwhile. Applied crops remain only in memory for
  the current StagePane run, survive a source-sharing disconnect on the retained
  layer, and are shared consistently by the live Stage, pointer overlay, and
  explicit Audience PNG. Every running picker-approved stream remains full-source.

### Changed

- Pausing a source now clears its visible pixels from the Stage, Workspace, and
  Audience PNG while retaining the layer's placement, crop, and stacking order.
  Resume reveals the layer only after a new complete frame arrives.
- Mac App Store candidates now use the checked-in local Organizer archive
  helper from an annotated signed release tag. The helper pins the App Store
  scheme, validates release provenance and signing settings, verifies the
  archive, and leaves upload as a separate explicit action.

### Fixed

- Workspace notices now float above the current section as auto-dismissing
  toasts instead of entering the layout and resizing the Stage preview.
- Ending a source's macOS sharing session no longer deletes its logical layer.
  StagePane immediately clears the renderer and old frame, keeps the layer's
  placement, crop, and stacking order, then offers Select Again through Apple's
  picker. Only an explicit Remove deletes the retained layer.
- Closing the Share Stage now affects only audience output. Source layers,
  capture bindings, placement, and crop remain in the private Workspace until
  the user explicitly removes a layer or chooses Stop All.

## [0.2.0] - 2026-08-27

### Added

- A useful Free tier with two simultaneous sources, plus the one-time,
  non-consumable StagePane Pro In-App Purchase. Pro unlocks up to four sources
  and makes the audience-facing StagePane mark optional; purchase, restore,
  entitlement, refund, and revocation state is verified through Apple StoreKit.

### Changed

- Added the live Mac App Store listing to the Japanese and English website.

## [0.1.1] - 2026-08-26

### Added

- Initial StagePane macOS application and brand system.
- Stable, chrome-free Share Stage plus one private Stage Workspace. A
  Docker-style sidebar brings Canvas, Sources, Stage Settings, Appearance,
  Permissions, Privacy, and About into that single working window.
- macOS ScreenCaptureKit system picker for local window/app/display preview.
  Each choice grants access only to the selected content for that capture
  session; StagePane does not request separate broad Screen Recording access.
- Up to four independently consented window/app/display sources, added one at a
  time with per-source pause/resume, replace, and remove controls. Pausing stops
  that source's stream while retaining its last frame until resume or removal.
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

### Changed

- Refreshed the bilingual website around the current two-window workflow, with
  deterministic Arrange, Draw, Sources, and Permissions screenshots generated
  by StagePane itself from privacy-safe synthetic content.
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
- Consolidated the former Control Room into the Stage Workspace. Canvas,
  Sources, Stage Settings, Appearance, Permissions, Privacy, and About now use
  one Docker-style sidebar; the only other window is the chrome-free Share
  Stage. The private-window label remains workflow guidance, not a security
  boundary, because application or full-display sharing can expose Workspace.
- Standardized the app, Store target, and release gates on the canonical bundle
  identifier `com.hinoshiba.stagepane`.
- Replaced local signing, notarization, DMG, archive, and upload steps with an
  Xcode Cloud workflow triggered by semantic-version tags.
