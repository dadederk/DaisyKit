import Foundation
import Testing
@testable import DaisyKit

@Suite("Resolver Security")
struct ResolverSecurityTests {
    @Test("Given missing input URL when parsing then resolver input not found error is thrown")
    func test_givenMissingInputURL_whenParsing_thenResolverInputNotFoundErrorIsThrown() async throws {
        let missingURL = TestFixtureBuilder.makeMissingInputURL()

        do {
            _ = try await parsePublication(at: missingURL, options: .init(mode: .lenient))
            Issue.record("Expected missing input URL to throw.")
        } catch let parseError as DaisyParseError {
            #expect(parseError.diagnostic.code == "resolver.input-not-found")
            #expect(parseError.diagnostic.severity == .error)
        }
    }

    @Test("Given unsupported file input when parsing then resolver unsupported input error is thrown")
    func test_givenUnsupportedFileInput_whenParsing_thenResolverUnsupportedInputErrorIsThrown() async throws {
        let plainTextURL = try TestFixtureBuilder.makePlainTextInputFile()
        defer { TestFixtureBuilder.removeIfPresent(plainTextURL) }

        do {
            _ = try await parsePublication(at: plainTextURL, options: .init(mode: .lenient))
            Issue.record("Expected unsupported input to throw.")
        } catch let parseError as DaisyParseError {
            #expect(parseError.diagnostic.code == "resolver.unsupported-input")
        }
    }

    @Test("Given invalid zip archive when parsing then resolver invalid zip error is thrown")
    func test_givenInvalidZipArchive_whenParsing_thenResolverInvalidZipErrorIsThrown() async throws {
        let invalidZip = try TestFixtureBuilder.makeInvalidZipFile()
        defer { TestFixtureBuilder.removeIfPresent(invalidZip) }

        do {
            _ = try await parsePublication(at: invalidZip, options: .init(mode: .lenient))
            Issue.record("Expected invalid zip to throw.")
        } catch let parseError as DaisyParseError {
            #expect(parseError.diagnostic.code == "resolver.invalid-zip")
        }
    }

    @Test("Given zip traversal entry when parsing then unsafe path is rejected")
    func test_givenZipTraversalEntry_whenParsing_thenUnsafePathIsRejected() async throws {
        let traversalZip = try TestFixtureBuilder.makeTraversalZip()
        defer { TestFixtureBuilder.removeIfPresent(traversalZip) }

        do {
            _ = try await parsePublication(at: traversalZip, options: .init(mode: .lenient))
            Issue.record("Expected traversal zip to throw.")
        } catch let parseError as DaisyParseError {
            #expect(parseError.diagnostic.code == "resolver.zip-unsafe-entry-path")
        }
    }

    @Test("Given absolute path zip entry when parsing then unsafe path is rejected")
    func test_givenAbsolutePathZipEntry_whenParsing_thenUnsafePathIsRejected() async throws {
        let absoluteZip = try TestFixtureBuilder.makeAbsolutePathZip()
        defer { TestFixtureBuilder.removeIfPresent(absoluteZip) }

        do {
            _ = try await parsePublication(at: absoluteZip, options: .init(mode: .lenient))
            Issue.record("Expected absolute path zip to throw.")
        } catch let parseError as DaisyParseError {
            #expect(parseError.diagnostic.code == "resolver.zip-unsafe-entry-path")
        }
    }

    @Test("Given entry count above limit when parsing then resolver entry limit error is thrown")
    func test_givenEntryCountAboveLimit_whenParsing_thenResolverEntryLimitErrorIsThrown() async throws {
        let fixtureDirectory = try TestFixtureBuilder.makePublicationDirectory(variant: .valid)
        let fixtureZip = try TestFixtureBuilder.makeZip(from: fixtureDirectory)
        defer {
            TestFixtureBuilder.removeIfPresent(fixtureDirectory)
            TestFixtureBuilder.removeIfPresent(fixtureZip)
        }

        let parser = DaisyParserPipeline(
            options: .init(mode: .lenient),
            zipLimits: DaisyZipLimits(maxEntries: 1, maxEntrySize: 1_024_000, maxTotalUncompressedSize: 10_000_000)
        )

        do {
            _ = try await parser.parse(at: fixtureZip)
            Issue.record("Expected entry limit to throw.")
        } catch let parseError as DaisyParseError {
            #expect(parseError.diagnostic.code == "resolver.zip-entry-limit-exceeded")
        }
    }

    @Test("Given entry size above limit when parsing then resolver entry size limit error is thrown")
    func test_givenEntrySizeAboveLimit_whenParsing_thenResolverEntrySizeLimitErrorIsThrown() async throws {
        let largeEntryZip = try TestFixtureBuilder.makeLargeEntryZip(byteCount: 512)
        defer { TestFixtureBuilder.removeIfPresent(largeEntryZip) }

        let parser = DaisyParserPipeline(
            options: .init(mode: .lenient),
            zipLimits: DaisyZipLimits(maxEntries: 20_000, maxEntrySize: 128, maxTotalUncompressedSize: 10_000_000)
        )

        do {
            _ = try await parser.parse(at: largeEntryZip)
            Issue.record("Expected entry size limit to throw.")
        } catch let parseError as DaisyParseError {
            #expect(parseError.diagnostic.code == "resolver.zip-entry-size-limit-exceeded")
        }
    }

    @Test("Given total uncompressed size above limit when parsing then resolver total size limit error is thrown")
    func test_givenTotalUncompressedSizeAboveLimit_whenParsing_thenResolverTotalSizeLimitErrorIsThrown() async throws {
        let largeEntryZip = try TestFixtureBuilder.makeLargeEntryZip(byteCount: 512)
        defer { TestFixtureBuilder.removeIfPresent(largeEntryZip) }

        let parser = DaisyParserPipeline(
            options: .init(mode: .lenient),
            zipLimits: DaisyZipLimits(maxEntries: 20_000, maxEntrySize: 1_024, maxTotalUncompressedSize: 128)
        )

        do {
            _ = try await parser.parse(at: largeEntryZip)
            Issue.record("Expected total size limit to throw.")
        } catch let parseError as DaisyParseError {
            #expect(parseError.diagnostic.code == "resolver.zip-total-size-limit-exceeded")
        }
    }
}
