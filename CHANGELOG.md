# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.10.0] - 2026-03-27

### Added
- Added `parseTextPublication(at:options:)` as a text-focused API that returns line-indexed headings and flattened readable lines.
- Added DTBook-only lenient fallback for `parseTextPublication` so directory/zip inputs without an OPF can still yield readable text and diagnostics.
- Added unit coverage for text-focused parsing and DTBook-only fallback behavior.

### Changed
- Expanded DTBook parsing support to include `doctitle`, `hd`, and paragraph-like text nodes such as `sent`, `li`, `dd`, and `note` while preserving deterministic ordering.
- Limited DTBook-only fallback recovery to lenient mode when no readable text is produced from OPF-driven parsing.
- Made heading normalization deterministic by using a fixed locale for text deduplication.
- Lowered `swift-tools-version` to `6.1` to match current GitHub Actions runner toolchains.
- Updated CI iOS simulator test command to remove unsupported `xcodebuild -packagePath` usage.
- Updated CI iOS simulator test job to auto-detect the available DaisyKit scheme across Xcode versions by probing known scheme names.
- Updated CI iOS simulator test job to resolve a concrete simulator device ID dynamically (and create one when needed) instead of relying on a fixed simulator name.
- Updated GitHub Actions to Node 24-ready major versions (`actions/checkout@v6` and `actions/upload-artifact@v6`).
- Updated docs to reflect Swift tools minimum version `6.1+`.

## [0.9.0] - 2026-03-23

### Added
- Initial public docs baseline.
- `README.md` with requirements, installation, quick start, API overview, Xcode integration, and troubleshooting.
- `LICENSE` (MIT), `CONTRIBUTING.md`, and this changelog scaffold.

### Changed
- Swift package layout now uses repository root (`Package.swift`, `Sources/`, and `Tests/`) for direct GitHub SwiftPM consumption.
- CI and contributor commands now run `swift test` from repository root.
- Installation docs now reference `https://github.com/dadederk/DaisyKit.git` with `from: "0.9.0"`.
