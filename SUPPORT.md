# Support

Use GitHub Issues for reproducible DaisyKit bugs, documentation problems, and focused feature requests.

## Before Filing

- Check the README, architecture doc, changelog, and contributing guide for current parser scope.
- Reduce the issue to the smallest DAISY directory or `.zip` fixture that reproduces it.
- Confirm whether the problem is parser output/diagnostics or consuming-app reader behavior.

## Include In Bug Reports

- Swift and Xcode version.
- Platform and deployment target.
- Input type: directory or `.zip`.
- Parse API used: `parsePublication` or `parseTextPublication`.
- Parse mode: `strict` or `lenient`.
- Diagnostic codes/messages or thrown error details.
- A minimal reproducible fixture when possible.

Questions about playback engines, timeline audio behavior, reader UI, library management, or Xarra-specific behavior belong with the consuming app unless DaisyKit's parsed output or diagnostics are wrong.
