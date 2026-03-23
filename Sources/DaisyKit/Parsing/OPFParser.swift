import Foundation

struct DaisyOPFParseResult {
    let metadata: DaisyMetadata
    let manifest: [DaisyManifestItem]
    let spine: [DaisySpineItem]
    let dtbookPaths: [String]
    let ncxPath: String?
    let smilPaths: [String]
}

enum DaisyOPFParser {
    static func parse(
        opfURL: URL,
        workspaceRootURL: URL,
        collector: DaisyDiagnosticCollector
    ) throws -> DaisyOPFParseResult {
        DaisyLogger.opf.info("📘 Parsing OPF: \(opfURL.lastPathComponent, privacy: .public)")
        let parsedRoot = try DaisyXML.rootElement(at: opfURL)
        let root = parsedRoot.name == "package"
            ? parsedRoot
            : (parsedRoot.firstDescendant(named: "package") ?? parsedRoot)
        guard root.name == "package" else {
            throw DaisyParseError(
                diagnostic: DaisyDiagnostic(
                    severity: .error,
                    code: "opf.missing-package-root",
                    message: "OPF package root element is missing.",
                    sourcePath: opfURL.lastPathComponent
                )
            )
        }

        let uniqueIdentifierID = root.attributes["unique-identifier"]
        let metadata = extractMetadata(from: root.firstChild(named: "metadata"), uniqueIdentifierID: uniqueIdentifierID)
        let manifest = try parseManifest(root: root, opfURL: opfURL, workspaceRootURL: workspaceRootURL, collector: collector)
        let spine = try parseSpine(root: root, manifest: manifest, collector: collector)

        let manifestByID = Dictionary(uniqueKeysWithValues: manifest.map { ($0.id, $0) })
        let dtbookPaths = spine.compactMap { manifestByID[$0.idRef] }
            .filter { $0.mediaType.localizedCaseInsensitiveContains("dtbook") || $0.href.lowercased().hasSuffix(".xml") }
            .map(\.normalizedPath)

        let tocID = root.firstChild(named: "spine")?.attributes["toc"]
        let ncxPath = resolveNCXPath(manifest: manifest, tocID: tocID)
        let smilPaths = manifest
            .filter { $0.mediaType.localizedCaseInsensitiveContains("smil") || $0.href.lowercased().hasSuffix(".smil") }
            .map(\.normalizedPath)

        return DaisyOPFParseResult(
            metadata: metadata,
            manifest: manifest,
            spine: spine,
            dtbookPaths: dtbookPaths,
            ncxPath: ncxPath,
            smilPaths: smilPaths
        )
    }

    private static func extractMetadata(
        from metadataRoot: DaisyXMLElement?,
        uniqueIdentifierID: String?
    ) -> DaisyMetadata {
        guard let metadataRoot else {
            return DaisyMetadata(title: nil, creator: nil, identifier: nil, language: nil)
        }

        var title: String?
        var creator: String?
        var language: String?
        var identifier: String?
        var identifiersByID: [String: String] = [:]

        for node in metadataRoot.children {
            guard let text = node.textValue else { continue }
            switch node.name {
            case "title":
                title = title ?? text
            case "creator":
                creator = creator ?? text
            case "identifier":
                identifier = identifier ?? text
                if let id = node.attributes["id"] {
                    identifiersByID[id] = text
                }
            case "language":
                language = language ?? text
            default:
                continue
            }
        }

        if let uniqueIdentifierID, let exactIdentifier = identifiersByID[uniqueIdentifierID] {
            identifier = exactIdentifier
        }
        return DaisyMetadata(title: title, creator: creator, identifier: identifier, language: language)
    }

    private static func parseManifest(
        root: DaisyXMLElement,
        opfURL: URL,
        workspaceRootURL: URL,
        collector: DaisyDiagnosticCollector
    ) throws -> [DaisyManifestItem] {
        guard let manifestRoot = root.firstChild(named: "manifest") else {
            try collector.record(
                DaisyDiagnostic(
                    severity: .error,
                    code: "opf.manifest-missing",
                    message: "Manifest element is missing from OPF.",
                    sourcePath: opfURL.lastPathComponent
                )
            )
            return []
        }

        let baseDirectory = opfURL.deletingLastPathComponent()
        var items: [DaisyManifestItem] = []

        for itemNode in manifestRoot.children(named: "item") {
            guard
                let id = itemNode.attributes["id"],
                let href = itemNode.attributes["href"],
                let mediaType = itemNode.attributes["media-type"]
            else {
                try collector.record(
                    DaisyDiagnostic(
                        severity: .error,
                        code: "opf.invalid-manifest-item",
                        message: "Manifest item is missing id, href, or media-type.",
                        sourcePath: opfURL.lastPathComponent
                    )
                )
                continue
            }

            guard let resolved = DaisyPathResolution.resolveHref(
                href: href,
                relativeTo: baseDirectory,
                workspaceRootURL: workspaceRootURL
            ) else {
                try collector.record(
                    DaisyDiagnostic(
                        severity: .error,
                        code: "opf.manifest-path-outside-workspace",
                        message: "Manifest item points outside the workspace.",
                        sourcePath: href,
                        elementID: id
                    )
                )
                continue
            }

            items.append(
                DaisyManifestItem(
                    id: id,
                    href: href,
                    mediaType: mediaType,
                    normalizedPath: resolved.path
                )
            )
        }

        return items
    }

    private static func parseSpine(
        root: DaisyXMLElement,
        manifest: [DaisyManifestItem],
        collector: DaisyDiagnosticCollector
    ) throws -> [DaisySpineItem] {
        guard let spineRoot = root.firstChild(named: "spine") else {
            try collector.record(
                DaisyDiagnostic(
                    severity: .error,
                    code: "opf.spine-missing",
                    message: "Spine element is missing from OPF."
                )
            )
            return []
        }

        let manifestIDs = Set(manifest.map(\.id))
        var spineItems: [DaisySpineItem] = []

        for itemRef in spineRoot.children(named: "itemref") {
            guard let idRef = itemRef.attributes["idref"] else {
                try collector.record(
                    DaisyDiagnostic(
                        severity: .error,
                        code: "opf.spine-item-missing-idref",
                        message: "Spine item is missing idref."
                    )
                )
                continue
            }

            if !manifestIDs.contains(idRef) {
                try collector.record(
                    DaisyDiagnostic(
                        severity: .error,
                        code: "opf.missing-spine-manifest-reference",
                        message: "Spine item references a missing manifest item.",
                        elementID: idRef
                    )
                )
            }

            let linear = itemRef.attributes["linear"]?.lowercased() != "no"
            spineItems.append(DaisySpineItem(idRef: idRef, linear: linear))
        }

        return spineItems
    }

    private static func resolveNCXPath(manifest: [DaisyManifestItem], tocID: String?) -> String? {
        if let tocID, let byID = manifest.first(where: { $0.id == tocID }) {
            return byID.normalizedPath
        }
        return manifest.first(where: { $0.mediaType == "application/x-dtbncx+xml" })?.normalizedPath
    }
}
