## Why

Describe the user problem and why this scope is appropriate.

## What changed

-

## Safety and compliance

- [ ] Public Apple APIs only; no private display API or raw event injection
- [ ] Mac App Store target stays sandboxed, exposes no Control mode, and contains
      no cross-application Accessibility implementation or permission path;
      Control changes stay inside the local development build boundary
- [ ] Capture/privacy data flow unchanged, or a reviewed threat model is linked
- [ ] Dependency/license/SBOM/notices unchanged, or all are updated
- [ ] Japanese and English copy updated together
- [ ] Accessibility and non-color state cues checked

## Verification

- [ ] `./Scripts/release-check.sh`
- [ ] `swift build -Xswiftc -warnings-as-errors`
- [ ] Synthetic screenshots attached for visual changes
- [ ] Manual macOS/meeting-app matrix listed below where relevant

## DCO

- [ ] Every commit has a `Signed-off-by:` line
