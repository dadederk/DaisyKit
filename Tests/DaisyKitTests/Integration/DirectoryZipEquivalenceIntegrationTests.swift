import Foundation
import Testing
@testable import DaisyKit

@Suite("Directory Zip Equivalence Integration")
struct DirectoryZipEquivalenceIntegrationTests {
    @Test("Given real fixture directories and zips when parsing lenient then outputs are equivalent")
    func test_givenRealFixtureDirectoriesAndZips_whenParsingLenient_thenOutputsAreEquivalent() async throws {
        let descriptors = try FixtureManifestLoader.load().filter(\.isReal)
        #expect(!descriptors.isEmpty)

        for descriptor in descriptors {
            let directoryURL = try TestFixtureBuilder.makeWorkingCopyOfRealFixture(id: descriptor.id)
            let zipURL = try TestFixtureBuilder.makeZip(from: directoryURL)
            defer {
                TestFixtureBuilder.removeIfPresent(directoryURL)
                TestFixtureBuilder.removeIfPresent(zipURL)
            }

            let directoryReport = try await parsePublication(at: directoryURL, options: .init(mode: .lenient))
            let zipReport = try await parsePublication(at: zipURL, options: .init(mode: .lenient))

            #expect(directoryReport.publication == zipReport.publication)
            #expect(directoryReport.raw == zipReport.raw)
            #expect(directoryReport.diagnostics == zipReport.diagnostics)
        }
    }

    @Test("Given valid fixture when parsing then normalized ordering remains stable")
    func test_givenValidFixture_whenParsing_thenNormalizedOrderingRemainsStable() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .valid)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))

        #expect(report.publication.sections.count == 1)
        #expect(report.publication.sections[0].headings.map(\.text) == ["Chapter 1", "Section 1"])
        #expect(report.publication.sections[0].paragraphs.map(\.id) == ["p1", "p2"])
        #expect(report.raw.smilRefs.map(\.resolvedTextTarget) == ["chapter1.xml#p1", "chapter1.xml#p2"])
    }

    @Test("Given known structural OPF failure when parsing strict and lenient then strict code appears in lenient diagnostics")
    func test_givenKnownStructuralOPFFailure_whenParsingStrictAndLenient_thenStrictCodeAppearsInLenientDiagnostics() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .opfInvalidSpineIDRef)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        var strictErrorCode: String?
        do {
            _ = try await parsePublication(at: fixtureURL, options: .init(mode: .strict))
            Issue.record("Expected strict parse to throw.")
        } catch let parseError as DaisyParseError {
            strictErrorCode = parseError.diagnostic.code
        }

        let lenientReport = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        let code = try #require(strictErrorCode)
        #expect(lenientReport.diagnostics.contains(where: { $0.code == code }))
    }
}
