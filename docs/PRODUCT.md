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
- four independently pausable/resumable, replaceable, and removable in-memory
  video sources in Free; the one-time StagePane Pro purchase removes the app's
  source-count limit, while the practical total depends on Mac performance and
  operating-system constraints;
  pause stops the stream and makes its layer transparent in the Stage, private
  Workspace, and Audience PNG while retaining placement, crop, and z-order;
  resume reveals it only after a new complete frame arrives
- large private Workspace hosting the global Arrange and Draw modes plus a crop
  action on every layer, with move, free resize, per-source source-space
  cropping, z-order, and auto arrange; source management and settings live in
  its sidebar
- explicit per-source removal confirmation and stop-all capture teardown
- fail-closed capture-session detachment: an externally ended share clears its
  renderer and old frame while retaining the logical layer's placement, crop,
  and z-order for explicit picker-based reconnection; only Remove deletes it
- instant Privacy Curtain with customizable message
- 16:9, 4:3, 9:16, 1:1 shapes
- system, laser, or hidden pointer style; the adjustable-color/size/glow laser
  belongs only to the frontmost source, is hidden while it is paused, and all
  audience pointer styles are temporarily suppressed in Draw mode
- translucent lower-right StagePane mark on audience-facing Stage states,
  including content and Curtain; always shown in Free and optional in Pro
- global Arrange and Draw modes in every build, with a layer-owned Crop editor
  entered from each tile or source row; Arrange edits placement; Crop privately
  drafts one selected layer at a time, Apply commits it, Cancel discards it, and
  applied crop geometry remains in memory for the current StagePane run and
  survives a source-sharing disconnect on the retained layer while every running
  stream remains full-source; Draw suppresses the audience pointer and adds bounded
  session-only Stage ink
- explicit one-shot clean Audience Stage PNG copy/save at the selected preset
  dimensions, including Curtain, ink, watermark, and pointer when visible but
  excluding Workspace chrome; no automatic screenshot, recording, or network path
- all-Spaces, always-on-top compatibility, Presentation Lock
- menu-bar recovery and keyboard shortcuts
- persistent Permissions view explaining picker-scoped screen sharing
- Japanese/English UI selected from system language
- App Sandbox, privacy manifest, no publisher-operated network service,
  analytics, StagePane account, or cross-application Accessibility/input-forwarding
  path; optional Pro commerce uses Apple's StoreKit only

## Deliberate exclusions

- real or private-API virtual display
- window reparenting, raw mouse/keyboard event synthesis, keyboard/drag
  forwarding, event taps, or unattended remote control
- cursor teleportation, app activation/focus, generic canvas/content control, or
  input sent to app/display/ambiguous sources
- audio, microphone, recording, streaming, cloud, AI, OCR, or automatic screenshots
- separate broad Screen Recording permission or a custom source-permission flow
- StagePane account, subscription, ads, analytics, crash upload, custom updater
- Finder/Dock clone, app launcher, or alternate desktop

These exclusions are product trust and App Review boundaries, not missing
marketing claims.

## Roadmap candidates after validation

1. Local image/PDF/text cards selected through sandbox-safe open panels.
2. Scene presets that store layout but never source window identity/content.
3. Presenter timer and local notes kept out of the Stage.
4. A local, user-initiated redacted diagnostics export.
5. User-selected local branding/background assets with sandbox-safe file access.

Every addition must repeat privacy, license, accessibility, performance, and
App Review threat modeling before implementation.

## Quality objectives

- first Stage success rate ≥95%
- median time to first value ≤60 seconds
- Stage preparation P95 ≤2 seconds
- Curtain UI transition ≤100 ms
- crash-free sessions ≥99.9%
- zero automatic frame persistence and zero screen/usage transmission by
  invariant; only an explicit one-shot screenshot can copy or save a clean
  Audience Stage PNG. StoreKit may contact Apple's App Store for the optional
  Pro product, purchase, entitlement, and restore flows.
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
