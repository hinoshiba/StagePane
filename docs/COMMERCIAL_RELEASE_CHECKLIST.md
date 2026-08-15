# Commercial release checklist

## Product and rights

- [ ] Publisher legal entity and authorized signer identified
- [ ] StagePane name/logo clearance completed in every launch market
- [ ] Publisher-controlled domain, bundle ID, support address, and privacy URL
- [ ] Apache-2.0, NOTICE, trademark policy, SBOM, and bundle notices reviewed
- [ ] Every dependency and asset has origin, version, hash, license, and notice
- [ ] Contributor DCO provenance is complete; no incompatible inbound code

## Apple and binary

- [ ] Apple Developer agreements/tax/banking current
- [ ] Developer ID/App Store certificates and recovery process verified
- [ ] Universal signed build, Hardened Runtime, notarization, and staple pass
- [ ] App Sandbox entitlement and privacy manifest match the binary
- [ ] No private APIs, forbidden entitlements, updater, license key, or driver
- [ ] Mac App Store archive has no absolute `LC_RPATH`, placeholder, or missing
      legal/help/localization/icon resource; Organizer validation passes
- [ ] App Review notes and demo path independently reproduced

## Privacy and consumer terms

- [ ] Privacy policy identifies publisher, data flows, retention, controls, and contact
- [ ] App Privacy answers are evidence-backed; `Data Not Collected` remains true
- [ ] Terms, EULA strategy, support policy, warranty disclaimers, and refunds reviewed
- [ ] Pricing, tax, payment, cancellation, and delivery disclosures complete
- [ ] Japan Specified Commercial Transactions Act page includes seller name,
      address, telephone, representative, price/additional fees, payment method
      and timing, delivery timing, returns/cancellation, and system requirements
- [ ] Export controls, sanctions, encryption questionnaire, and age rating assessed

## Quality and launch

- [ ] CI, signed acceptance matrix, performance soak, and accessibility pass
- [ ] Screenshots/metadata show the real app and avoid “virtual display” claims
- [ ] Website/download URLs, checksums, SBOM, and support channels verified
- [ ] Incident response, rollback message, release signing, and key rotation ready
- [ ] Rating prompt uses StoreKit only after a successful natural stopping point

No unchecked item should be silently waived. Record approver, evidence, date,
scope, and expiry for every exception.
