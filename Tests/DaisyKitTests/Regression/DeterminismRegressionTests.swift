import Foundation
import Testing
@testable import DaisyKit

@Suite("Determinism Regression", .serialized)
struct DeterminismRegressionTests {
    @Test("Given identical directory input when parsing repeatedly then reports remain byte-equivalent")
    func test_givenIdenticalDirectoryInput_whenParsingRepeatedly_thenReportsRemainByteEquivalent() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .valid)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let reports = try await parseRepeatedly(at: fixtureURL, iterations: 5)
        let first = try #require(reports.first)

        for report in reports.dropFirst() {
            #expect(report.publication == first.publication)
            #expect(report.raw == first.raw)
            #expect(report.diagnostics == first.diagnostics)
        }
    }

    @Test("Given identical zip input when parsing repeatedly then diagnostic ordering stays stable")
    func test_givenIdenticalZipInput_whenParsingRepeatedly_thenDiagnosticOrderingStaysStable() async throws {
        let fixtureDirectory = try TestFixtureBuilder.makePublicationDirectory(variant: .unresolvedSmilTarget)
        let fixtureZip = try TestFixtureBuilder.makeZip(from: fixtureDirectory)
        defer {
            TestFixtureBuilder.removeIfPresent(fixtureDirectory)
            TestFixtureBuilder.removeIfPresent(fixtureZip)
        }

        let reports = try await parseRepeatedly(at: fixtureZip, iterations: 5)
        let baselineCodes = reports.first?.diagnostics.map(\.code) ?? []

        for report in reports.dropFirst() {
            #expect(report.diagnostics.map(\.code) == baselineCodes)
        }
    }

    private func parseRepeatedly(at url: URL, iterations: Int) async throws -> [DaisyParseReport] {
        var reports: [DaisyParseReport] = []
        reports.reserveCapacity(iterations)

        for _ in 0..<iterations {
            let report = try await parsePublication(at: url, options: .init(mode: .lenient))
            reports.append(report)
        }

        return reports
    }
}
