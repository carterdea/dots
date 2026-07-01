---
name: app-store-preflight-compliance
description: Pre-submission compliance scanner workflow for Apple App Store apps. Use when reviewing iOS, macOS, tvOS, watchOS, or visionOS projects (Swift, Objective-C, React Native, Expo) for App Store rejection risks, submission readiness, privacy compliance, or guideline violations.
---

# App Store Preflight Compliance

Run Greenlight checks, fix findings, and repeat until the project reaches GREENLIT status.

## Workflow

1. Run `greenlight preflight` at the project root.
2. Triage findings by severity: blocking tiers first (`CRITICAL`, plus `BLOCK`/`HIGH` if your Greenlight build emits them), then `WARN`, then `INFO`.
3. Apply concrete code/configuration fixes.
4. Re-run and continue until no blocking findings remain.

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

# Build from source — make build only writes ./build/greenlight, which isn't on
# PATH, so install it before returning to the app project to run the scan.
git clone https://github.com/RevylAI/greenlight.git
cd greenlight && make build
sudo install build/greenlight /usr/local/bin/greenlight
```

Prefer `brew`/`go install` — both land `greenlight` on `PATH` directly. The rest of this workflow runs from the app project, so a source build is only usable once its binary is on `PATH`.

## Step 2: Fix Findings

Fix in order:

1. `CRITICAL` (and any higher blocking tier — `BLOCK` from `verify`, or `HIGH` if your Greenlight build emits it): must fix before submission.
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

Continue until output reports GREENLIT — zero `CRITICAL` findings, and zero of any higher blocking tier your Greenlight build reports (`BLOCK`/`HIGH`). Don't declare readiness on `CRITICAL` alone if the report still lists blocking findings under another label.

## Step 4: Verify Runtime Flows (when present)

GREENLIT only confirms flow-dependent guidelines *exist* in source. When the app has account creation, in-app purchases, or social login, run the optional runtime tier before declaring it submission-ready — Apple rejects these flows for being broken, not just absent (e.g. account deletion §5.1.1(v)):

```bash
greenlight verify . --dry-run            # show claimed flows + generated tests, no device

# Registered Revyl build. Runs every claimed flow by default; login-gated flows
# (account deletion, restore purchases) need test credentials, or the run
# dead-ends unauthenticated and proves nothing.
greenlight verify . --build-name "My App" \
  --var email=<test account> --var password=<test password>

# Local, unregistered build: upload it with --artifact. Revyl runs cloud
# simulators, so pass a simulator .app (iOS) or .apk (Android) — NOT a device .ipa.
greenlight verify . --build-name "My App" --artifact ./build/MyApp.app \
  --var email=<test account> --var password=<test password>
```

`verify` runs **every** flow the app claims by default — keep it that way so no claimed flow goes unexercised; `--flows account-deletion` is only a deliberate narrowing knob for debugging a single flow. Flow names: `account-deletion` (§5.1.1), `restore-purchases` (§3.1.1), `sign-in-apple` (§4.8). Unlike the static scanner, `verify` is opt-in and **not** offline — it runs on a cloud device via the `revyl` CLI (account required). Pass `--var` credentials for any login-gated flow and `--artifact` for a build that isn't already registered. The app is submission-ready only when `preflight` is GREENLIT **and** every claimed flow actually ran and passed under `verify` — not just "no failures." A flow that was skipped or couldn't run (missing credentials, build, or device) is unverified, not a pass, so don't declare the runtime tier green until each claimed flow has a passing result. Skip `verify` only when none of those flows are present.

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
