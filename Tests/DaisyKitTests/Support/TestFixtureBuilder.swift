import Foundation
import ZIPFoundation

enum DaisyFixtureVariant {
    case valid
    case opfMissingManifest
    case opfMissingSpine
    case opfInvalidManifestItem
    case opfInvalidSpineIDRef
    case opfUniqueIdentifierMismatch
    case opfHrefOutsideWorkspace
    case ncxMissingNavMap
    case ncxMissingLabelAndSource
    case ncxNestedDepth
    case malformedNCX
    case dtbookHeadingLevels
    case dtbookMixedLanguage
    case dtbookWhitespaceParagraphs
    case dtbookDuplicateIDs
    case smilMissingTextSrc
    case smilOutsideWorkspaceTarget
    case unresolvedSmilTarget
    case smilFileMissingReferencedByOPF
}

enum TestFixtureBuilder {
    static func makePublicationDirectory(variant: DaisyFixtureVariant) throws -> URL {
        let root = try makeTemporaryDirectory(prefix: "daisykit-fixture")

        let opf = opfXML(for: variant)
        let ncx = ncxXML(for: variant)
        let dtbook = dtbookXML(for: variant)
        let smil = smilXML(for: variant)

        try write(opf, to: root.appendingPathComponent("book.opf"))
        try write(ncx, to: root.appendingPathComponent("toc.ncx"))
        try write(dtbook, to: root.appendingPathComponent("chapter1.xml"))

        if variant != .smilFileMissingReferencedByOPF {
            try write(smil, to: root.appendingPathComponent("sync.smil"))
        }

        return root
    }

