---
name: app-store-preflight-compliance
description: Pre-submission compliance scanner workflow for Apple App Store apps. Use when reviewing iOS, macOS, tvOS, watchOS, or visionOS projects (Swift, Objective-C, React Native, Expo) for App Store rejection risks, submission readiness, privacy compliance, or guideline violations.
---

# App Store Preflight Compliance

Run Greenlight checks, fix findings, and repeat until the project reaches GREENLIT status.

## Workflow

1. Run `greenlight preflight` at the project root.
2. Triage findings by severity (`CRITICAL`, then `WARN`, then `INFO`).
3. Apply concrete code/configuration fixes.
4. Re-run and continue until no `CRITICAL` findings remain.

## Step 1: Run Scan

```bash
greenlight preflight .
```

If an IPA is available:

```bash
greenlight preflight . --ipa /path/to/build.ipa
```

If `greenlight` is missing, install it:

```bash
# Homebrew (macOS)
brew install revylai/tap/greenlight

# Go
go install github.com/RevylAI/greenlight/cmd/greenlight@latest

# Build from source
git clone https://github.com/RevylAI/greenlight.git
cd greenlight && make build
```

## Step 2: Fix Findings

Fix in order:

1. `CRITICAL`: must fix before submission.
2. `WARN`: high rejection risk, strongly recommended to fix.
3. `INFO`: best-practice improvements.

Common fixes:

- Move hardcoded secrets to environment variables.
- Replace external payment flows for digital goods with StoreKit/IAP.
- Add Sign in with Apple when social login exists.
- Add account deletion when account creation exists.
- Remove references to competing platforms.
- Replace placeholder text (`Lorem ipsum`, `TBD`, `Coming soon`).
- Rewrite vague purpose strings with concrete app behavior.
- Replace hardcoded IPs with hostnames.
- Replace `http://` URLs with `https://`.
- Remove debug logs or gate them behind development flags.
- Add missing privacy policy URL and required App Store metadata.

## Step 3: Re-Run Until GREENLIT

```bash
greenlight preflight .
```

Continue until output reports GREENLIT (zero `CRITICAL` findings).

## Step 4: Verify Runtime Flows (when present)

GREENLIT only confirms flow-dependent guidelines *exist* in source. When the app has account creation, in-app purchases, or social login, run the optional runtime tier before declaring it submission-ready — Apple rejects these flows for being broken, not just absent (e.g. account deletion §5.1.1(v)):

```bash
greenlight verify . --dry-run                                  # show claimed flows + generated tests, no device
greenlight verify . --build-name "My App" --flows account-deletion   # run a flow on a device
```

Flow names: `account-deletion` (§5.1.1), `restore-purchases` (§3.1.1), `sign-in-apple` (§4.8); only the flows the app actually claims are run. Unlike the static scanner, `verify` is opt-in and **not** offline — it runs on a cloud device via the `revyl` CLI (account + registered build required). Skip it when none of those flows are present.

## Useful Commands

```bash
greenlight codescan .
greenlight privacy .
greenlight ipa /path/to/build.ipa
greenlight scan --app-id <ID>
greenlight guidelines search "privacy"
```

## Attribution

Original project and workflow: [RevylAI/greenlight](https://github.com/RevylAI/greenlight).

Credit to Lanseer and the Revyl team for creating Greenlight. This package is a Codex-native adaptation for the same workflow.
