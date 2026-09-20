# Contributing

Thanks for your interest in improving DaisyKit.

## Local Setup

1. Clone the repository.
2. Open a terminal in the repository root.
3. Run package tests:

```bash
swift test
```

## Development Guidelines

- Keep parser behavior deterministic (stable ordering and diagnostics).
- Preserve typed diagnostics behavior for strict and lenient parse modes.
- Keep the package text-first (no playback/timeline engine behavior).
- Keep workspace resolution, format parsers, normalization, and diagnostics separate. Preserve source identifiers, reading order, and mixed-language text.
- Prefer small, pure parsing helpers and async/await for new asynchronous work. Avoid sleeps or timers to sequence parsing.
- Use the existing `DaisyLogger`/OSLog categories and feature markers for package logging, not `print()`.
- Avoid adding third-party dependencies without explicit approval.
- Do not add network-dependent tests.

## Tests and Fixtures

- Cover OPF, NCX, DTBook, and SMIL references, plus directory/zip equivalence, malformed inputs, strict/lenient diagnostics, and deterministic normalized output.
- Keep fixtures checked in, small, and synthetic or public-domain. Avoid large binary audio assets.
- Prefer Given/When/Then scenario names. Name test doubles by their role (`Dummy`, `Stub`, `Fake`, `Spy`, or `Mock`) rather than a generic `Test` prefix.

## Pull Requests

1. Create focused changes with clear commit messages.
2. Add or update tests for behavior changes.
3. Update documentation when parser behavior or scope changes.
4. Ensure `swift test` passes before opening the PR.

## Reporting Issues

When filing a bug, include:
- Input type (directory or `.zip`)
- Parse mode (`strict` or `lenient`)
- Diagnostic codes/messages or thrown error details
- A minimal reproducible fixture when possible
