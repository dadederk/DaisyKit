import Foundation

enum DaisyNCXParser {
    static func parse(
        ncxURL: URL,
        collector: DaisyDiagnosticCollector
    ) throws -> [DaisyNavPoint] {
        DaisyLogger.ncx.info("🧭 Parsing NCX: \(ncxURL.lastPathComponent, privacy: .public)")
        let root: DaisyXMLElement
        do {
            root = try DaisyXML.rootElement(at: ncxURL)
        } catch let parseError as DaisyParseError {
            try collector.record(
                DaisyDiagnostic(
                    severity: .error,
                    code: "ncx.xml-parse-failed",
                    message: parseError.diagnostic.message,
                    sourcePath: ncxURL.lastPathComponent
                )
            )
            return []
        }

        guard let navMap = root.firstDescendant(named: "navmap") else {
            try collector.record(
                DaisyDiagnostic(
                    severity: .warning,
                    code: "ncx.navmap-missing",
                    message: "NCX navMap is missing.",
                    sourcePath: ncxURL.lastPathComponent
                )
            )
            return []
        }

        return try navMap.children(named: "navpoint").map { try parse(navPoint: $0, collector: collector) }
    }

    private static func parse(navPoint: DaisyXMLElement, collector: DaisyDiagnosticCollector) throws -> DaisyNavPoint {
        let id = navPoint.attributes["id"]
        let playOrder = navPoint.attributes["playorder"].flatMap(Int.init)
        let label = navPoint
            .firstChild(named: "navlabel")?
            .firstChild(named: "text")?
            .textValue ?? ""
        let contentSource = navPoint.firstChild(named: "content")?.attributes["src"] ?? ""

        if label.isEmpty {
            try collector.record(
                DaisyDiagnostic(
                    severity: .warning,
                    code: "ncx.missing-label",
                    message: "A navPoint is missing a label.",
                    elementID: id
                )
            )
        }

        if contentSource.isEmpty {
            try collector.record(
                DaisyDiagnostic(
                    severity: .warning,
                    code: "ncx.missing-content-source",
                    message: "A navPoint is missing a content source.",
                    elementID: id
                )
            )
        }

        let children = try navPoint.children(named: "navpoint").map { try parse(navPoint: $0, collector: collector) }
        return DaisyNavPoint(id: id, playOrder: playOrder, label: label, contentSource: contentSource, children: children)
    }
}
