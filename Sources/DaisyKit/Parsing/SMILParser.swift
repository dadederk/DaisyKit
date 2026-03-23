import Foundation

enum DaisySMILParser {
    static func parseRefs(
        smilURL: URL,
        relativePath: String,
        opfBaseDirectory: URL,
        workspaceRootURL: URL,
        collector: DaisyDiagnosticCollector
    ) throws -> [DaisySmilRef] {
        DaisyLogger.smil.info("🎼 Parsing SMIL: \(smilURL.lastPathComponent, privacy: .public)")

        let root: DaisyXMLElement
        do {
            root = try DaisyXML.rootElement(at: smilURL)
        } catch let parseError as DaisyParseError {
            try collector.record(
                DaisyDiagnostic(
                    severity: .error,
                    code: "smil.xml-parse-failed",
                    message: parseError.diagnostic.message,
                    sourcePath: relativePath
                )
            )
            return []
        }

        var refs: [DaisySmilRef] = []
        for par in root.descendants(named: "par") {
            guard let textNode = par.firstChild(named: "text") else { continue }
            guard let textSource = textNode.attributes["src"], !textSource.isEmpty else {
                try collector.record(
                    DaisyDiagnostic(
                        severity: .warning,
                        code: "smil.missing-text-source",
                        message: "SMIL par node is missing text src.",
                        sourcePath: relativePath
                    )
                )
                continue
            }

            guard let resolved = DaisyPathResolution.resolveHref(
                href: textSource,
                relativeTo: opfBaseDirectory,
                workspaceRootURL: workspaceRootURL
            ) else {
                try collector.record(
                    DaisyDiagnostic(
                        severity: .warning,
                        code: "smil.text-source-outside-workspace",
                        message: "SMIL text source points outside the workspace.",
                        sourcePath: relativePath
                    )
                )
                continue
            }

            refs.append(
                DaisySmilRef(
                    id: par.attributes["id"],
                    sourcePath: relativePath,
                    textTarget: textSource,
                    resolvedTextTarget: resolved.pathWithFragment,
                    audioSource: par.firstChild(named: "audio")?.attributes["src"]
                )
            )
        }

        return refs
    }
}
