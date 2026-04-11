import Foundation
import Testing
@testable import DaisyKit

@Suite("DTBook Parser Unit")
struct DTBookParserUnitTests {
    @Test("Given heading levels h1 through h6 when parsing then all heading levels are captured")
    func test_givenHeadingLevelsH1ThroughH6_whenParsing_thenAllHeadingLevelsAreCaptured() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .dtbookHeadingLevels)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL)
        let levels = report.publication.sections.first?.headings.map(\.level) ?? []
        #expect(levels.contains(1))
        #expect(levels.contains(2))
        #expect(levels.contains(3))
        #expect(levels.contains(4))
        #expect(levels.contains(5))
        #expect(levels.contains(6))
    }

    @Test("Given mixed language paragraphs when parsing then multilingual text is preserved")
    func test_givenMixedLanguageParagraphs_whenParsing_thenMultilingualTextIsPreserved() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .dtbookMixedLanguage)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL)
        let paragraphs = report.publication.sections.first?.paragraphs.map(\.text) ?? []

        #expect(paragraphs.contains("Hello world."))
        #expect(paragraphs.contains("Hola món."))
        #expect(paragraphs.contains("Bonjour le monde."))
        #expect(paragraphs.contains("مرحبا بالعالم."))
    }

    @Test("Given whitespace paragraphs when parsing then empty paragraphs are ignored")
    func test_givenWhitespaceParagraphs_whenParsing_thenEmptyParagraphsAreIgnored() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .dtbookWhitespaceParagraphs)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL)
        #expect(report.publication.sections.first?.paragraphs.count == 1)
        #expect(report.publication.sections.first?.paragraphs.first?.text == "Visible paragraph.")
    }

    @Test("Given duplicate dtbook ids when parsing then anchors are de-duplicated")
    func test_givenDuplicateDTBookIDs_whenParsing_thenAnchorsAreDeduplicated() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .dtbookDuplicateIDs)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL)
        let anchors = report.publication.sections.first?.anchors ?? []
        #expect(anchors.count == 1)
        #expect(anchors.first?.id == "dup")
    }

    @Test("Given dtbook with bodymatter when parsing then section role is bodymatter and only body content is included")
    func test_givenDTBookWithBodymatter_whenParsing_thenSectionRoleIsBodymatterAndOnlyBodyContentIncluded() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .dtbookBodymatterOnly)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL)
        let section = try #require(report.publication.sections.first)

        #expect(section.role == .bodymatter)
        #expect(section.paragraphs.map(\.text).contains("Body paragraph."))
        #expect(!section.paragraphs.map(\.text).contains("Index entry."))
        #expect(!section.paragraphs.map(\.text).contains("Chapter One"))
    }

    @Test("Given dtbook with only frontmatter when parsing then section role is frontmatter")
    func test_givenDTBookWithOnlyFrontmatter_whenParsing_thenSectionRoleIsFrontmatter() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .dtbookFrontmatterOnly)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL)
        let section = try #require(report.publication.sections.first)

        #expect(section.role == .frontmatter)
        #expect(section.paragraphs.map(\.text).contains("Introductory material."))
    }

    @Test("Given dtbook without structural elements when parsing then section role is fullDocument")
    func test_givenDTBookWithoutStructuralElements_whenParsing_thenSectionRoleIsFullDocument() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .dtbookNoStructuralElements)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parsePublication(at: fixtureURL)
        let section = try #require(report.publication.sections.first)

        #expect(section.role == .fullDocument)
        #expect(section.paragraphs.map(\.text).contains("Flat paragraph without structural containers."))
    }
}
