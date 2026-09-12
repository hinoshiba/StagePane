# Workspace interaction review

## Problem and evidence

The reported task is to move overlapping shared sources and temporarily hide
one source while continuing to compose the Stage. These are parts of the same
editing task and need to remain available beside the live composition.

The baseline source at `e9d4903` explains the friction:

- `StageWorkspaceView` exposes Canvas and Sources as separate navigation
  destinations. It also hides its optional source rail below 1,100 points, even
  though the supported minimum Workspace is 900×620 points.
- `StageLayoutEditor` brings a source to the front on a tile tap, source-row
  tap, keyboard move, and the start of a drag or resize. Selecting or moving a
  covered item therefore changes the audience stack as a side effect.
- Every editable tile displays a title, outline, crop control, and resize
  handle. Overlapping content also overlaps these controls.
- Pause/Resume already provide the necessary temporary-hide behavior: clear
  the pixels, retain the layer geometry and order, and wait for a fresh frame
  before showing it again. Canvas access is through a context menu, while
  source management lives in a separate view or optional rail.

These are code-review findings and the user's reported experience. They are
not a claim that baseline installation or manual acceptance has been completed.

The follow-up report identifies a second source of friction: square sources and
applied crops still inherit a larger placement rectangle's editing outline and
movement limits. Letterbox margins then behave like part of the source, making
visible edges harder to position and blocking access to content underneath.

## Alternatives considered

| Option | Benefit | Cost |
| --- | --- | --- |
| Keep Canvas and Sources separate; add shortcuts | Small structural change | Ordinary source actions still interrupt visual editing; shortcuts do not solve discovery or covered-layer selection. |
| Put all actions on every Canvas tile | Direct access when tiles are large and separate | Overlapping or small tiles obscure both content and controls. |
| Add a live visibility flag separate from Pause | Instant audience-only hiding | Creates two similar hidden states and lets capture continue when the user expects it to stop. |
| Keep a layer list beside the Canvas and separate selection from ordering | Stable access to every layer with predictable audience output | Uses some horizontal Canvas space and requires compact row controls. |

## Chosen design

Use one Workspace composition view with a persistent layer list beside the
Canvas, including at the minimum window size. Keep Stage Settings, Appearance,
Permissions, Privacy, and About in navigation. The list runs from front to back
and includes hidden or disconnected layers.

Selection belongs to the private editor. Canvas and list share the selected
source ID; selecting, dragging, resizing, or opening Crop does not change the
stack. Only the selected tile displays editing chrome. The selected outline may
be accessible above overlapping private controls without moving its source
pixels forward. Move a selected rear or hidden layer by dragging its private
title badge or using arrow keys; its resize handle remains accessible above
the overlap. The selected overlay's transparent interior passes clicks through
to visible foreground content so selecting another layer stays natural.
Move Forward, Move Backward, Bring to Front, and Send to Back
are explicit ordering actions; commands at the stack boundary have no effect.

Arrange controls follow the visible aspect-fitted source or applied crop.
Selection outlines, hit targets, title badges, and resize handles exclude empty
letterbox margins, which pass clicks through to lower layers. At the start of a
move, compact the placement rectangle to the visible content without changing
its displayed position or scale, then clamp movement by those visible edges.
Resize proportionally from the fixed visible upper-left corner. Keyboard and
VoiceOver actions use the same geometry, and hidden layers retain their last
bounds. This keeps free destination rectangles for Quick Layout while making
direct manipulation match the content the user sees. Crop remains a private
draft; only Apply changes the bounds used when returning to Arrange.

Use the content-sized selection outline as the Arrange keyboard focus indicator.
Disable the positioned overlay's additional native focus effect, whose host
bounds can leave a second ring at the previous location during movement. Keep
keyboard focus and the normal focus feedback of list rows and buttons.

Provide direct Hide/Show controls in the layer list and selected-layer tools.
Hide uses the existing Pause transition: suppress presented pixels and stop
that stream while retaining placement, crop, and order. Show uses Resume and
keeps the layer transparent until a new complete frame arrives. It does not
reuse a saved thumbnail or reveal stale content. The list preserves an access
point for the hidden layer. A disconnected source keeps Select Again; Remove
continues to require confirmation.

