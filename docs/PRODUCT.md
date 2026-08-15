# Product and brand brief

## Brand

**StagePane** combines a presentation *stage* with a dedicated window *pane*.
Always write it in CamelCase so the `P` remains visible. Japanese reading:
ステージペイン.

Tagline: **見せたいものだけ、ひとつのステージへ。**<br>
English: **A clean stage for everything you share.**

The mental model is **Stage + Control Room**, never a replacement desktop.
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

- Stable Stage window and separate Control Room
- Apple system picker for window/app/display source consent
- In-memory video-only preview and explicit stop
- instant Privacy Curtain with customizable message
- 16:9, 4:3, 9:16, 1:1 shapes
- pointer toggle, safe-area guide, optional watermark
- all-Spaces, always-on-top compatibility, Presentation Lock
- menu-bar recovery and keyboard shortcuts
- Japanese/English UI selected from system language
- sandbox, privacy manifest, zero network/analytics/account dependencies

## Deliberate exclusions

- real or private-API virtual display
- window reparenting or Accessibility input injection
- cursor teleportation or synthetic clicks
- audio, microphone, recording, streaming, cloud, AI, OCR
- account, subscription, ads, analytics, crash upload, custom updater
- Finder/Dock clone, app launcher, or alternate desktop

These exclusions are product trust and App Review boundaries, not missing
marketing claims.

## Roadmap candidates after validation

1. Local image/PDF/text cards selected through sandbox-safe open panels.
2. Two-source layouts and picture-in-picture with per-source consent.
3. Scene presets that store layout but never source window identity/content.
4. Presenter timer and local notes kept out of the Stage.
5. A local, user-initiated redacted diagnostics export.
6. StoreKit one-time Supporter/Pro purchase only after the free core proves
   useful; no account or subscription by default.

Every addition must repeat privacy, license, accessibility, performance, and
App Review threat modeling before implementation.

## Quality objectives

- first Stage success rate ≥95%
- median time to first value ≤60 seconds
- Stage preparation P95 ≤2 seconds
- Curtain UI transition ≤100 ms
- crash-free sessions ≥99.9%
- zero saved/source frames and zero network requests by invariant
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
