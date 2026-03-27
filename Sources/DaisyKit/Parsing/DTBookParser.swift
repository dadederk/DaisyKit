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

        let body = root.firstDescendant(named: "bodymatter") ?? root.firstDescendant(named: "book") ?? root
        var state = TraversalState(sourcePath: relativePath)
        collect(from: body, state: &state)

        return DaisySection(
            sourcePath: relativePath,
            title: state.sectionTitle ?? state.headings.first?.text,
            paragraphs: state.paragraphs,
            headings: state.headings,
            anchors: state.anchors
        )
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