    static func makeLargePublicationDirectory(paragraphCount: Int) throws -> URL {
        let root = try makeTemporaryDirectory(prefix: "daisykit-large-fixture")
        try write(opfXML(for: .valid), to: root.appendingPathComponent("book.opf"))
        try write(ncxXML(for: .valid), to: root.appendingPathComponent("toc.ncx"))
        try write(smilXML(for: .valid), to: root.appendingPathComponent("sync.smil"))

        var paragraphs: [String] = []
        paragraphs.reserveCapacity(paragraphCount)
        for index in 0..<paragraphCount {
            paragraphs.append("<p id=\"p\(index + 1)\">Large paragraph \(index + 1).</p>")
        }

        let dtbook = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <dtbook xmlns=\"http://www.daisy.org/z3986/2005/dtbook/\" version=\"2005-1\">
          <book>
            <bodymatter>
              <h1 id=\"h1\">Large Fixture</h1>
              \(paragraphs.joined(separator: "\n              "))
            </bodymatter>
          </book>
        </dtbook>
        """
        try write(dtbook, to: root.appendingPathComponent("chapter1.xml"))
        return root
    }

    static func makeWorkingCopyOfRealFixture(id fixtureID: String) throws -> URL {
        let manifest = try FixtureManifestLoader.load()
        guard let descriptor = manifest.first(where: { $0.id == fixtureID && $0.isReal }) else {
            throw NSError(domain: "TestFixtureBuilder", code: 501)
        }

        let sourceDirectory = FixtureManifestLoader.realFixtureDirectory(for: descriptor)
        let destination = try makeTemporaryDirectory(prefix: "daisykit-real-copy")
        try copyDirectoryContents(from: sourceDirectory, to: destination)
        return destination
    }

    static func makeZip(from directoryURL: URL) throws -> URL {
        let zipURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("daisykit-fixture-\(UUID().uuidString).zip")
        let archive = try Archive(url: zipURL, accessMode: .create)

        let files = try fileURLs(in: directoryURL).sorted(by: { $0.path < $1.path })
        for fileURL in files {
            let relativePath = try relativePath(from: directoryURL, to: fileURL)
            let data = try Data(contentsOf: fileURL)
            try archive.addEntry(
                with: relativePath,
                type: .file,
                uncompressedSize: Int64(data.count),
                compressionMethod: .deflate
            ) { position, size in
                let start = Int(position)
                let end = Int(position + Int64(size))
                return data.subdata(in: start..<end)
            }
        }

        return zipURL
    }

    static func makeTraversalZip() throws -> URL {
        try makeZipWithEntry(path: "../escape.txt", payload: Data("unsafe".utf8))
    }

    static func makeAbsolutePathZip() throws -> URL {
        try makeZipWithEntry(path: "/absolute.txt", payload: Data("unsafe".utf8))
    }

    static func makeLargeEntryZip(byteCount: Int) throws -> URL {
        let payload = Data(repeating: 65, count: byteCount)
        return try makeZipWithEntry(path: "large.bin", payload: payload)
    }

    static func makeInvalidZipFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("daisykit-invalid-\(UUID().uuidString).zip")
        try Data("not-a-zip".utf8).write(to: url)
        return url
    }

    static func makePlainTextInputFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("daisykit-input-\(UUID().uuidString).txt")
        try Data("plain text".utf8).write(to: url)
        return url
    }

    static func makeMissingInputURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("daisykit-missing-\(UUID().uuidString)", isDirectory: false)
    }

    static func removeIfPresent(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private static func makeZipWithEntry(path: String, payload: Data) throws -> URL {
        let zipURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("daisykit-zip-\(UUID().uuidString).zip")
        let archive = try Archive(url: zipURL, accessMode: .create)

        try archive.addEntry(
            with: path,
            type: .file,
            uncompressedSize: Int64(payload.count),
            compressionMethod: .none
        ) { position, size in
            let start = Int(position)
            let end = Int(position + Int64(size))
            return payload.subdata(in: start..<end)
        }

        return zipURL
    }

    private static func makeTemporaryDirectory(prefix: String) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private static func copyDirectoryContents(from source: URL, to destination: URL) throws {
        for fileURL in try fileURLs(in: source) {
            let relative = try relativePath(from: source, to: fileURL)
            let target = destination.appendingPathComponent(relative)
            try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: fileURL, to: target)
        }
    }

    private static func fileURLs(in directoryURL: URL) throws -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var urls: [URL] = []
        for case let url as URL in enumerator {
            if (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
                urls.append(url)
            }
        }
        return urls
    }

    private static func relativePath(from root: URL, to fileURL: URL) throws -> String {
        let rootPath = root.standardizedFileURL.path
        let filePath = fileURL.standardizedFileURL.path
        let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        guard filePath.hasPrefix(prefix) else {
            throw NSError(domain: "TestFixtureBuilder", code: 511)
        }
        return String(filePath.dropFirst(prefix.count))
    }

    private static func write(_ string: String, to url: URL) throws {
        try Data(string.utf8).write(to: url)
    }

    private static func opfXML(for variant: DaisyFixtureVariant) -> String {
        switch variant {
        case .opfMissingManifest:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <package xmlns=\"http://www.daisy.org/z3986/2005/ncx/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" unique-identifier=\"BookId\" version=\"2005-1\">
              <metadata>
                <dc:title>Fixture Title</dc:title>
                <dc:identifier id=\"BookId\">fixture-id</dc:identifier>
              </metadata>
              <spine toc=\"ncx\">
                <itemref idref=\"chapter1\"/>
              </spine>
            </package>
            """
        case .opfMissingSpine:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <package xmlns=\"http://www.daisy.org/z3986/2005/ncx/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" unique-identifier=\"BookId\" version=\"2005-1\">
              <metadata>
                <dc:title>Fixture Title</dc:title>
                <dc:identifier id=\"BookId\">fixture-id</dc:identifier>
              </metadata>
              <manifest>
                <item id=\"ncx\" href=\"toc.ncx\" media-type=\"application/x-dtbncx+xml\"/>
                <item id=\"chapter1\" href=\"chapter1.xml\" media-type=\"application/x-dtbook+xml\"/>
              </manifest>
            </package>
            """
        case .opfInvalidManifestItem:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <package xmlns=\"http://www.daisy.org/z3986/2005/ncx/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" unique-identifier=\"BookId\" version=\"2005-1\">
              <metadata>
                <dc:title>Fixture Title</dc:title>
                <dc:identifier id=\"BookId\">fixture-id</dc:identifier>
              </metadata>
              <manifest>
                <item id=\"ncx\" href=\"toc.ncx\" media-type=\"application/x-dtbncx+xml\"/>
                <item id=\"chapter1\" media-type=\"application/x-dtbook+xml\"/>
              </manifest>
              <spine toc=\"ncx\">
                <itemref idref=\"chapter1\"/>
              </spine>
            </package>
            """
        case .opfInvalidSpineIDRef:
            return opfTemplate(uniqueIdentifier: "BookId", chapterHref: "chapter1.xml", spineIDRef: "missing-id")
        case .opfUniqueIdentifierMismatch:
            return opfTemplate(uniqueIdentifier: "UnknownIdentifier", chapterHref: "chapter1.xml", spineIDRef: "chapter1")
        case .opfHrefOutsideWorkspace:
            return opfTemplate(uniqueIdentifier: "BookId", chapterHref: "../outside/chapter1.xml", spineIDRef: "chapter1")
        case .smilFileMissingReferencedByOPF:
            return opfTemplate(uniqueIdentifier: "BookId", chapterHref: "chapter1.xml", spineIDRef: "chapter1", includeSmil: true)
        default:
            return opfTemplate(uniqueIdentifier: "BookId", chapterHref: "chapter1.xml", spineIDRef: "chapter1")
        }
    }

    private static func opfTemplate(
        uniqueIdentifier: String,
        chapterHref: String,
        spineIDRef: String,
        includeSmil: Bool = true
    ) -> String {
        let smilItem = includeSmil ? "<item id=\"smil1\" href=\"sync.smil\" media-type=\"application/smil+xml\"/>" : ""
        return """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <package xmlns=\"http://www.daisy.org/z3986/2005/ncx/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" unique-identifier=\"\(uniqueIdentifier)\" version=\"2005-1\">
          <metadata>
            <dc:title>Fixture Title</dc:title>
            <dc:creator>Fixture Author</dc:creator>
            <dc:identifier id=\"BookId\">fixture-id</dc:identifier>
            <dc:identifier id=\"AltId\">alternate-id</dc:identifier>
            <dc:language>en</dc:language>
          </metadata>
          <manifest>
            <item id=\"ncx\" href=\"toc.ncx\" media-type=\"application/x-dtbncx+xml\"/>
            <item id=\"chapter1\" href=\"\(chapterHref)\" media-type=\"application/x-dtbook+xml\"/>
            \(smilItem)
          </manifest>
          <spine toc=\"ncx\">
            <itemref idref=\"\(spineIDRef)\"/>
          </spine>
        </package>
        """
    }

    private static func ncxXML(for variant: DaisyFixtureVariant) -> String {
        switch variant {
        case .malformedNCX:
            return "<ncx><navMap><navPoint>"
        case .ncxMissingNavMap:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <ncx xmlns=\"http://www.daisy.org/z3986/2005/ncx/\" version=\"2005-1\"></ncx>
            """
        case .ncxMissingLabelAndSource:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <ncx xmlns=\"http://www.daisy.org/z3986/2005/ncx/\" version=\"2005-1\">
              <navMap>
                <navPoint id=\"nav1\" playOrder=\"1\">
                  <navLabel><text>   </text></navLabel>
                  <content/>
                </navPoint>
              </navMap>
            </ncx>
            """
        case .ncxNestedDepth:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <ncx xmlns=\"http://www.daisy.org/z3986/2005/ncx/\" version=\"2005-1\">
              <navMap>
                <navPoint id=\"nav1\" playOrder=\"1\">
                  <navLabel><text>Level 1</text></navLabel>
                  <content src=\"chapter1.xml#h1\"/>
                  <navPoint id=\"nav2\" playOrder=\"2\">
                    <navLabel><text>Level 2</text></navLabel>
                    <content src=\"chapter1.xml#h2\"/>
                    <navPoint id=\"nav3\" playOrder=\"3\">
                      <navLabel><text>Level 3</text></navLabel>
                      <content src=\"chapter1.xml#h3\"/>
                    </navPoint>
                  </navPoint>
                </navPoint>
              </navMap>
            </ncx>
            """
        default:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <ncx xmlns=\"http://www.daisy.org/z3986/2005/ncx/\" version=\"2005-1\">
              <navMap>
                <navPoint id=\"nav1\" playOrder=\"1\">
                  <navLabel><text>Chapter 1</text></navLabel>
                  <content src=\"chapter1.xml#h1\"/>
                </navPoint>
              </navMap>
            </ncx>
            """
        }
    }

    private static func dtbookXML(for variant: DaisyFixtureVariant) -> String {
        switch variant {
        case .dtbookHeadingLevels:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <dtbook xmlns=\"http://www.daisy.org/z3986/2005/dtbook/\" version=\"2005-1\">
              <book>
                <frontmatter><h1 id=\"f1\">Front</h1></frontmatter>
                <bodymatter>
                  <h1 id=\"h1\">One</h1>
                  <h2 id=\"h2\">Two</h2>
                  <h3 id=\"h3\">Three</h3>
                  <h4 id=\"h4\">Four</h4>
                  <h5 id=\"h5\">Five</h5>
                  <h6 id=\"h6\">Six</h6>
                </bodymatter>
                <rearmatter><h2 id=\"r1\">Rear</h2></rearmatter>
              </book>
            </dtbook>
            """
        case .dtbookMixedLanguage:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <dtbook xmlns=\"http://www.daisy.org/z3986/2005/dtbook/\" version=\"2005-1\">
              <book>
                <bodymatter>
                  <h1 id=\"h1\">Multilingual</h1>
                  <p id=\"p1\">Hello world.</p>
                  <p id=\"p2\">Hola món.</p>
                  <p id=\"p3\">Bonjour le monde.</p>
                  <p id=\"p4\">مرحبا بالعالم.</p>
                </bodymatter>
              </book>
            </dtbook>
            """
        case .dtbookWhitespaceParagraphs:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <dtbook xmlns=\"http://www.daisy.org/z3986/2005/dtbook/\" version=\"2005-1\">
              <book>
                <bodymatter>
                  <h1 id=\"h1\">Whitespace</h1>
                  <p id=\"p1\">   </p>
                  <p id=\"p2\">Visible paragraph.</p>
                </bodymatter>
              </book>
            </dtbook>
            """
        case .dtbookDuplicateIDs:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <dtbook xmlns=\"http://www.daisy.org/z3986/2005/dtbook/\" version=\"2005-1\">
              <book>
                <bodymatter>
                  <h1 id=\"dup\">Heading Dup</h1>
                  <p id=\"dup\">Paragraph Dup</p>
                </bodymatter>
              </book>
            </dtbook>
            """
        default:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <dtbook xmlns=\"http://www.daisy.org/z3986/2005/dtbook/\" version=\"2005-1\">
              <book>
                <bodymatter>
                  <h1 id=\"h1\">Chapter 1</h1>
                  <h2 id=\"h2\">Section 1</h2>
                  <p id=\"p1\">Hello world.</p>
                  <p id=\"p2\">Bonjour le monde.</p>
                </bodymatter>
              </book>
            </dtbook>
            """
        }
    }

    private static func smilXML(for variant: DaisyFixtureVariant) -> String {
        switch variant {
        case .smilMissingTextSrc:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <smil xmlns=\"http://www.w3.org/2001/SMIL20/Language\">
              <body><seq><par id=\"par1\"><text/></par></seq></body>
            </smil>
            """
        case .smilOutsideWorkspaceTarget:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <smil xmlns=\"http://www.w3.org/2001/SMIL20/Language\">
              <body><seq><par id=\"par1\"><text src=\"../outside/chapter.xml#p1\"/></par></seq></body>
            </smil>
            """
        case .unresolvedSmilTarget:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <smil xmlns=\"http://www.w3.org/2001/SMIL20/Language\">
              <body><seq><par id=\"par1\"><text src=\"chapter1.xml#missing-anchor\"/></par></seq></body>
            </smil>
            """
        default:
            return """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <smil xmlns=\"http://www.w3.org/2001/SMIL20/Language\">
              <body>
                <seq>
                  <par id=\"par1\"><text src=\"chapter1.xml#p1\"/></par>
                  <par id=\"par2\"><text src=\"chapter1.xml#p2\"/></par>
                </seq>
              </body>
            </smil>
            """
        }
    }
}
