# Greenlight commands

## Setup

If `greenlight` is missing, prefer Homebrew or Go so it lands on `PATH`:

```bash
brew install revylai/tap/greenlight
# Or use an explicit current release verified from the upstream project:
go install 'github.com/RevylAI/greenlight/cmd/greenlight@<version>'
```

For a source build, `make build` only writes `./build/greenlight`; install the binary before returning to the app project:

```bash
git clone https://github.com/RevylAI/greenlight.git
cd greenlight
make build
sudo install build/greenlight /usr/local/bin/greenlight
```

## Runtime verification

`verify` is opt-in and runs on a cloud device via `revyl` (account required); it is not an offline extension of `preflight`. Confirm authorization before uploading an artifact or running cloud tests.

```bash
greenlight verify . --dry-run
# Registered Revyl build:
greenlight verify . --build-name "My App" \
  --var 'email=<disposable-test-account>' --var 'password=<disposable-test-password>'
# Unregistered build: Revyl's cloud simulators need a simulator .app, not a device .ipa.
greenlight verify . --build-name "My App" --artifact ./build/MyApp.app \
  --var 'email=<disposable-test-account>' --var 'password=<disposable-test-password>'
```

A dry run shows claimed flows and generated tests without a device. `verify` runs every claimed flow by default: `account-deletion` (§5.1.1), `restore-purchases` (§3.1.1), and `sign-in-apple` (§4.8). Keep that coverage for readiness; use `--flows account-deletion` only to debug a deliberately narrowed check. Skip this tier only when none of those flows are present.

Login-gated flows need credentials and unregistered builds need `--artifact`. CLI arguments expose passwords in process lists, shell history, and transcripts. Use only disposable test credentials there; if only real credentials exist, have the human run locally or use a non-echoed credential path supported by their tooling. Missing access or a skipped flow remains unverified, never a passing runtime result.

For non-Apple projects, the upstream runtime tooling also accepts Android `.apk` artifacts; that does not establish App Store readiness.

## Focused checks

```bash
greenlight codescan .
greenlight privacy .
greenlight ipa /path/to/build.ipa
greenlight scan --app-id '<ID>'
greenlight guidelines search "privacy"
```
