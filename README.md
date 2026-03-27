# DaisyKit

<p align="center">
  <img src="Images/Logo.png" alt="DaisyKit logo" width="420">
</p>

[![Swift](https://img.shields.io/badge/swift-6.1%2B-F05138.svg)](https://swift.org)
![Platforms](https://img.shields.io/badge/platform-iOS%2017%2B%20%7C%20macOS%2014%2B-0A84FF.svg)
[![CI](https://github.com/dadederk/DaisyKit/actions/workflows/daisykit-tests.yml/badge.svg)](https://github.com/dadederk/DaisyKit/actions/workflows/daisykit-tests.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Text-first DAISY 3 parser for Swift packages and Apple-platform apps.

DaisyKit parses DAISY 3 publications from a directory or `.zip` and returns:
- Raw publication structures (OPF, NCX, DTBook, optional SMIL refs).
- A normalized reading model for app consumption (sections, headings, paragraphs, anchors).
- A text-focused, line + heading model for reader/transcript style experiences.
- Typed diagnostics with strict and lenient parse modes.

v1 scope is text-first parsing only. Playback/timeline audio engine behavior is intentionally out of scope.

## Requirements

| Item | Requirement |
| --- | --- |
| Swift tools | 6.1+ |
| iOS | 17+ |
| macOS | 14+ |
| Dependency | [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) (transitive via SwiftPM) |

## Installation

Add DaisyKit to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/dadederk/DaisyKit.git", from: "0.10.0")
]
```

Then add the product to your target:

```swift
target(
    name: "YourApp",
    dependencies: [
        .product(name: "DaisyKit", package: "DaisyKit")
    ]
)
```

## Quick Start

```swift
import Foundation
import DaisyKit

func parseBook(at inputURL: URL) async {
    do {
        // Default mode is lenient.
        let report = try await parsePublication(at: inputURL)

        print("Title:", report.publication.title)
        print("Sections:", report.publication.sections.count)

        // Inspect diagnostics in lenient mode.
        for diagnostic in report.diagnostics {
            print("[\(diagnostic.severity.rawValue)] \(diagnostic.code): \(diagnostic.message)")
        }
    } catch let parseError as DaisyParseError {
        // Strict mode and structural failures surface typed parse errors.
        print("Parse failed:", parseError.diagnostic.code, parseError.diagnostic.message)
    } catch {
        print("Unexpected error:", error)
    }
}
```

Strict mode example:

```swift
func parseBookStrict(at inputURL: URL) async throws -> DaisyParseReport {
    let options = DaisyParseOptions(mode: .strict)
    return try await parsePublication(at: inputURL, options: options)
}
```

Text-focused extraction example:

```swift
func parseReadableText(at inputURL: URL) async throws -> DaisyTextParseReport {
    // In lenient mode, this can recover DTBook-only packages that do not include OPF metadata.
    try await parseTextPublication(at: inputURL, options: .init(mode: .lenient))
}
```

## API Overview

- `parsePublication(at:options:) async throws -> DaisyParseReport`
- `parseTextPublication(at:options:) async throws -> DaisyTextParseReport`
- `DaisyParseMode`: `.strict` or `.lenient`
- `DaisyParseOptions`: parser options container (`mode`)
- `DaisyParseReport`: output wrapper containing `raw`, `publication`, and `diagnostics`
- `DaisyTextParseReport`: output wrapper containing `publication` (`DaisyTextPublication`) and `diagnostics`
- `DaisyParseError`: typed thrown error with a `diagnostic`

## Apps Using DaisyKit

- [Xarra!](https://accessibilityupto11.com/apps/xarra/) ([App Store](https://apps.apple.com/app/id6759402266)) - accessibility-focused text-to-audio reading app.
- Let us know if you'd like your app to be listed here.

## Architecture

For a diagram-first view of the parser pipeline, package components, and model relationships, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Xcode Integration

1. In Xcode, open your project and select `File > Add Package Dependencies...`
2. Enter the DaisyKit repository URL.
3. Choose a version rule and add the `DaisyKit` library product to your target.

## Troubleshooting

- Input URL fails immediately: ensure the URL points to a readable DAISY publication directory or `.zip`.
- Strict mode throws: catch `DaisyParseError` and inspect `diagnostic.code` and `diagnostic.message`.
- Lenient mode seems incomplete: check `report.diagnostics` for recoverable issues and unresolved references.
- Zip and directory outputs differ: they should be equivalent for the same content, so verify source files match exactly.
- Import problems in Xcode: confirm your target links the `DaisyKit` product and uses a compatible iOS/macOS deployment target.

## Development

- Run tests:

```bash
swift test
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history and breaking-change notes.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for local setup and PR guidelines.

## License

MIT. See [LICENSE](LICENSE).
