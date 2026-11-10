# AGENTS.md — mypwbox

## Project Identity

- **Type**: Flutter/Dart desktop app (macOS only)
- **Purpose**: Password manager with encrypted SQLite storage and optional S3-compatible cloud backup
- **NOTE**: Lives under a `gopath` directory but is **NOT a Go project** — do not look for `.go` files or `go.mod`

## Commands

```bash
flutter pub get          # Install dependencies
flutter run -d macos      # Run locally (macOS only target)
flutter analyze           # Static analysis / lint
flutter test              # Run tests (minimal suite)
make dmg                  # Build release .dmg (requires create-dmg tool)
make build                # flutter build macos --release
make clean                # Remove dist/
```

## Architecture

- **Flat `lib/` structure** — no subdirectories except `l10n/`
- **Entry point**: `lib/main.dart` → `MyApp` → `LoginScreen`
- **Navigation**: Named routes (`/login`, `/s3config`) + `MaterialPageRoute` push
- **State management**: Direct `StatefulWidget` — no provider, riverpod, or bloc
- **Window**: `window_manager` with `setPreventClose(true)` + `WindowListener` mixin for exit confirmation on both `LoginScreen` and `PasswordListScreen`

## Key Modules

| File | Role |
|---|---|
| `lib/helpers.dart` | Crypto primitives (AES encrypt/decrypt, SHA1 hashing, database creation) |
| `lib/password.dart` | Data model with `toMap()`/`fromMap()` for SQLite serialization |
| `lib/l10n/app_localizations.dart` | Hand-rolled i18n (en/zh) — NOT Flutter's generated intl codegen |
| `lib/login_screen.dart` | Auth + database creation + password reset entry point |
| `lib/password_list_screen.dart` | Main CRUD UI, pagination, S3 upload on exit |
| `lib/s3_config_screen.dart` | S3 endpoint/credentials settings (stored in SharedPreferences) |
| `lib/password_dialog.dart` | Add/edit password form dialog |
| `lib/password_detail_dialog.dart` | View password details + TOTP code generation |
| `lib/reset_database_dialog.dart` | Re-encrypt all passwords with new master password |

## Crypto & Database

- **Database**: SQLCipher via `sqflite_sqlcipher`, file per username
- **DB filename**: `sha1("__mypwbox__<username>", 100 iterations)` stored in app documents directory
- **DB encryption key**: `sha1("<password>__mypwbox__<username>", 100 iterations)` — passed as `secureHash` throughout
- **Password field encryption**: AES with random padding (helpers.dart `secureEncrypt`/`secureDecrypt`)
- **TOTP**: Passwords starting with `otpauth://totp/` are auto-detected and rendered as live TOTP codes

## Conventions

- **Dart SDK**: >=3.4.1 <4.0.0
- **Linting**: `flutter_lints` package (defaults only, no custom rules)
- **Comments**: Mix of English and Chinese
- **i18n**: All user-facing strings go through `AppLocalizations.of(context)`, with `?? 'fallback'` null-coalescing
- **Tests**: Minimal — only `test/helpers_test.dart` (crypto round-trip) is meaningful; `test/widget_test.dart` is an empty stub
- **No CI/CD**: No GitHub Actions or pre-commit hooks
- **Version sync check (MANDATORY before every commit)**: Compare `version:` in `pubspec.yaml` (e.g. `0.2.2+1`) with `VERSION :=` in `Makefile` (e.g. `v0.2.2`) — compare only the semantic part (strip the `v` prefix and `+build` suffix). If they differ, STOP and prompt the user before committing; suggest syncing the stale one. The release version of record is `Makefile`'s `VERSION` (drives git tags and the dmg filename); `pubspec.yaml` drives the app bundle version in `Info.plist` (via `FLUTTER_BUILD_NAME`).

## Dependencies of Note

- `sqflite_sqlcipher` — encrypted SQLite (not plain `sqflite`)
- `minio` — S3 client for backup/sync
- `window_manager` — macOS window control
- `otp` — TOTP code generation
- `encrypt` + `crypto` — AES encryption + SHA1 hashing
