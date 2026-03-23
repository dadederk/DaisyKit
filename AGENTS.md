# AGENTS.md

AI agent development guidelines for DaisyKit.

DaisyKit is a Swift Package that parses DAISY 3 publications (ANSI/NISO Z39.86-2005) into:
1. Raw publication structures (OPF, NCX, DTBook, optional SMIL refs).
2. A normalized, app-friendly reading model (text, headings, anchors, navigation).

## Quick Start

**Role**: Senior Swift engineer focused on robust DAISY parsing and clean package APIs  
**Target**: Swift 6.1+, Swift Package Manager, Apple platforms  
**Current Scope**: Text-first v1 (no playback/timeline engine)

### Critical Rules

1. **ALWAYS** read relevant planning/spec files before implementing:
- `Daisy3Kit-SPM-Plan.md`
- `Specs/SG-DAISY3/` (as needed for parser behavior)
2. **ALWAYS** ensure the package compiles and tests pass after changes:
- `swift test`
3. **ALWAYS** keep parser behavior deterministic:
- stable ordering for emitted sections/headings/anchors
- deterministic diagnostics
4. **ALWAYS** use typed errors/diagnostics for parser outcomes:
- strict mode fails structural invalidity
- lenient mode collects recoverable warnings
5. **ALWAYS** keep the library language-agnostic:
- preserve source text content
- do not filter by language-specific keywords
6. **NEVER** rely on external network calls in tests.
7. **NEVER** add DAISY playback/timing behavior to v1 core parser scope.
8. **NEVER** shift app responsibilities into the package:
- security-scoped URL access remains caller responsibility
- app-layer mapping belongs outside DaisyKit
9. **ALWAYS** update planning/docs when behavior or scope changes.
10. **NEVER** add third-party dependencies without explicit approval.

## Project Overview

DaisyKit is a standalone parser package designed to be embedded in apps. It should expose a small, stable public API and predictable models that are easy to adapt into app-specific persistence/view models.

### Canonical Inputs

- Directory URL containing DAISY 3 content.
- `.zip` URL containing DAISY 3 content.

### Canonical Outputs

- Raw parse model surface for fidelity and debugging.
- Normalized reading model optimized for app consumption.
- Typed diagnostics for invalid, incomplete, or unsupported structures.

## Architecture Principles

1. **Pipeline over monolith**
- Resolver -> OPF -> NCX -> DTBook -> SMIL refs -> Normalizer -> Diagnostics
2. **Single responsibility**
- Each parser handles one format and owns only its extraction logic
3. **Pure transformations where possible**
- Prefer side-effect free parsing and normalization functions
4. **Strict boundaries**
- Keep file I/O, parsing, normalization, and diagnostics separated
5. **Stable API evolution**
- Additive changes by default; avoid breaking model/property names without clear migration intent
6. **Modern concurrency first**
- Prefer async/await over callback-based APIs for new code
- Avoid legacy GCD patterns unless there is no modern alternative

## Suggested Package Layout

Use this as the default organization pattern as the package grows:

```
DaisyKit/
├── Package.swift
├── Sources/
│   └── DaisyKit/
│       ├── API/                 # Public entrypoints and top-level types
│       ├── Resolver/            # Directory/zip workspace resolution
│       ├── Parsers/
│       │   ├── OPF/
│       │   ├── NCX/
│       │   ├── DTBook/
│       │   └── SMIL/
│       ├── Normalize/           # Raw -> normalized models
│       ├── Models/
│       │   ├── Raw/
│       │   ├── Normalized/
│       │   └── Diagnostics/
│       └── Support/             # Shared utilities
└── Tests/
    └── DaisyKitTests/
        ├── Unit/
        ├── Integration/
        ├── Regression/
        └── Fixtures/
```

## Public API Guidelines

- Prefer one clear entrypoint (for example `parsePublication(at:mode:)`).
- Keep input URL-based and explicit.
- Separate parse mode and options in typed config.
- Return rich result types instead of ad-hoc tuples.
- Favor immutable models (`let`) unless mutation is required.

## Parsing Guidelines

### OPF

- Extract metadata, manifest, spine, unique identifier.
- Validate manifest/spine references.
- Preserve source identifiers and href relationships.

### NCX

- Parse hierarchical nav map and labels.
- Preserve play order semantics when present.
- Resolve and normalize content targets/anchors.

### DTBook

- Preserve structural hierarchy and reading order.
- Extract text content without language-specific filtering.
- Support Unicode and mixed-language content robustly.

