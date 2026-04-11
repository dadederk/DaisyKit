import Foundation

enum DaisyDTBookParser {
    static func parseSection(
        dtbookURL: URL,
        relativePath: String,
        collector: DaisyDiagnosticCollector
    ) throws -> DaisySection {
        DaisyLogger.dtbook.info("📝 Parsing DTBook: \(dtbookURL.lastPathComponent, privacy: .public)")
        let root: DaisyXMLElement
        do {
            root = try DaisyXML.rootElement(at: dtbookURL)
        } catch let parseError as DaisyParseError {
            try collector.record(
                DaisyDiagnostic(
                    severity: .error,
                    code: "dtbook.xml-parse-failed",
                    message: parseError.diagnostic.message,
                    sourcePath: relativePath
                )
            )
            return DaisySection(sourcePath: relativePath, title: nil, paragraphs: [], headings: [], anchors: [])
        }

        let (body, role) = resolveBodyNode(from: root)
        var state = TraversalState(sourcePath: relativePath)
        collect(from: body, state: &state)

        return DaisySection(
            sourcePath: relativePath,
            title: state.sectionTitle ?? state.headings.first?.text,
            paragraphs: state.paragraphs,
            headings: state.headings,
            anchors: state.anchors,
            role: role
        )
    }

    /// Resolves the traversal root node and its structural role from a DTBook document root.
    ///
    /// Prefers `<bodymatter>` (the primary narrative body), then falls back to `<frontmatter>` if it is the
    /// only structural container present, and finally uses `<book>` or the document root when no explicit
    /// structural elements are found.
    private static func resolveBodyNode(from root: DaisyXMLElement) -> (node: DaisyXMLElement, role: DaisySectionRole) {
        if let bodymatter = root.firstDescendant(named: "bodymatter") {
            return (bodymatter, .bodymatter)
        }
        if let rearmatter = root.firstDescendant(named: "rearmatter"),
           root.firstDescendant(named: "frontmatter") == nil {
            return (rearmatter, .rearmatter)
        }
        if let frontmatter = root.firstDescendant(named: "frontmatter"),
           root.firstDescendant(named: "rearmatter") == nil {
            return (frontmatter, .frontmatter)
        }
        let fallback = root.firstDescendant(named: "book") ?? root
        return (fallback, .fullDocument)
    }

    private static func collect(from node: DaisyXMLElement, state: inout TraversalState) {
        if let anchorID = node.attributes["id"], state.seenAnchorIDs.insert(anchorID).inserted {
            state.anchors.append(DaisyAnchor(id: anchorID, href: "\(state.sourcePath)#\(anchorID)"))
        }

        if node.name == "doctitle", let text = node.textValue, !text.isEmpty {
            state.sectionTitle = state.sectionTitle ?? text
            let headingID = node.attributes["id"]
            let anchor = headingID.map { "\(state.sourcePath)#\($0)" }
            state.headings.append(DaisyHeading(id: headingID, level: 1, text: text, anchor: anchor))
            return
        }

        if node.name == "hd", let text = node.textValue, !text.isEmpty {
            let headingID = node.attributes["id"]
            let anchor = headingID.map { "\(state.sourcePath)#\($0)" }
            let declaredLevel = node.attributes["level"].flatMap(Int.init) ?? 2
            let normalizedLevel = max(1, min(6, declaredLevel))
            state.headings.append(DaisyHeading(id: headingID, level: normalizedLevel, text: text, anchor: anchor))
            return
        }

        if let headingLevel = headingLevel(for: node.name), let text = node.textValue, !text.isEmpty {
            let headingID = node.attributes["id"]
            let anchor = headingID.map { "\(state.sourcePath)#\($0)" }
            state.headings.append(DaisyHeading(id: headingID, level: headingLevel, text: text, anchor: anchor))
            state.sectionTitle = state.sectionTitle ?? text
            return
        }

        if paragraphElementNames.contains(node.name), let text = node.textValue, !text.isEmpty {
            state.paragraphs.append(DaisyParagraph(id: node.attributes["id"], text: text))
            return
        }

        for child in node.children {
            collect(from: child, state: &state)
        }
    }

    private static func headingLevel(for elementName: String) -> Int? {
        guard elementName.count == 2, elementName.first == "h", let level = Int(String(elementName.last!)) else {
            return nil
        }
        return (1...6).contains(level) ? level : nil
    }

    private static let paragraphElementNames: Set<String> = [
        "p",
        "sent",
        "li",
        "dd",
        "dt",
        "caption",
        "prodnote",
        "note"
    ]
}

private struct TraversalState {
    let sourcePath: String
    var sectionTitle: String?
    var paragraphs: [DaisyParagraph] = []
    var headings: [DaisyHeading] = []
    var anchors: [DaisyAnchor] = []
    var seenAnchorIDs: Set<String> = []
}
