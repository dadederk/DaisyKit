# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Lowered `swift-tools-version` to `6.1` to match current GitHub Actions runner toolchains.
- Updated CI iOS simulator test command to remove unsupported `xcodebuild -packagePath` usage.
- Updated CI iOS simulator test job to auto-detect the available DaisyKit scheme across Xcode versions.
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
