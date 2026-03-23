import Foundation
import Testing
@testable import DaisyKit

@Suite("OPF Parser Unit")
struct OPFParserUnitTests {
    @Test("Given missing manifest when parsing lenient then opf manifest missing diagnostic is returned")
    func test_givenMissingManifest_whenParsingLenient_thenManifestMissingDiagnosticIsReturned() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .opfMissingManifest)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        #expect(report.diagnostics.contains { $0.code == "opf.manifest-missing" && $0.severity == .error })
    }

    @Test("Given missing spine when parsing lenient then opf spine missing diagnostic is returned")
    func test_givenMissingSpine_whenParsingLenient_thenSpineMissingDiagnosticIsReturned() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .opfMissingSpine)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        #expect(report.diagnostics.contains { $0.code == "opf.spine-missing" && $0.severity == .error })
    }

    @Test("Given invalid manifest item when parsing lenient then opf invalid manifest item diagnostic is returned")
    func test_givenInvalidManifestItem_whenParsingLenient_thenInvalidManifestItemDiagnosticIsReturned() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .opfInvalidManifestItem)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        #expect(report.diagnostics.contains { $0.code == "opf.invalid-manifest-item" })
    }

    @Test("Given invalid spine idref when parsing strict then parser throws missing spine manifest reference")
    func test_givenInvalidSpineIDRef_whenParsingStrict_thenParserThrowsMissingSpineManifestReference() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .opfInvalidSpineIDRef)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        do {
            _ = try await parsePublication(at: fixtureURL, options: .init(mode: .strict))
            Issue.record("Expected strict parsing to throw.")
        } catch let parseError as DaisyParseError {
            #expect(parseError.diagnostic.code == "opf.missing-spine-manifest-reference")
            #expect(parseError.diagnostic.elementID == "missing-id")
        }
    }

    @Test("Given unique identifier mismatch when parsing then fallback identifier is used")
    func test_givenUniqueIdentifierMismatch_whenParsing_thenFallbackIdentifierIsUsed() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .opfUniqueIdentifierMismatch)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        #expect(report.raw.metadata.identifier == "fixture-id")
    }

    @Test("Given manifest href outside workspace when parsing lenient then out of workspace diagnostic is returned")
    func test_givenManifestHrefOutsideWorkspace_whenParsingLenient_thenOutOfWorkspaceDiagnosticIsReturned() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .opfHrefOutsideWorkspace)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        #expect(report.diagnostics.contains { $0.code == "opf.manifest-path-outside-workspace" })
    }
}
