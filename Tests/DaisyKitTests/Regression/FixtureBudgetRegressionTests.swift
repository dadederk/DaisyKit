import Foundation
import Testing

@Suite("Fixture Budget Regression")
struct FixtureBudgetRegressionTests {
    private let maxBudgetBytes: UInt64 = 25 * 1_024 * 1_024

    @Test("Given checked-in fixture corpus when measuring size then payload remains under twenty-five megabytes")
    func test_givenCheckedInFixtureCorpus_whenMeasuringSize_thenPayloadRemainsUnderTwentyFiveMegabytes() throws {
        let totalBytes = try FixtureManifestLoader.checkedInFixturesSizeInBytes()
        #expect(totalBytes <= maxBudgetBytes)
    }

    @Test("Given fixture manifest when validating entries then all descriptors have provenance and parse expectations")
    func test_givenFixtureManifest_whenValidatingEntries_thenAllDescriptorsHaveProvenanceAndParseExpectations() throws {
        let manifest = try FixtureManifestLoader.load()
        #expect(!manifest.isEmpty)

        for descriptor in manifest {
            #expect(!descriptor.id.isEmpty)
            #expect(!descriptor.provenance.isEmpty)
            if descriptor.isReal {
                #expect(descriptor.relativePath != nil)
            }
            if descriptor.isSynthetic {
                #expect(descriptor.syntheticVariant != nil)
            }
        }
    }
}
