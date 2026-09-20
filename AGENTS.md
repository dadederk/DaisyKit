# Agent Guidance

DaisyKit is a Swift 6.1+ package that parses DAISY 3 publications into raw models, normalized reading models, and typed diagnostics. These instructions are for any coding agent; contributors do not need a personal skill installation.

## Start Here

1. Read `ARCHITECTURE.md` for the parsing pipeline and `CONTRIBUTING.md` for development rules. Use `README.md` for public API behavior and `Specs/SG-DAISY3/` when changing specification-governed parsing.
2. Inspect the nearest source and tests before changing behavior.
3. Run `swift test` after code changes. Update tests and public documentation when parser behavior, diagnostics, API shape, or scope changes.

## Boundaries

- Keep the package text-first. SMIL is reference-level only; playback and timeline synchronization belong to consuming apps.
- Accept local DAISY directories and `.zip` files without network access. Preserve source text and identifiers across languages; do not filter by language-specific keywords.
- Keep output and diagnostics deterministic. Strict mode fails structural invalidity; lenient mode reports recoverable issues without silently dropping content.
- Keep workspace resolution, format parsing, normalization, and diagnostics separate. Security-scoped URL access, persistence, reader UI, and user-facing recovery copy belong to consuming apps.
- Keep public APIs small and additive by default. Do not add third-party dependencies without explicit approval.

## Optional Skills

When available, consult `swift-api-design-guidelines-skill` for public API design, `swift-concurrency` for isolation or async work, and `swift-testing-expert` for Swift Testing. These personal/global aids are optional, not repository dependencies. The checked-in docs and tests remain authoritative for contributors without them.
