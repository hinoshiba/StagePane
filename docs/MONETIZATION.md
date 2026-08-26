# StagePane Pro: market, persona, purchase, and launch plan

Research date: 2026-08-25
Decision status: implemented product boundary; App Store Connect setup remains
an authorized release-owner action.

## Decision

The official Mac App Store binary uses a useful free app plus one permanent,
non-consumable In-App Purchase:

| | Free | StagePane Pro |
|---|---:|---:|
| Simultaneous sources | 2 | 4 |
| StagePane mark | Always shown | Optional |
| Curtain, Stop All, pause, replace, and remove | Included | Included |
| Arrange, Draw, layouts, pointer, and stage shapes | Included | Included |
| Audience image copy/save | Included, with mark | Included, mark optional |
| Billing | None | One-time purchase |

- Product ID: `com.hinoshiba.stagepane.pro`
- App Store Connect Apple ID: `6805630496`
- Type: Non-Consumable
- Reference name: `StagePane Pro Lifetime`
- Japan launch price: **¥500**
- United States launch price: **$4.99** (Apple's closest price point to $5). Use the United States as the base
  storefront, override Japan to ¥500, and review Apple's automatically
  generated, locally rounded prices for every other storefront. The shipping
  app always displays StoreKit's localized price instead of hardcoding one.
- Family Sharing: off for the first release; enabling it is a separate,
  effectively irreversible product decision
- No subscription, account, external license key, advertising, or analytics SDK
- Source-built development binaries expose all features. Commerce applies only
  to the official `StagePaneAppStore` target.

The purchase screen promises only features present in the submitted binary.
Future Pro additions are not advertised before they ship.

## Why this boundary

The free product must demonstrate StagePane's entire trust proposition before
asking for money. One or two sources are enough for an everyday meeting and let
people validate the exact Stage/Workspace boundary, Apple picker, Curtain,
Stop All, layouts, Draw, and PNG export. A third source is a natural signal that
the person is using StagePane for a professional demo, class, or production.

Brand removal is similarly tied to professional output rather than safety. It
must cover every audience-facing state consistently: holding screen, captured
content, Curtain, Workspace preview, copied image, and saved PNG.

The following must never become paid safety gates:

- Privacy Curtain and Stop All
- pause, resume, replace, remove, and removal confirmation
- picker-scoped permission guidance
- Arrange and Draw
- accessibility and keyboard operation
- output quality, supported shapes, and crash/security fixes

## Priority personas and jobs

| Priority | Persona | Job to be done | Main anxiety | Honest purchase moment |
|---:|---|---|---|---|
| 1 | Sales engineer, customer success, developer advocate | Show slides, a live product, and a terminal/reference without leaking chat or notifications | Sharing the wrong window in front of a customer | Adds a third source |
| 2 | Teacher, trainer, workshop host | Combine lesson material, a code/demo window, and supporting content while drawing attention live | Losing time to complex broadcast software | Adds a third source; wants a clean recorded/classroom image |
| 3 | Consultant, executive, client-facing presenter | Deliver a polished client-branded presentation | A utility logo makes the output feel informal | Turns the StagePane mark off |
| 4 | Creator or lightweight streamer | Compose a few sources without learning OBS | Simple tools becoming unreliable or unexpectedly recording data | Adds a third source; turns the mark off |
| 5 | Everyday meeting participant | Share one or two windows safely | Being forced to subscribe before proving value | Remains on Free and can become an advocate |
| 6 | Open-source user who prefers the official signed build | Install and update through the App Store while supporting continued maintenance | Being guilted into paying for code that can be built freely | Buys Pro for its shipped unlocks and convenience, never as a donation requirement |

Organizations using Apple Business Manager or Apple School Manager are a
separate procurement persona. In-App Purchases can be awkward for centralized
volume deployment. If that demand is validated, assess a separate paid full
edition or Custom App instead of distorting the consumer IAP.

## Market frame

Prices and offers change; verify them again before every pricing decision.

| Product | Observed model | Implication for StagePane |
|---|---|---|
| [Screegle US](https://apps.apple.com/us/app/screegle-clean-screen-sharing/id1591051659?mt=12) / [Japan](https://apps.apple.com/jp/app/screegle-clean-screen-sharing/id1591051659?mt=12) | Free: two windows and non-removable branding; Pro about $7.99 / ¥1,300 | Strong validation of the same Free-2 plus brand-removal boundary |
| [SliceShare](https://apps.apple.com/us/app/sliceshare-screen-sharing/id6736578460?mt=12) | Free plus about $8.99 Pro | Focused selective-sharing utilities sit near the $10 one-time anchor |
| [Sel](https://apps.apple.com/us/app/sel-screen-window-sharing/id6780409611?mt=12) | Free plus about $19.99 / ¥3,000 lifetime | A $20 tier needs broader scene, camera, recording, or overlay value |
| [Zone Share](https://apps.apple.com/us/app/zone-share-screen-sharing-tool/id6743621581?mt=12) | Subscription and lifetime options around $19.99–24.99 | Reliability in real meeting apps matters more than a long feature list |
| [Presentify](https://apps.apple.com/jp/app/presentify-screen-annotation/id1507246666) | About $14.99 / ¥2,500 one-time | Mature annotation can support a higher price; StagePane differentiates by drawing inside the shared Stage window |
| [DemoPro](https://www.demoproapp.com/) | $3.99 one-time | Annotation-only utilities establish a lower price anchor |
| [OBS Studio](https://obsproject.com/) | Free and open source | StagePane wins on safe setup in under 60 seconds, not raw feature count |

At the current feature set, ¥500 / $4.99 is an intentionally accessible launch
price below the closest commercial alternatives. Revisit a higher price only
after shipping and validating meaningful additions such as local scene/layout
presets, presenter notes/timer, or user-selected branding assets.

### Price and proceeds operating rules

- Confirm the In-App Purchase tax category in App Store Connect; `App Store
  software` is the likely default, but the release owner must validate it for
  the publisher and launch territories.
- Model proceeds after applicable taxes and Apple's commission. Do not assume
  the publisher receives the displayed ¥500: the standard commission is
  generally 30%, or
  15% only while the account is approved for and remains eligible under the
  App Store Small Business Program. Finance should use App Store Connect's
  actual proceeds reports, not these planning percentages.
- Keep the launch price unchanged for at least eight weeks unless there is a
  material listing error. Avoid training customers to wait for discounts.
- Review price only after enough evidence: at least 1,000 product-page views
  and 100 completed Pro purchases across the primary storefronts, plus a full
  refund window. Segment Japan and English-language storefronts rather than
  averaging them blindly.
- Consider a future ¥2,000–2,500 price only after at least one substantial Pro
  addition ships, paid conversion remains at or above 4%, refunds stay below
  3%, and rating/reliability signals remain healthy. If paid conversion is
  below 1.5%, first test clearer screenshots, positioning, and onboarding;
  price is not automatically the cause.
- Record every decision with the comparison window, downloads, paid
  conversion, proceeds per download, refunds, crash-free use, and rating
  distribution. These thresholds are decision guardrails, not promises or
  statistical proof.

References:

- [App Store Small Business Program](https://developer.apple.com/app-store/small-business-program/)
- [Set a tax category](https://developer.apple.com/help/app-store-connect/manage-app-information/set-a-tax-category/)
- [View payments and proceeds](https://developer.apple.com/help/app-store-connect/getting-paid/view-payments-and-proceeds/)

## Purchase journey

There are exactly three entry points:

1. A Free user with two active sources chooses Add Source.
2. A Free user turns off the StagePane mark in Appearance.
3. A person deliberately opens StagePane Pro from the Workspace or app menu.

Do not show the purchase screen at first launch, before the first picker, while
a person is presenting, after a purchase cancellation, or as a condition of
using a privacy control.

### Third-source flow

1. Keep both active sources running and unchanged.
2. Open StagePane Pro inside the private Workspace; never alter the audience
   Stage or put purchase UI in it.
3. Explain why this screen appeared: “Your third source is ready with Pro.”
4. Show the localized `Product.displayPrice` and state explicitly that this is
   a one-time purchase.
5. On a verified successful transaction, dismiss the StoreKit purchase UI and
   resume the original Add Source flow by opening Apple's picker.
6. On cancel, do nothing and preserve the Stage. On pending approval, explain
   that Pro will unlock automatically. On failure, offer retry and restore.

### Mark-removal flow

1. Leave the mark visible while access is unverified.
2. Explain that Pro removes it from the Stage, Curtain, and Audience images.
3. After verified purchase or restore, complete the original request by turning
   the mark off and return to Appearance.
4. If a refund/revocation later removes entitlement, show the mark again but do
   not stop an active capture session.

### Restore flow

The app checks `Transaction.currentEntitlements` proactively at launch. The
Restore Purchases button remains available for exceptional cases and calls
`AppStore.sync()` only after an explicit click because that call can present an
Apple Account authentication prompt.

## Non-dark-pattern rules

- Never obscure “Continue Free.”
- Never label one product “Most Popular.”
- Never invent a countdown, discount, review, user count, or scarcity claim.
- Never make “Continue” secretly mean purchase.
- Never hardcode a currency or price in shipping UI.
- Never treat cancel as an error or immediately present the offer again.
- Never hide purchase restoration.
- Never gate an unlock behind a rating, review, or social post.
- Never route only satisfied users to the App Store rating prompt.
- Never claim an App Store rank that has not been achieved.

## StoreKit implementation contract

The authoritative implementation lives in:

- `Sources/StagePane/Purchase/ProPurchaseStore.swift`
- `Sources/StagePane/Purchase/ProUpgradePanel.swift`
- `Sources/StagePaneCore/StagePaneAccess.swift`
- `Config/StagePane.storekit`

Security and lifecycle requirements:

- Check `Transaction.currentEntitlements` at launch.
- Listen to `Transaction.updates` for purchase, restore, refund, revocation, and
  purchases completed on another device.
- Grant access only for a verified transaction matching the exact product ID.
- Finish a handled verified transaction.
- Never persist a Boolean “isPro” as an entitlement source.
- Fail closed for Pro-only operations while entitlement is checking or cannot
  be verified; keep every free and safety feature available.
- Keep the physical capture maximum at four and the current plan limit at two
  or four. Enforce the plan again immediately before creating a stream because
  ScreenCaptureKit's system video menu can bypass the app's Add Source button.
- If access is revoked with three or four sources active, preserve that live
  session and block only new additions. Do not destructively stop a presentation.
- Official builds use StoreKit. Source builds have full feature access so the
  Apache-licensed repository remains useful to contributors.

Apple references:

- [In-App Purchase with StoreKit](https://developer.apple.com/documentation/storekit/in-app-purchase)
- [`Transaction.currentEntitlements`](https://developer.apple.com/documentation/storekit/transaction/currententitlements)
- [`AppStore.sync()`](https://developer.apple.com/documentation/storekit/appstore/sync%28%29)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [In-App Purchase HIG](https://developer.apple.com/design/human-interface-guidelines/in-app-purchase)

## App Store Connect setup

The Product ID and type cannot be changed after creation. An Account Holder,
Admin, or App Manager should perform and independently review these steps.

1. Confirm the Paid Apps Agreement, tax, and banking status.
2. Open **Apps → StagePane → Monetization → In-App Purchases → +**.
3. Create:
   - Type: `Non-Consumable`
   - Reference Name: `StagePane Pro Lifetime`
   - Product ID: `com.hinoshiba.stagepane.pro`
4. Set availability to the intended launch storefronts.
5. Use the United States as the base storefront at $4.99, override Japan to
   ¥500, and review Apple's automatically generated, locally rounded prices
   for every other storefront.
6. Keep Family Sharing off until its refund, family-removal, support, and
   irreversible-enablement implications are explicitly approved.
7. Add localizations:

| Locale | Display name | Description |
|---|---|---|
| Japanese | `StagePane Pro` | `ロゴ非表示と最大4ソースを買い切りで開放` |
| English (U.S.) | `StagePane Pro` | `Hide the mark and compose up to four sources.` |

Both descriptions fit App Store Connect's current 45-character maximum; verify
the live limits again before submission.

8. Upload an App Review screenshot that clearly shows the in-app Pro screen,
   its two unlocks, one-time wording, localized price, Restore Purchases, and
   Continue Free.
9. For the first IAP, submit it with the app version that introduces the
   purchase. Make the review path explicit in App Review notes.
10. Validate product metadata in StoreKit Configuration, Sandbox, and TestFlight
    before tagging the release. Metadata changes can take time to appear in the
    Sandbox environment.

References:

- [Create a non-consumable IAP](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases/)
- [IAP information fields](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information)
- [Set IAP price](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase/)
- [IAP availability](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-availability-for-in-app-purchases)

### App Review notes for the IAP

> StagePane Pro is a one-time, non-consumable In-App Purchase. In the private
> “StagePane Workspace — Keep Private” window, choose “StagePane Pro” in the
> sidebar. The same screen also appears when a Free user attempts to add a
> third source or turns off the StagePane mark under Appearance.
>
> Free supports two simultaneous sources and includes all privacy and safety
> controls. Pro supports up to four simultaneous sources and makes the
> StagePane mark optional on the audience Stage, Privacy Curtain, and explicit
> Audience PNG copy/save output. Purchase UI never appears in the shareable
> Stage window. “Restore Purchases” explicitly invokes App Store sync. Only a
> StoreKit-verified transaction for `com.hinoshiba.stagepane.pro` unlocks Pro.
>
> To test the source-limit entry point, add two harmless test windows with
> Apple's ScreenCaptureKit picker, then choose Add Source again. Canceling the
> purchase changes nothing and does not interrupt either active source.

## Verification matrix

### StoreKit Configuration

- Product loads with Japanese and English localization.
- Price is read from `Product.displayPrice`.
- Successful purchase unlocks immediately.
- Third-source purchase resumes the picker.
- Mark-removal purchase immediately hides the mark.
- Cancel preserves current state and is not shown as an error.
- Ask to Buy/pending prevents duplicate purchase attempts and later unlocks
  through `Transaction.updates`.
- Product-loading and purchase failures show retryable, localized messages.
- Restore success, no-purchase result, authentication cancel, and network error
  are distinguishable.
- Unverified transactions never unlock features.
- Refund and revocation restore the mark and block new Pro-only additions.

### Sandbox and TestFlight

- New purchase, reinstall, restore, second Mac, and purchase on another device.
- Japanese and U.S. storefront price/currency.
- App Store product missing/not-yet-approved behavior.
- VoiceOver and keyboard completion of purchase, restore, retry, and Continue Free.
- No purchase or review UI appears in the audience Stage.
- Existing three/four-source session remains stable if entitlement changes.
- Mac App Store receipt and transaction behavior offline after a prior purchase.

### Regression

- Free source 1 and 2 still open Apple's picker.
- Free source 3 opens Pro from every entry point, including the system video menu.
- Pro source 4 works; source 5 is rejected by the physical maximum.
- Free Stage, Curtain, Workspace preview, Copy, and Save always include the mark.
- Pro mark preference applies consistently to every audience representation.
- Curtain, Stop All, Draw, and permission guidance remain free.
- `swift test`, strict-concurrency build, Xcode App Store build, XcodeGen drift,
  release checks, Sandbox, and signed TestFlight acceptance all pass.

## Ethical discovery and ranking plan

No implementation can guarantee first place. Apple says discoverability is
influenced by metadata relevance plus customer behavior such as downloads and
ratings. Optimize the inputs StagePane can honestly control:

1. First value in under 60 seconds; no launch paywall.
2. Screenshot 1: unmistakable private Workspace versus audience Stage.
3. Screenshot 2: “Up to four sources with StagePane Pro,” visibly labeled Pro.
4. Screenshot 3: Curtain, Draw, and Stop All as included trust features.
5. Screenshot 4: no recording, account, analytics, ads, or publisher server.
6. Request the system review prompt only after three clean completed capture
   sessions that each reached a real preview and lasted at least one minute,
   at least three days of experience, at a quiet post-session moment, and at
   most once per app version. Never pre-screen sentiment.
7. Reply promptly and specifically to Japanese and English reviews.
8. Use App Store campaign links and Apple's aggregate App Analytics rather than
   adding an analytics SDK.
9. Compare download conversion, proceeds per download, retention, refunds,
   crashes, and ratings with App Store Connect peer benchmarks.
10. Change one proposition at a time. Do not infer conversion from tiny samples.

Suggested metadata concepts, rechecked against current character limits before
submission:

- Japanese subtitle: `画面共有専用のステージ`
- Japanese concepts: プレゼン、会議、ウインドウ、配信、発表、デモ、講義、プライバシー
- English subtitle: `Screen Share Stage`
- English concepts: presentation, meeting, window, privacy, demo, teaching,
  webinar, laser, canvas, annotate

Do not duplicate the same term across name, subtitle, and keywords merely to
stuff metadata. Do not use competitor trademarks or claim “virtual display.”

Apple references:

- [App Store discovery](https://developer.apple.com/app-store/discoverability/)
- [App Store search](https://developer.apple.com/app-store/search/)
- [Ratings and reviews](https://developer.apple.com/app-store/ratings-and-reviews/)
- [Requesting App Store reviews](https://developer.apple.com/documentation/storekit/requesting-app-store-reviews)
- [App Store Connect Analytics](https://developer.apple.com/app-store-connect/analytics/)

## Next Pro candidates, only after validation

1. Local scene/layout presets that never retain source pixels or unauthorized
   window identity.
2. Presenter timer and notes visible only in Workspace.
3. User-selected local branding/background assets with sandbox-safe file access.
4. More saved visual presets without cloud or account dependencies.

Do not add recording, cloud, accounts, or a subscription merely to justify a
higher price. Each candidate needs the existing privacy, performance,
accessibility, licensing, and App Review threat model before implementation.
