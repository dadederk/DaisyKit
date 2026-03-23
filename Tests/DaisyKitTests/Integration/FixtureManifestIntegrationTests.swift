import Foundation
import Testing
@testable import DaisyKit

@Suite("Fixture Manifest Integration")
struct FixtureManifestIntegrationTests {
    @Test("Given fixture manifest descriptors when parsing then strict and lenient behavior matches expectations")
    func test_givenFixtureManifestDescriptors_whenParsing_thenStrictAndLenientBehaviorMatchesExpectations() async throws {
        let manifest = try FixtureManifestLoader.load()
        #expect(!manifest.isEmpty)

        for descriptor in manifest {
            let fixtureURL: URL
            if descriptor.isReal {
                fixtureURL = try TestFixtureBuilder.makeWorkingCopyOfRealFixture(id: descriptor.id)
            } else {
                let variant = try #require(descriptor.syntheticVariant)
                fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: variant)
            }
            defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

            let lenientReport = try await parseAndAssertExpectation(
                descriptor.expectedLenient,
                at: fixtureURL,
                mode: .lenient,
                descriptorID: descriptor.id
            )

            _ = try await parseAndAssertExpectation(
                descriptor.expectedStrict,
                at: fixtureURL,
                mode: .strict,
                descriptorID: descriptor.id
            )

            if let lenientReport {
                let families = Set(lenientReport.diagnostics.map(Self.family(for:)))
                for expectedFamily in descriptor.expectedDiagnosticFamilies {
                    #expect(families.contains(expectedFamily))
                }
            }
        }
    }

    private func parseAndAssertExpectation(
        _ expectation: FixtureParseExpectation,
        at fixtureURL: URL,
        mode: DaisyParseMode,
        descriptorID: String
    ) async throws -> DaisyParseReport? {
        switch expectation {
        case .success:
            return try await parsePublication(at: fixtureURL, options: .init(mode: mode))

        case .throwsError:
            do {
                _ = try await parsePublication(at: fixtureURL, options: .init(mode: mode))
                Issue.record("Expected fixture \(descriptorID) to throw in mode \(String(describing: mode)).")
                return nil
            } catch is DaisyParseError {
                return nil
            }
        }
    }

    private static func family(for diagnostic: DaisyDiagnostic) -> String {
        diagnostic.code.split(separator: ".").first.map(String.init) ?? ""
    }
}
