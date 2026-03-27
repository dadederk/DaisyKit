// TextPublicationParserUnitTests.swift
// DaisyKitTests

import Foundation
import Testing
@testable import DaisyKit

@Suite("Text Publication Parser Unit")
struct TextPublicationParserUnitTests {
    @Test("Given valid fixture when parsing text publication then lines and headings are mapped for app consumption")
    func givenValidFixtureWhenParsingTextPublicationThenLinesAndHeadingsAreMapped() async throws {
        let fixtureURL = try TestFixtureBuilder.makePublicationDirectory(variant: .valid)
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parseTextPublication(at: fixtureURL, options: .init(mode: .lenient))

        #expect(!report.publication.title.isEmpty)
        #expect(report.publication.lines.contains("Fixture Title") == false)
        #expect(report.publication.lines.contains("Hello world."))
        #expect(report.publication.lines.contains("Bonjour le monde."))
        #expect(report.publication.headings.contains { $0.text == "Chapter 1" })
    }

    @Test("Given DTBook-only input when parsing text publication lenient then parser recovers without OPF")
    func givenDTBookOnlyInputWhenParsingTextPublicationLenientThenParserRecoversWithoutOPF() async throws {
        let fixtureURL = try makeDTBookOnlyDirectory()
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parseTextPublication(at: fixtureURL, options: .init(mode: .lenient))

        #expect(report.publication.title == "A DTBook-Only Fixture")
        #expect(report.publication.lines.contains("First sentence in DTBook-only fixture."))
        #expect(report.publication.headings.contains { $0.text == "Section Alpha" })
        #expect(report.diagnostics.contains { $0.code == "normalize.dtbook-fallback-used" })
    }

    @Test("Given DTBook-only input when parsing text publication strict then parser throws OPF missing error")
    func givenDTBookOnlyInputWhenParsingTextPublicationStrictThenParserThrowsOPFMissingError() async throws {
        let fixtureURL = try makeDTBookOnlyDirectory()
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        await #expect(throws: DaisyParseError.self) {
            _ = try await parseTextPublication(at: fixtureURL, options: .init(mode: .strict))
        }
    }

    @Test("Given DTBook with sent and hd tags when parsing text publication then sent content and hd headings are preserved")
    func givenDTBookWithSentAndHDTagsWhenParsingThenSentContentAndHDHeadingsArePreserved() async throws {
        let fixtureURL = try makeDTBookOnlyDirectory()
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parseTextPublication(at: fixtureURL, options: .init(mode: .lenient))

        #expect(report.publication.lines.contains("First sentence in DTBook-only fixture."))
        #expect(report.publication.lines.contains("Second sentence in DTBook-only fixture."))
        #expect(report.publication.headings.contains { $0.text == "Section Alpha" })
    }

    @Test("Given OPF without DTBook spine when parsing text publication lenient then parser recovers from unreferenced DTBook")
    func givenOPFWithoutDTBookSpineWhenParsingTextPublicationLenientThenParserRecoversFromUnreferencedDTBook() async throws {
        let fixtureURL = try makeOPFWithoutDTBookSpineDirectory()
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        let report = try await parseTextPublication(at: fixtureURL, options: .init(mode: .lenient))

        #expect(report.publication.lines.contains("Recovered from unreferenced DTBook content."))
        #expect(report.diagnostics.contains { $0.code == "normalize.dtbook-fallback-used" })
    }

    @Test("Given OPF without DTBook spine when parsing text publication strict then parser throws no readable text error")
    func givenOPFWithoutDTBookSpineWhenParsingTextPublicationStrictThenParserThrowsNoReadableTextError() async throws {
        let fixtureURL = try makeOPFWithoutDTBookSpineDirectory()
        defer { TestFixtureBuilder.removeIfPresent(fixtureURL) }

        do {
            _ = try await parseTextPublication(at: fixtureURL, options: .init(mode: .strict))
            Issue.record("Expected strict parseTextPublication to throw no-readable-text when OPF yields no readable text.")
        } catch let parseError as DaisyParseError {
            #expect(parseError.diagnostic.code == "normalize.no-readable-text")
        }
    }

    private func makeDTBookOnlyDirectory() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("daisykit-dtbook-only-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let dtbook = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <dtbook xmlns=\"http://www.daisy.org/z3986/2005/dtbook/\" version=\"2005-1\" xml:lang=\"en\">
          <book>
            <frontmatter>
              <doctitle id=\"doc-title\">A DTBook-Only Fixture</doctitle>
            </frontmatter>
            <bodymatter>
              <hd id=\"sec-alpha\" level=\"2\">Section Alpha</hd>
              <sent id=\"s1\">First sentence in DTBook-only fixture.</sent>
              <sent id=\"s2\">Second sentence in DTBook-only fixture.</sent>
            </bodymatter>
          </book>
        </dtbook>
        """

        let dtbookURL = root.appendingPathComponent("book.xml")
        try Data(dtbook.utf8).write(to: dtbookURL)

        return root
    }

    private func makeOPFWithoutDTBookSpineDirectory() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("daisykit-opf-no-dtbook-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let opf = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <package xmlns=\"http://www.daisy.org/z3986/2005/ncx/\" version=\"2005-1\" unique-identifier=\"bookid\">
          <metadata xmlns:dc=\"http://purl.org/dc/elements/1.1/\">
            <dc:title>OPF Without DTBook Spine</dc:title>
            <dc:identifier id=\"bookid\">urn:uuid:opf-no-dtbook</dc:identifier>
            <dc:language>en</dc:language>
          </metadata>
          <manifest>
            <item id=\"content\" href=\"chapter.xhtml\" media-type=\"application/xhtml+xml\" />
          </manifest>
          <spine>
            <itemref idref=\"content\" />
          </spine>
        </package>
        """

        let xhtml = """
        <html xmlns=\"http://www.w3.org/1999/xhtml\">
          <head><title>Placeholder</title></head>
          <body><p>Placeholder XHTML content.</p></body>
        </html>
        """

        let unreferencedDTBook = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <dtbook xmlns=\"http://www.daisy.org/z3986/2005/dtbook/\" version=\"2005-1\" xml:lang=\"en\">
          <book>
            <bodymatter>
              <doctitle>Recovered DTBook</doctitle>
              <sent id=\"recover-1\">Recovered from unreferenced DTBook content.</sent>
            </bodymatter>
          </book>
        </dtbook>
        """

        try Data(opf.utf8).write(to: root.appendingPathComponent("book.opf"))
        try Data(xhtml.utf8).write(to: root.appendingPathComponent("chapter.xhtml"))
        try Data(unreferencedDTBook.utf8).write(to: root.appendingPathComponent("unreferenced.xml"))

        return root
    }
}
