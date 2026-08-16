# Changelog

All notable changes will be documented here. This project follows Semantic
Versioning once 1.0.0 is released.

## [Unreleased]

### Added

- Initial StagePane macOS application and brand system.
- Stable share Stage plus separate private Control Room.
- macOS ScreenCaptureKit system picker for local window/app/display preview.
- Privacy Curtain, aspect presets, menu bar controls, Presentation Lock,
  all-Spaces and always-on-top options, pointer and safe-area controls.
- Japanese/English interface selection from the system language.
- Apache-2.0 licensing, trademark separation, SBOM, privacy manifest, release
  gates, CI, security and contribution documents.
- Separate checked-in Mac App Store Xcode target and tagged Xcode Cloud path
  with App Sandbox, strict concurrency, universal slices, localized metadata,
  icon, privacy manifest, help, and legal-resource verification.
- Explicit development-only bundle marking.

### Changed

- Standardized the app, Store target, and release gates on the canonical bundle
  identifier `com.hinoshiba.stagepane`.
- Replaced local signing, notarization, DMG, archive, and upload steps with an
  Xcode Cloud workflow triggered by semantic-version tags.
