import Foundation

enum FixtureParseExpectation: String, Decodable {
    case success
    case throwsError = "throws"
}

struct FixtureDescriptor: Decodable, Sendable {
    let id: String
    let type: String
    let provenance: String
    let relativePath: String?
    let generator: String?
    let expectedStrict: FixtureParseExpectation
    let expectedLenient: FixtureParseExpectation
    let expectedDiagnosticFamilies: [String]

    var isReal: Bool { type == "real" }
    var isSynthetic: Bool { type == "synthetic" }

    var syntheticVariant: DaisyFixtureVariant? {
        guard let generator else { return nil }
        switch generator {
        case "opfMissingManifest":
            return .opfMissingManifest
        case "opfMissingSpine":
            return .opfMissingSpine
        case "opfInvalidManifestItem":
            return .opfInvalidManifestItem
        case "opfInvalidSpineIDRef":
            return .opfInvalidSpineIDRef
        case "opfUniqueIdentifierMismatch":
            return .opfUniqueIdentifierMismatch
        case "opfHrefOutsideWorkspace":
            return .opfHrefOutsideWorkspace
        case "ncxMissingNavMap":
            return .ncxMissingNavMap
        case "ncxMissingLabelAndSource":
            return .ncxMissingLabelAndSource
        case "ncxNestedDepth":
            return .ncxNestedDepth
        case "malformedNCX":
            return .malformedNCX
        case "dtbookHeadingLevels":
            return .dtbookHeadingLevels
        case "dtbookMixedLanguage":
            return .dtbookMixedLanguage
        case "dtbookWhitespaceParagraphs":
            return .dtbookWhitespaceParagraphs
        case "dtbookDuplicateIDs":
            return .dtbookDuplicateIDs
        case "smilMissingTextSrc":
            return .smilMissingTextSrc
        case "smilOutsideWorkspaceTarget":
            return .smilOutsideWorkspaceTarget
        case "unresolvedSmilTarget":
            return .unresolvedSmilTarget
        case "smilFileMissingReferencedByOPF":
            return .smilFileMissingReferencedByOPF
        default:
            return nil
        }
    }
}

enum FixtureManifestLoader {
    static func load() throws -> [FixtureDescriptor] {
        let data = try Data(contentsOf: manifestURL)
        return try JSONDecoder().decode([FixtureDescriptor].self, from: data)
    }

    static var manifestURL: URL {
        fixturesDirectoryURL.appendingPathComponent("fixtures.json")
    }

    static var fixturesDirectoryURL: URL {
        if let bundledFixturesURL = Bundle.module.resourceURL?
            .appendingPathComponent("Fixtures", isDirectory: true),
           FileManager.default.fileExists(atPath: bundledFixturesURL.path) {
            return bundledFixturesURL
        }
        return testsRootURL.appendingPathComponent("Fixtures", isDirectory: true)
    }

    static var realFixturesDirectoryURL: URL {
        fixturesDirectoryURL.appendingPathComponent("real", isDirectory: true)
    }

    static var testsRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Fixtures
            .deletingLastPathComponent() // Support
            .deletingLastPathComponent() // DaisyKitTests
    }

    static func realFixtureDirectory(for descriptor: FixtureDescriptor) -> URL {
        precondition(descriptor.isReal)
        let relativePath = descriptor.relativePath ?? ""
        return fixturesDirectoryURL.appendingPathComponent(relativePath, isDirectory: true)
    }

    static func checkedInFixturesSizeInBytes() throws -> UInt64 {
        let manager = FileManager.default
        guard let enumerator = manager.enumerator(
            at: fixturesDirectoryURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            if values.isRegularFile == true {
                total += UInt64(values.fileSize ?? 0)
            }
        }

        return total
    }
}
