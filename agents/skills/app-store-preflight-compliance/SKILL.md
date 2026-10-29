---
name: app-store-preflight-compliance
description: App Store readiness audit for iOS, macOS, tvOS, watchOS, or visionOS apps. Use for rejection risks, submission readiness, privacy compliance, guideline violations, or unresolved App Review feedback.
---

# App Store Preflight Compliance

Audit the build Apple will review, its working user flows, and the information reviewers need. Greenlight is a scanner gate, not an approval prediction. Keep audits read-only unless fixes are requested; submission, reviewer correspondence, and production changes need their own authorization.

## 1. Establish the review target

Record the app/bundle ID, platform, version/build, source commit, and available binary. For an existing submission, read its current App Store Connect status, selected build, review notes, and latest reviewer messages. A build creation date is not a submission date.

Compare the submitted build's source with the current checkout before attributing a defect or recommending a rebuild. Track deployed backend, remotely loaded content, and feature-flag versions separately. Inspect generated manifests, entitlements, and purpose strings in the archive when available; source declarations alone do not prove shipped configuration.

**Done:** identify what each evidence source describes. Mark unavailable build, listing, or deployment evidence unverified; continue source checks without treating latest code as the submitted app.

## 2. Run Greenlight

Run from the app project root:

```bash
greenlight preflight .
# Include the target device archive when available:
greenlight preflight . --ipa /path/to/build.ipa
```

If setup is needed, read [Greenlight setup](references/greenlight.md#setup). Record the scanned revision, binary, tool version, and findings. If the scanner cannot run, report that gap and continue manual review.

**Done:** retain the scan result or exact execution blocker, not an assumed pass.

## 3. Resolve rejection risks

Triage `CRITICAL` and any blocking `BLOCK`/`HIGH` tiers first, then `WARN`, then `INFO`. Verify findings against the app and the current [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/); scanner severity is not an Apple decision. Check applicable platform, storefront, entitlement, and business-model exceptions before prescribing changes, especially for payments (§3.1) and equivalent login options (§4.8).

Common checks:

- Remove placeholders and broken or unfinished routes. Favor a complete initial release over optional complexity; do not hide functionality from review or enable noncompliant behavior afterward.
- Keep secrets out of the client, use HTTPS, replace brittle hardcoded IPs, and remove sensitive production logs. Environment variables embedded in a client are not secret storage.
- Reconcile actual collection and SDK behavior with purpose strings, consent, privacy manifests, privacy labels, and the published policy. Open the configured privacy, terms, and support URLs; checked-in drafts do not prove live content.
- Check account deletion, purchase/restore access, and login requirements where applicable. Verify user-generated-content reporting, blocking, moderation, and support when the app supports UGC (§1.2).
- Compare listing claims, screenshots, and purchase disclosures with the target build; remove misleading claims and irrelevant competing-platform references rather than blindly deleting legitimate content.

When fixes are authorized, apply concrete code/configuration changes and rerun the affected checks, then `greenlight preflight .`. Stop at unresolved blockers or missing access; do not loop indefinitely.

**Done:** account for every finding as fixed and rechecked, supported exception/false positive, unresolved risk, or unverified. GREENLIT requires zero blocking findings under every severity label the installed version emits.

## 4. Rehearse the app on the target build

Exercise cold launch, onboarding, core advertised features, navigation, and error recovery on supported devices/sizes. Check keyboard, safe areas, text sizing, and permission denial as relevant. Assess observed behavior without requiring a framework rewrite or treating visual taste as proof of reviewer preference.

For account creation, IAP, or social login, read [Greenlight runtime verification](references/greenlight.md#runtime-verification) and run every claimed flow with `greenlight verify`. Supplement its coverage with the app's purchase, restore, subscription management, account deletion, and support routes as applicable. A present button or passing source test does not prove the flow completes. Use sandbox purchases and disposable accounts; do not delete customer data or charge real accounts to test readiness.

**Done:** record each applicable flow's build, environment, device, and pass/fail/unverified result. A dry run, skipped test, missing credentials, or unavailable device is unverified. Passing Greenlight's claimed flows does not cover other advertised functionality automatically.

## 5. Make the review reproducible

Read Apple's [complete-review guidance](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review). Draft or inspect concise review notes that a first-time user can follow:

- State the app's purpose/audience and the shortest route through its main features.
- Give exact steps for gated or non-obvious functionality, purchases/restore, safety controls, deletion, and relevant permission/data-sharing behavior.
- Verify working reviewer access and representative data so time-based or social features can be tested without waiting days or another person's approval. Explain test setup and any demo accommodations honestly; preserve the real functionality under review.
- Keep credentials in App Store Connect's protected review fields, out of reports and recordings. Check that the required backend services and review resources are reachable.

Attach a short walkthrough of the target build when it resolves navigation, hardware, or timing ambiguity, or Apple requests one. It supplements working access; a video is not a universal requirement or a substitute for a functional app. Check any required regulated-feature documentation. Do not invent access, claim attachments exist, or upload/post drafts without authorization.

**Done:** every review step maps to a reachable feature in the target build, or has a named evidence gap. Distinguish an absent review resource from one you could not inspect.

## 6. Report readiness and review status separately

Return the target build/revision, scan outcome, runtime coverage, prioritized findings with evidence and applicable Apple sources, recommended fixes, and remaining verification gaps. Separate confirmed defects from suspected risks. Reserve a readiness verdict for no unresolved material rejection risks, a GREENLIT scan, and verified applicable flows and review resources; otherwise state what prevents that verdict. Never guarantee approval or a turnaround time.

If a submission is waiting, report the verified status and timestamp separately from compliance findings. A queue delay alone is not a rejection or evidence of a particular defect. Use [App Review contact guidance](https://developer.apple.com/help/app-review/after-submitting-for-review/contact-app-review) for a factual inquiry or a guideline-specific response; a call is not a proven queue shortcut. Consider [expedited review](https://developer.apple.com/help/app-review/after-submitting-for-review/request-expedited-review) only for genuine qualifying urgency. Do not manufacture a reason, promise a special queue, or cancel/resubmit merely to chase speed.

**Done:** the report states what is ready, what is blocked or unverified, and which next actions require the owner's involvement.

## Attribution

Greenlight workflow: [RevylAI/greenlight](https://github.com/RevylAI/greenlight), created by Lanseer and the Revyl team. Reviewer-clarity and completeness principles informed by [Frederick James's article](https://x.com/frederickjames/status/2086419927548809285), treated as practitioner advice; Apple sources govern policy claims.
