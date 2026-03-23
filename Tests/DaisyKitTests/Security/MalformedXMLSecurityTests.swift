import Foundation
import Testing
@testable import DaisyKit

@Suite("Malformed XML Security")
struct MalformedXMLSecurityTests {
    @Test("Given malformed NCX when parsing strict then parser fails fast with NCX parse diagnostic")
    func test_givenMalformedNCX_whenParsingStrict_thenParserFailsFastWithNCXParseDiagnostic() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .malformedNCX)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        do {
            _ = try await parsePublication(at: fixtureURL, options: .init(mode: .strict))
            Issue.record("Expected strict parsing to throw for malformed NCX.")
        } catch let parseError as DaisyParseError {
            #expect(parseError.diagnostic.code == "ncx.xml-parse-failed")
            #expect(parseError.diagnostic.severity == .error)
        }
    }

    @Test("Given malformed NCX when parsing lenient then parser accumulates NCX parse diagnostic")
    func test_givenMalformedNCX_whenParsingLenient_thenParserAccumulatesNCXParseDiagnostic() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .malformedNCX)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        #expect(report.diagnostics.contains(where: { $0.code == "ncx.xml-parse-failed" && $0.severity == .error }))
        #expect(report.publication.sections.count == 1)
    }

    @Test("Given OPF href outside workspace when parsing lenient then outside workspace diagnostic is emitted")
    func test_givenOPFHrefOutsideWorkspace_whenParsingLenient_thenOutsideWorkspaceDiagnosticIsEmitted() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .opfHrefOutsideWorkspace)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        #expect(report.diagnostics.contains(where: { $0.code == "opf.manifest-path-outside-workspace" }))
    }

    @Test("Given SMIL target outside workspace when parsing lenient then outside workspace diagnostic is emitted")
    func test_givenSMILTargetOutsideWorkspace_whenParsingLenient_thenOutsideWorkspaceDiagnosticIsEmitted() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .smilOutsideWorkspaceTarget)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        #expect(report.diagnostics.contains(where: { $0.code == "smil.text-source-outside-workspace" && $0.severity == .warning }))
    }
}
