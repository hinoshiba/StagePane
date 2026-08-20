## Why

Describe the user problem and why this scope is appropriate.

## What changed

-

## Safety and compliance

- [ ] Public Apple APIs only; no private display API or raw event injection
- [ ] Local and Mac App Store targets keep the same sandboxed Arrange/Draw
      feature set and contain no cross-application input, Accessibility
      implementation, or Accessibility/Input Monitoring permission path
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
