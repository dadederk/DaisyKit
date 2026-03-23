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
- Keep v1 scope text-first (no playback/timeline engine behavior).
- Avoid adding third-party dependencies without explicit approval.
- Do not add network-dependent tests.

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
