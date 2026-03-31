# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [Script v1.0.13] - 2026-03-31

### Added

- Playwright as optional install tool (`oa --install`) — installs `playwright-core`, auto-configures Chromium path and environment variables

### Fixed

- Auto-disable Bonjour/mDNS when Android/Termux only exposes loopback (`lo`) to Node.js, preventing noisy Gateway shutdown warnings

### Changed

- Bump Gson 2.12.1 → 2.13.2
- Bump androidx.core:core-ktx 1.17.0 → 1.18.0
- Bump ktlint gradle plugin 14.1.0 → 14.2.0
- Bump Gradle wrapper 9.3.1 → 9.4.1
- Bump eslint 9.39.4 → 10.0.3
- Bump globals 16.5.0 → 17.4.0
- Bump eslint-plugin-react-refresh 0.4.24 → 0.5.2
- Bump GitHub Actions: checkout v4→v6, setup-node v4→v6, setup-java v4→v5, upload-artifact v4→v7, download-artifact v4→v8

## [App v0.4.0 / Script v1.0.12] - 2026-03-30

### Added

- App: i18n support — English, Korean (한국어), Chinese (中文) with auto-detection
- App: Language selector in Settings
- Add Chinese README (README.zh.md) with China mirror download link
- Add language switcher links to README.md, README.ko.md, README.zh.md
- GitHub mirror fallback for China/restricted networks (ghfast.top, ghproxy.net)
- npm registry auto-switch to npmmirror.com when npmjs.org is unreachable
- Add AppLogger centralized logging wrapper, replace all android.util.Log calls
- Add unit test infrastructure (JUnit5 + MockK, 22 tests)
- Add CI code-quality workflow (shellcheck, sync check, markdownlint, doc freshness, kotlin lint, unit tests)
- Add shellcheck, markdownlint to pre-commit hook
- Add post-setup.sh sync verification to pre-commit hook
- Add Claude Code hooks (push warning, document freshness, shellcheck auto-run)

### Changed

- Resolve all 48 detekt violations — no baseline needed
- Resolve all 43 shellcheck violations across all scripts
- Resolve all 125 markdownlint violations across all documents
- Refactor BootstrapManager, JsBridge, MainActivity for reduced complexity
- Convert A&&B||C patterns to if/then/else in install.sh, install-tools.sh
- Bump app version to v0.4.0 (versionCode 9)
- Bump script version to v1.0.12

## [1.0.6] - 2026-03-10

### Changed

- Clean up existing installation on reinstall

## [1.0.5] - 2026-03-06

### Added

- Standalone Android APK with WebView UI, native terminal, and extra keys bar
- Multi-session terminal tab bar with swipe navigation
- Boot auto-start via BootReceiver
- Chromium browser automation support (`scripts/install-chromium.sh`)
- `oa --install` command for installing optional tools independently

### Fixed

- `update-core.sh` syntax error (extra `fi` on line 237)
- sharp image processing with WASM fallback for glibc/bionic boundary

### Changed

- Switch terminal input mode to `TYPE_NULL` for strict terminal behavior

## [1.0.4] - 2025-12-15

### Changed

- Upgrade Node.js to v22.22.0 for FTS5 support (`node:sqlite` static bundle)
- Show version in all update skip and completion messages

### Removed

- oh-my-opencode support (OpenCode uses internal Bun, PATH-based plugins not detected)

### Fixed

- Update version glob picks oldest instead of latest
- Native module build failures during update

## [1.0.3] - 2025-11-20

### Added

- `.gitattributes` for LF line ending enforcement

### Changed

- Bump version to v1.0.3

## [1.0.2] - 2025-10-15

### Added

- Platform-plugin architecture (`platforms/<name>/` structure)
- Shared script library (`scripts/lib.sh`)
- Verification system (`tests/verify-install.sh`)

### Changed

- Refactor install flow into modular scripts
- Separate platform-specific code from infrastructure

## [1.0.1] - 2025-09-01

### Fixed

- Initial bug fixes and stability improvements

## [1.0.0] - 2025-08-15

### Added

- Initial release
- glibc-runner based execution (no proot-distro required)
- One-command installer (`curl | bash`)
- Node.js glibc wrapper for standard Linux binaries on Android
- Path conversion for Termux compatibility
- Optional tools: tmux, code-server, OpenCode, AI CLIs
- Post-install verification
