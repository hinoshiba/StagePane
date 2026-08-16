# StagePane Privacy Policy — pre-release draft

Effective date: 2026-08-15<br>
Product: StagePane for macOS

> **Pre-release draft:** Jurisdiction-appropriate review remains required before
> publishing or selling the app. Project and privacy questions use the contact
> address listed below.

## Summary

StagePane does not collect personal data, create accounts, show advertising,
run analytics, or send telemetry. It has no network client entitlement and no
third-party SDKs.

## Screen content

StagePane accesses screen content only after the user opens Apple's system
content-sharing picker and explicitly chooses a window, application, or display.
The chosen video frames are rendered into the local StagePane Stage window.

StagePane does not:

- record or encode those frames;
- write them to disk, logs, the clipboard, or a database;
- perform OCR, object recognition, or AI processing;
- transmit them to StagePane, its publisher, or any third party;
- capture system audio or microphone audio.

Frames exist transiently in system/application memory for display and are
discarded as playback advances. **Stop Preview** ends the capture stream and
flushes the last displayed image. The Privacy Curtain visually covers the Stage
but does not stop capture; this is disclosed beside the control.

## Settings stored on the device

StagePane stores interface preferences such as aspect preset, theme, pointer
visibility, safe-area visibility, curtain message, and window behavior in the
app's sandboxed `UserDefaults`. It does not persist the chosen source, window
title, application name, screen image, file path, or meeting information.

Users can remove settings by deleting the app's container or using macOS app
data controls. A future reset control must be added before claiming in-app data
deletion support.

## Screen Recording permission

macOS controls screen-capture consent. Users can review or revoke access in
System Settings → Privacy & Security → Screen & System Audio Recording. If
permission is revoked, StagePane remains usable as an empty/holding share
window, but cannot mirror external content until the user approves it again.

## Network and third parties

StagePane makes no network requests. The meeting application that shares the
StagePane Stage is separate software. Its transmission, recording, accounts,
and data practices are governed by that provider, not by StagePane.

macOS and Apple frameworks are part of the operating system. Their behavior is
governed by Apple's terms and privacy information.

## Retention, disclosure, sale, and tracking

Because StagePane does not collect screen content or personal data, it has no
server-side retention, disclosure, sale, cross-context behavioral advertising,
or tracking process. `NSPrivacyTracking` is declared false and collected data
types are empty in the privacy manifest.

## Children and international use

StagePane is a general productivity utility and is not directed to children.
The publisher must assess age-rating, consumer, and privacy obligations in each
market before distribution.

## Changes

Any future network service, crash reporting, analytics, recording, account,
payment, cloud sync, or support-upload feature requires an updated data-flow
audit, privacy manifest, App Store disclosure, policy, consent design, and
release notes before code ships.

## Contact

[support@hinoshiba.com](mailto:support@hinoshiba.com)
