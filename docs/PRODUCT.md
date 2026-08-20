# Product and brand brief

## Brand

**StagePane** combines a presentation *stage* with a dedicated window *pane*.
Always write it in CamelCase so the `P` remains visible. Japanese reading:
ステージペイン.

Tagline: **見せたいものだけ、ひとつのステージへ。**<br>
English: **A clean stage for everything you share.**

The mental model is **Audience Stage + private Stage Workspace**, never a
replacement desktop. The Stage is a chrome-free output. The Workspace combines
the large WYSIWYG Canvas, Sources, Stage Settings, Appearance, Permissions,
Privacy, and About behind a Docker-style sidebar.
Ink `#0C1018`, Stage Indigo `#5B5CF0`, and Beam Aqua `#48D8E8` form the core
palette. Status uses macOS semantic colors plus icons/text; the brand gradient
is reserved for the mark and empty states.

The logo is an abstract proscenium: two overlapping panes with a bright central
stage. It must remain legible at 16 px and must not resemble a monitor stand,
broadcast service logo, or the referenced Youyaku wave mark.

## Core promise

People should create a safe, recognizable share target in under 60 seconds,
understand exactly what is and is not being captured, cover it in under 100 ms,
and end capture with no retained frame or orphaned state.

## P0 shipping scope

- Stable, chrome-free Share Stage plus one private Stage Workspace; its private
  label is guidance, not protection from full-display
  or application sharing
- Apple system picker for one window/app/display source consent at a time;
  access is scoped to that selection and capture session, with no separate
  broad Screen Recording permission
- up to four independently pausable/resumable, replaceable, and removable
  in-memory video sources; pause stops the stream and retains its last frame
- large private Workspace hosting Arrange, Press Buttons where available, and
  Draw, with move, free resize, z-order, and auto arrange; source management and
  settings live in its sidebar
- explicit per-source removal confirmation and stop-all capture teardown
- instant Privacy Curtain with customizable message
- 16:9, 4:3, 9:16, 1:1 shapes
- system, laser, or hidden pointer style; the adjustable-color/size/glow laser
  belongs only to the frontmost source and is hidden while it is paused
- default-on translucent lower-right StagePane mark on audience-facing Stage
  states, including content and Curtain
- mutually exclusive Arrange and Draw modes in the Mac App Store build; Arrange
  edits only the composition and Draw is bounded session-only Stage ink
- explicit one-shot clean Audience Stage PNG copy/save at the selected preset
  dimensions, including Curtain, ink, watermark, and pointer but excluding
  Workspace chrome; no automatic screenshot, recording, or network path
- all-Spaces, always-on-top compatibility, Presentation Lock
- menu-bar recovery and keyboard shortcuts
- persistent Permissions view explaining picker-scoped screen sharing; the
  local development build also exposes its separate Press Buttons Accessibility card
- Japanese/English UI selected from system language
- App Sandbox, privacy manifest, zero network/analytics/account dependencies;
  the Mac App Store build omits Press Buttons and all cross-application Accessibility
  permission/action paths

The unsandboxed local development build can additionally offer Press Buttons on macOS
15.2 or later. Selecting Press Buttons may route to Permissions, but only the
Accessibility card's explicit **Continue Setup** action requests consent. It
may perform only a supported Press action on a pressable control inside an exact
single-window source. This variant is outside the Mac App Store shipping scope
and must preserve every Press-Buttons-specific exclusion and validation below. A
future direct-distribution build would be a separate product and release
decision; none currently ships. The Mac App Store build hides the Accessibility
card entirely.

## Deliberate exclusions

- real or private-API virtual display
- window reparenting, raw mouse/keyboard event synthesis, keyboard/drag
  forwarding, event taps, or unattended remote control
- cursor teleportation, app activation/focus, generic canvas/content control, or
  input sent to app/display/ambiguous sources
- audio, microphone, recording, streaming, cloud, AI, OCR, or automatic screenshots
- separate broad Screen Recording permission or a custom source-permission flow
- account, subscription, ads, analytics, crash upload, custom updater
- Finder/Dock clone, app launcher, or alternate desktop

These exclusions are product trust and App Review boundaries, not missing
marketing claims.

## Roadmap candidates after validation

1. Local image/PDF/text cards selected through sandbox-safe open panels.
2. Scene presets that store layout but never source window identity/content.
3. Presenter timer and local notes kept out of the Stage.
4. A local, user-initiated redacted diagnostics export.
5. StoreKit one-time Supporter/Pro purchase only after the free core proves
   useful; no account or subscription by default.

Every addition must repeat privacy, license, accessibility, performance, and
App Review threat modeling before implementation.

## Quality objectives

- first Stage success rate ≥95%
- median time to first value ≤60 seconds
- Stage preparation P95 ≤2 seconds
- Curtain UI transition ≤100 ms
- crash-free sessions ≥99.9%
- zero automatic frame persistence and zero network requests by invariant;
  only an explicit one-shot screenshot can copy or save a clean Audience Stage PNG
- 100% common-task VoiceOver/keyboard completion before claims
- no unbounded memory growth in a two-hour 1080p session
- signed manual compatibility evidence for each listed meeting app/release

An App Store rank or 4.7+ rating is an aspiration, never a guarantee.

## Naming clearance

Initial general web/App Store checks found no major exact-match software. This
is not legal clearance. Before public use, search exact and phonetic variants in
J-PlatPat, USPTO, EUIPO/TMview, WIPO, App Store, GitHub, Homebrew, domains, and
social handles; engage a trademark professional for relevant classes and
markets. English user testing should also check the possible “stage pain”
homophone.
