import Foundation
import Testing
@testable import DaisyKit

@Suite("SMIL Parser Unit")
struct SMILParserUnitTests {
    @Test("Given smil text without src when parsing lenient then smil missing text source warning is returned")
    func test_givenSMILTextWithoutSource_whenParsingLenient_thenMissingTextSourceWarningIsReturned() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .smilMissingTextSrc)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL)
        #expect(report.diagnostics.contains { $0.code == "smil.missing-text-source" })
    }

    @Test("Given smil text pointing outside workspace when parsing lenient then outside workspace warning is returned")
    func test_givenSMILTextOutsideWorkspace_whenParsingLenient_thenOutsideWorkspaceWarningIsReturned() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .smilOutsideWorkspaceTarget)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL)
        #expect(report.diagnostics.contains { $0.code == "smil.text-source-outside-workspace" })
    }

    @Test("Given unresolved smil target when parsing lenient then unresolved smil warning is returned")
    func test_givenUnresolvedSMILTarget_whenParsingLenient_thenUnresolvedSMILWarningIsReturned() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .unresolvedSmilTarget)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL)
        #expect(report.diagnostics.contains { $0.code == "smil.unresolved-text-target" })
    }

    @Test("Given smil file missing but referenced by opf when parsing lenient then smil file missing warning is returned")
    func test_givenSMILFileMissingButReferencedByOPF_whenParsingLenient_thenSMILFileMissingWarningIsReturned() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .smilFileMissingReferencedByOPF)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL)
        #expect(report.diagnostics.contains { $0.code == "smil.file-missing" })
    }
}