### SMIL (Reference-Level in v1)

- Parse link relationships and anchors.
- Expose references for consumers.
- Do not implement timing/playback engine behavior in v1.

## Error Handling and Diagnostics

- Use typed diagnostics with severity (`error`, `warning`, optionally `info`).
- Include machine-usable context (file, element/id, reason).
- Keep messages concise and actionable.
- In strict mode, fail fast for structural invalidity.
- In lenient mode, continue when safe and report recoverable issues.

## Logging

- Use `OSLog` (`Logger`) for package logs; do not use `print()`.
- Choose log level by impact:
- `debug`: parser step details helpful during development.
- `info`: high-level lifecycle events (start/end parse, selected mode).
- `notice`: notable but expected fallbacks/recoveries.
- `warning`: recoverable issues that may affect output quality.
- `error`: failures that stop an operation.
- `fault`: invariant violations or serious unexpected corruption.
- Prefix log messages with feature emoji markers for fast scanning:
- `📦` resolver / package loading
- `📘` OPF
- `🧭` NCX
- `📝` DTBook
- `🎼` SMIL refs
- `🧱` normalization
- `⚠️` diagnostics summary
- If a message spans multiple features, include multiple emojis in a stable order (pipeline order) and keep it concise (prefer 1-3 emojis max).

## Testing Requirements

### Baseline Commands

```bash
swift test
```

### Required Test Coverage

1. Unit tests per parser (OPF/NCX/DTBook/SMIL refs).
2. Integration tests for directory and zip end-to-end parsing.
3. Strict vs lenient behavior tests.
4. Regression tests for malformed XML and edge structures.
5. Snapshot or equivalent deterministic assertions for normalized output.

### Test Structure (Given/When/Then)

- Write tests as clear scenarios with explicit setup, action, and expected result.
- Prefer naming or comments that express `Given / When / Then`.
- Example naming style: `test_givenMalformedNCX_whenStrictMode_thenThrowsInvalidStructure`.

### Test Double Vocabulary and Naming

- `Test Double` is the umbrella term for all substitute collaborators in tests.
- `Dummy`: placeholder value passed to satisfy a signature but never used.
- `Stub`: returns preconfigured values, no assertions about interactions.
- `Fake`: lightweight working implementation (often in-memory).
- `Spy`: records calls/inputs for later assertions.
- `Mock`: has expectations and can fail the test when interactions differ.
- Name doubles by exact behavior (`DummyURLProvider`, `StubManifestLoader`, `SpyDiagnosticsSink`, `MockResolver`) instead of generic names like `TestService`.

### Fixture Strategy

- Keep fixtures checked in.
- Prefer public-domain or synthetic text-first fixtures.
- Avoid large binary audio assets in v1.
- Keep fixtures minimal, purpose-specific, and documented.

## Performance and Reliability

- Avoid loading unnecessary large files into memory when streaming is enough.
- Avoid artificial timing logic (`sleep`, timers) to sequence parser behavior.
- Ensure repeated parse runs on same input produce equivalent outputs.
- Keep utility helpers small and composable.

## Code Style and Maintainability

- Code should read as a succession of instructions at the top level.
- Prefer short, single-purpose functions with names that state intent and outcome.
- Use clear names by intent and outcome (`resolvePackageLayout`, `buildNormalizedSections`).
- Keep top-level methods short and readable.
- Split large files early; avoid single-file parser blobs.
- Comment why, not what.
- Avoid force unwraps unless truly unrecoverable and justified.

## What To Avoid

1. `print()` in package code paths.
2. Hidden global mutable state in parsing logic.
3. Silent data drops without diagnostics.
4. Keyword-based text filtering.
5. Network-dependent tests.
6. Parsing and normalization tightly coupled in one giant function.
7. Breaking public API names casually.
8. Ambiguous test-double naming (`TestFoo`) when `Stub`/`Fake`/`Spy`/`Mock` is clear.

## Documentation Maintenance

After any meaningful parser/API behavior change:
1. Update `Daisy3Kit-SPM-Plan.md` if scope or milestones changed.
2. Document parser decisions and edge cases in repo docs.
3. Add or adjust fixtures/tests for the new behavior.

## File Reference

- Plan: `Daisy3Kit-SPM-Plan.md`
- DAISY 3 reference material: `Specs/SG-DAISY3/`
- Package manifest: `Package.swift`
- Library source root: `Sources/DaisyKit/`
- Tests: `Tests/DaisyKitTests/`

---

Version: 2.1  
Last Updated: 2026-03-21
