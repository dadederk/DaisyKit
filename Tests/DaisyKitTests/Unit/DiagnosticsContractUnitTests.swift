import Foundation
import Testing
@testable import DaisyKit

@Suite("Diagnostics Contract Unit")
struct DiagnosticsContractUnitTests {
    private let allowedFamilies: Set<String> = ["resolver", "io", "opf", "ncx", "dtbook", "smil", "normalize"]

    @Test("Given representative error fixtures when parsing lenient then diagnostic families stay in contract")
    func test_givenRepresentativeErrorFixtures_whenParsingLenient_thenDiagnosticFamiliesStayInContract() async throws {
        let mockAsserter = MockDiagnosticFamilyAsserter(allowedFamilies: allowedFamilies)
        let variants: [DaisyFixtureVariant] = [
            .opfMissingManifest,
            .opfMissingSpine,
            .opfInvalidManifestItem,
            .opfInvalidSpineIDRef,
            .opfHrefOutsideWorkspace,
            .ncxMissingNavMap,
            .ncxMissingLabelAndSource,
            .malformedNCX,
            .smilMissingTextSrc,
            .smilOutsideWorkspaceTarget,
            .unresolvedSmilTarget,
            .smilFileMissingReferencedByOPF,
        ]

        for variant in variants {
            let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: variant)
            defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

            let report = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
            mockAsserter.assertFamilies(for: report.diagnostics)
        }

        #expect(mockAsserter.assertionCount == variants.count)
    }

    @Test("Given strict mode and structural OPF error when parsing then strict fails fast and lenient accumulates")
    func test_givenStrictModeAndStructuralOPFError_whenParsing_thenStrictFailsFastAndLenientAccumulates() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .opfMissingManifest)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        do {
            _ = try await parsePublication(at: fixtureURL, options: .init(mode: .strict))
            Issue.record("Expected strict parse to throw for structural OPF error.")
        } catch let parseError as DaisyParseError {
            #expect(parseError.diagnostic.code == "opf.manifest-missing")
            #expect(parseError.diagnostic.severity == .error)
        }

        let lenientReport = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        #expect(lenientReport.diagnostics.contains(where: { $0.code == "opf.manifest-missing" && $0.severity == .error }))
    }

    @Test("Given known warning and error fixtures when parsing lenient then diagnostic severities match contract")
    func test_givenKnownWarningAndErrorFixtures_whenParsingLenient_thenDiagnosticSeveritiesMatchContract() async throws {
        let warningFixture = try TestFixtureBuilder.makePublicationDirectory(variant: .ncxMissingNavMap)
        let errorFixture = try TestFixtureBuilder.makePublicationDirectory(variant: .opfInvalidManifestItem)
        defer {
            TestFixtureBuilder.removeIfPresent(warningFixture)
            TestFixtureBuilder.removeIfPresent(errorFixture)
        }

        let warningReport = try await parsePublication(at: warningFixture, options: .init(mode: .lenient))
        let errorReport = try await parsePublication(at: errorFixture, options: .init(mode: .lenient))

        #expect(warningReport.diagnostics.contains(where: { $0.code == "ncx.navmap-missing" && $0.severity == .warning }))
        #expect(errorReport.diagnostics.contains(where: { $0.code == "opf.invalid-manifest-item" && $0.severity == .error }))
    }

    @Test("Given unsupported input file when parsing then resolver error family is emitted")
    func test_givenUnsupportedInputFile_whenParsing_thenResolverErrorFamilyIsEmitted() async throws {
        let plainText = try TestFixtureBuilder.makePlainTextInputFile()
        defer { TestFixtureBuilder.removeIfPresent(plainText) }

        do {
            _ = try await parsePublication(at: plainText, options: .init(mode: .lenient))
            Issue.record("Expected unsupported input to throw.")
        } catch let parseError as DaisyParseError {
            #expect(parseError.diagnostic.code == "resolver.unsupported-input")
            #expect(parseError.diagnostic.severity == .error)
            #expect(parseError.diagnostic.code.hasPrefix("resolver."))
        }
    }
}