The audience Stage, Curtain, exact-window sharing guidance, picker consent,
capture scope, StoreKit behavior, and distribution process retain their existing
contracts. The change adds no source-application control, permission, persistence,
network service, or dependency. This is a composition workflow change, so help,
review guidance, and synthetic website screenshots must match before release.

## Implementation plan

1. Keep private selection in the controller and clear it on selected-layer
   removal or Stop All. Provide deterministic stack operations in the layout
   core, preserving source IDs, frames, and applied crops.
2. Remove implicit promotion from Canvas/list selection and movement. Synchronize
   list selection and selected Canvas chrome; expose ordering through named
   controls and accessibility actions. Restrict the selected overlay's editing
   hit targets to its title badge and resize handle so its transparent interior
   permits foreground selection.
3. Make the layer list persistent in the composition view, with front-to-back
   rows and direct visibility controls. Reuse existing pause/resume state and
   transition eligibility rather than introduce another visibility model.
4. Update Japanese/English help and review materials. Refresh synthetic UI
   fixtures after the implementation stabilizes; keep private source titles and
   real meeting content out of public evidence.
5. Share the visible-content projection between Arrange hit testing and editing
   geometry. Normalize the destination on the first move without a visual jump,
   use proportional resize, and retain geometry across temporary hiding. Cover
   both source-aspect changes and applied crops without changing draft semantics.

## Acceptance plan

Record results against the exact candidate commit. The following checks are
planned; this document does not mark them as passed.

- Place square and portrait synthetic sources in wide tiles, then apply a crop
  with a different aspect ratio. Verify outlines, titles, and handles follow
  the visible content; click through each empty margin to a lower layer. Move
  by mouse and keyboard to every Stage edge with no first-gesture position or
  scale jump. Resize by mouse, keyboard, and VoiceOver and verify proportions,
  the fixed visible upper-left corner, and minimum size. Repeat after Quick
  Layout, a live source-window resize, and Hide/Show. Compare Canvas, Stage,
  and an explicit Audience PNG.
- Edit a crop draft, cancel it, then edit and apply it. Arrange bounds must
  reflect only the applied crop. Hide a cropped source and check that its last
  bounds remain usable without revealing old pixels while capture resumes.
- Use synthetic content in at least three overlapping sources. Select the
  fully covered bottom source through the list, drag its title badge, move it
  with arrow keys, and resize it. Click visible foreground content inside the
  rear layer's selection outline and verify the foreground layer is selected.
  Verify
  the stack is unchanged in the Canvas, Stage, and explicit Audience PNG.
- Exercise each ordering command at the middle and both boundaries. Verify the
  list stays front-to-back and geometry/crop do not change. Check that private
  selection alone does not change pointer ownership or audience pixels.
- Hide a cropped layer, select it while hidden, and show it. Verify retained
  geometry/order, no source pixels in all three outputs while hidden, and no
  stale frame during resume. Cover rapid repeated actions, stream failure,
  picker cancellation, and disconnected-layer reselection.
- Verify only selected-layer editing chrome appears; test small overlapping
  tiles and the 900×620-point Workspace. Check both languages, light/dark,
  keyboard navigation, VoiceOver labels/actions, Increase Contrast, and Reduce
  Motion. During continuous dragging, the single selection outline must follow
  the source without a second ring remaining at its previous position. Verify
  arrow-key movement and visible keyboard focus on the crop button. Layer
  buttons must remain independently reachable.
- Recheck Crop draft/apply/cancel, Quick Layout, Draw/Undo/Clear, Curtain,
  Workspace/Stage close and reopen, selected-source removal cancellation,
  Stop All, and source-count limits. Public Stage/PNG must contain no private
  selection, layer controls, or hidden source pixels.
- Run repository source gates and pull-request CI; install the candidate for
  Computer Use testing and retain synthetic before/after evidence. Complete the
  broader OS, hardware, commerce, meeting-app, and exact-candidate requirements
  in [RELEASE.md](RELEASE.md) before release, with actual results and any approved
  exceptions recorded separately.
