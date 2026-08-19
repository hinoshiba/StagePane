# Changelog

All notable changes will be documented here. This project follows Semantic
Versioning once 1.0.0 is released.

## [Unreleased]

### Added

- Initial StagePane macOS application and brand system.
- Stable, chrome-free Share Stage plus separate private Stage Workspace and
  Control Room. Arrange, Control, and Draw live on the large Workspace; Control
  Room keeps source management and settings without a second live editor.
- macOS ScreenCaptureKit system picker for local window/app/display preview.
  Each choice grants access only to the selected content for that capture
  session; StagePane does not request separate broad Screen Recording access.
- Up to four independently consented window/app/display sources, added one at a
  time with per-source pause/resume, replace, and remove controls. Pausing stops
  that source's stream while retaining its last frame until resume or removal.
- A private Stage Workspace with a large live editor, drag, free resize,
  front-to-back ordering, and deterministic automatic arrangement.
- Mutually exclusive Arrange and Draw modes in the sandboxed Mac App Store
  build. Draw renders bounded, session-only vector ink in both the private
  Workspace and public Stage. The unsandboxed local development build can
  additionally expose Control on macOS 15.2 or later; only the explicit
  **Continue Setup** action in Permissions requests Accessibility access.
  Control performs only a supported Press action inside an exact single-window
  source and never synthesizes arbitrary mouse/keyboard input, activates the
  source app, or controls generic canvas/content regions.
- A persistent Permissions view that explains picker-scoped screen sharing and,
  in the local development build only, shows Control's separate Accessibility
  status and request action. The Mac App Store build omits that card.
- Privacy Curtain with a customizable message, aspect presets, menu bar
  controls, Presentation Lock, all-Spaces and always-on-top options,
  system/laser/hidden pointer styles, adjustable laser color/size/glow,
  safe-area controls, and a default-on translucent lower-right StagePane mark.
- A destructive confirmation before per-source removal.
- Explicit one-shot screenshots of the clean audience Stage. The user can copy
  a lossless PNG or save it at the selected Stage dimensions; Curtain, ink,
  watermark, and pointer are included, while private Workspace controls are not.
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
- Explicit development-only bundle marking.
- Accessibility consent is requested at most once from the Permissions view.
  If an updated ad-hoc development build no longer matches macOS's saved code
  identity, StagePane now shows exact remove-and-re-add repair steps instead of
  repeatedly presenting the same consent request.

### Changed

- Laser pointer mode now draws one dot only for the frontmost Stage source.
  A paused frontmost source shows no dot and does not delegate pointer display
  to a source behind it.
- Toggling the Privacy Curtain no longer brings the Stage window to the front.
- Removed repeated privacy slogans from the Stage dashboard and Control Room
  sidebar, and removed the redundant Important Limitation card from About. The
  full Privacy screen and privacy documentation remain available.
- Set minimum content sizes of 1040×680 points for the large Workspace and
  820×580 points for the compact Control Room to preserve their layouts.
- Moved Arrange, Control, and Draw out of Control Room and into the dedicated
  Stage Workspace. The private-window labels are workflow guidance, not a
  security boundary; application or full-display sharing can expose them.
- Standardized the app, Store target, and release gates on the canonical bundle
  identifier `com.hinoshiba.stagepane`.
- Replaced local signing, notarization, DMG, archive, and upload steps with an
  Xcode Cloud workflow triggered by semantic-version tags.
