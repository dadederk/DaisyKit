import Foundation
import Testing
@testable import DaisyKit

@Suite("Parse Performance", .serialized)
struct ParsePerformanceTests {
    private let largeFixtureBaselineSeconds: TimeInterval = 12.0
    private let mediumFixtureBaselineSeconds: TimeInterval = 3.0
    private let regressionMultiplierLimit: Double = 4.0
    private let coarsePeakMemoryUpperBoundBytes: UInt64 = 512 * 1_024 * 1_024

    @Test("Given large synthetic fixture when parsing then runtime and memory stay within coarse baseline bounds")
    func test_givenLargeSyntheticFixture_whenParsing_thenRuntimeAndMemoryStayWithinCoarseBaselineBounds() async throws {
        let fixtureURL = try TestFixtureBuilder.makeLargePublicationDirectory(paragraphCount: 5_000)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        // Warm-up to reduce first-run noise in deterministic gates.
        _ = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))

        let memoryTracker = FakePeakMemoryTracker()
        memoryTracker.captureCurrentUsage()

        let duration = try await PerformanceMetrics.measure {
            _ = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        }

        memoryTracker.captureCurrentUsage()

        #expect(duration <= largeFixtureBaselineSeconds)
        #expect(memoryTracker.peakBytes <= coarsePeakMemoryUpperBoundBytes)
    }

    @Test("Given medium curated fixture when parsing then runtime remains under medium baseline")
    func test_givenMediumCuratedFixture_whenParsing_thenRuntimeRemainsUnderMediumBaseline() async throws {
        let fixtureURL = try TestFixtureBuilder.makeWorkingCopyOfRealFixture(id: "real_minimal_valid")
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        // Warm-up parse.
        _ = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))

        let duration = try await PerformanceMetrics.measure {
            _ = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        }

        #expect(duration <= mediumFixtureBaselineSeconds)
    }

    @Test("Given repeated parses when measuring drift then no catastrophic runtime regression appears")
    func test_givenRepeatedParses_whenMeasuringDrift_thenNoCatastrophicRuntimeRegressionAppears() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .valid)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        // Warm-up parse.
        _ = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))

        let recorder = SpyParseRunRecorder()
        let baseline = try await PerformanceMetrics.measure {
            _ = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
        }

        for _ in 0..<5 {
            let duration = try await PerformanceMetrics.measure {
                _ = try await parsePublication(at: fixtureURL, options: .init(mode: .lenient))
            }
            recorder.record(duration)
        }

        let allowedUpperBound = max(mediumFixtureBaselineSeconds, baseline * regressionMultiplierLimit)
        for duration in recorder.runDurations {
            #expect(duration <= allowedUpperBound)
        }
        #expect(recorder.runDurations.count == 5)
    }
}
