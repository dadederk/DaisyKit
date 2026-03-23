import Foundation
import Testing
@testable import DaisyKit

@Suite("NCX Parser Unit")
struct NCXParserUnitTests {
    @Test("Given missing navMap when parsing lenient then ncx navmap missing warning is returned")
    func test_givenMissingNavMap_whenParsingLenient_thenNavMapMissingWarningIsReturned() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .ncxMissingNavMap)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        #expect(report.diagnostics.contains { $0.code == "ncx.navmap-missing" && $0.severity == .warning })
    }

    @Test("Given navPoint missing label and source when parsing lenient then warning diagnostics are returned")
    func test_givenNavPointMissingLabelAndSource_whenParsingLenient_thenWarningDiagnosticsAreReturned() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .ncxMissingLabelAndSource)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        #expect(report.diagnostics.contains { $0.code == "ncx.missing-label" })
        #expect(report.diagnostics.contains { $0.code == "ncx.missing-content-source" })
    }

    @Test("Given nested nav points when parsing then hierarchy depth is preserved")
    func test_givenNestedNavPoints_whenParsing_thenHierarchyDepthIsPreserved() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .ncxNestedDepth)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        #expect(report.raw.navPoints.count == 1)
        #expect(report.raw.navPoints[0].children.count == 1)
        #expect(report.raw.navPoints[0].children[0].children.count == 1)
    }

    @Test("Given malformed ncx when parsing strict then parser throws ncx parse error")
    func test_givenMalformedNCX_whenParsingStrict_thenParserThrowsNCXParseError() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .malformedNCX)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        do {
            _ = try await parsePublication(at: fixtureURL, options: .init(mode: .strict))
            Issue.record("Expected strict parsing to throw.")
        } catch let parseError as DaisyParseError {
            #expect(parseError.diagnostic.code == "ncx.xml-parse-failed")
        }
    }
}
