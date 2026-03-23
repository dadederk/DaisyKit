import Foundation

struct DaisyParserPipeline {
    private let options: DaisyParseOptions
    private let zipLimits: DaisyZipLimits

    init(options: DaisyParseOptions, zipLimits: DaisyZipLimits) {
        self.options = options
        self.zipLimits = zipLimits
    }

    func parse(at inputURL: URL) async throws -> DaisyParseReport {
        let collector = DaisyDiagnosticCollector(mode: options.mode)
        let workspace = try DaisyWorkspaceResolver.resolveWorkspace(
            from: inputURL,
            limits: zipLimits
        )
        defer { workspace.cleanup() }

        let opfURL = try locateOPF(in: workspace.rootURL)
        let opfResult = try DaisyOPFParser.parse(
            opfURL: opfURL,
            workspaceRootURL: workspace.rootURL,
            collector: collector
        )

        let navPoints = try parseNCXIfAvailable(
            ncxPath: opfResult.ncxPath,
            workspaceRootURL: workspace.rootURL,
            collector: collector
        )

        let sections = try parseDTBookSections(
            dtbookPaths: opfResult.dtbookPaths,
            workspaceRootURL: workspace.rootURL,
            collector: collector
        )

        let smilRefs = try parseSmilRefs(
            smilPaths: opfResult.smilPaths,
            opfURL: opfURL,
            workspaceRootURL: workspace.rootURL,
            collector: collector
        )

        try DaisyNormalizer.validateSmilTargets(smilRefs: smilRefs, sections: sections, collector: collector)
        let publication = DaisyNormalizer.buildPublication(metadata: opfResult.metadata, sections: sections)
        let raw = DaisyPublicationRaw(
            metadata: opfResult.metadata,
            manifest: opfResult.manifest,
            spine: opfResult.spine,
            navPoints: navPoints,
            smilRefs: smilRefs
        )
        return DaisyParseReport(raw: raw, publication: publication, diagnostics: collector.diagnostics)
    }

    private func locateOPF(in rootURL: URL) throws -> URL {
        let opfURLs = fileURLs(withExtension: "opf", in: rootURL)
        guard let opfURL = opfURLs.first else {
            throw DaisyParseError(
                diagnostic: DaisyDiagnostic(
                    severity: .error,
                    code: "io.opf-not-found",
                    message: "No OPF file was found in the workspace.",
                    sourcePath: rootURL.path
                )
            )
        }
        return opfURL
    }

    private func parseNCXIfAvailable(
        ncxPath: String?,
        workspaceRootURL: URL,
        collector: DaisyDiagnosticCollector
    ) throws -> [DaisyNavPoint] {
        guard let ncxPath else {
            try collector.record(
                DaisyDiagnostic(
                    severity: .warning,
                    code: "ncx.missing-from-opf",
                    message: "No NCX item was referenced in OPF."
                )
            )
            return []
        }
        let ncxURL = workspaceRootURL.appendingPathComponent(ncxPath)
        guard FileManager.default.fileExists(atPath: ncxURL.path) else {
            try collector.record(
                DaisyDiagnostic(
                    severity: .error,
                    code: "ncx.file-missing",
                    message: "Referenced NCX file is missing.",
                    sourcePath: ncxPath
                )
            )
            return []
        }
        return try DaisyNCXParser.parse(ncxURL: ncxURL, collector: collector)
    }

    private func parseDTBookSections(
        dtbookPaths: [String],
        workspaceRootURL: URL,
        collector: DaisyDiagnosticCollector
    ) throws -> [DaisySection] {
        var sections: [DaisySection] = []
        for path in dtbookPaths {
            let dtbookURL = workspaceRootURL.appendingPathComponent(path)
            guard FileManager.default.fileExists(atPath: dtbookURL.path) else {
                try collector.record(
                    DaisyDiagnostic(
                        severity: .error,
                        code: "dtbook.file-missing",
                        message: "DTBook file referenced by OPF is missing.",
                        sourcePath: path
                    )
                )
                continue
            }

            let section = try DaisyDTBookParser.parseSection(
                dtbookURL: dtbookURL,
                relativePath: path,
                collector: collector
            )
            sections.append(section)
        }
        return sections
    }

    private func parseSmilRefs(
        smilPaths: [String],
        opfURL: URL,
        workspaceRootURL: URL,
        collector: DaisyDiagnosticCollector
    ) throws -> [DaisySmilRef] {
        var refs: [DaisySmilRef] = []
        let opfBaseDirectory = opfURL.deletingLastPathComponent()

        for path in smilPaths {
            let smilURL = workspaceRootURL.appendingPathComponent(path)
            guard FileManager.default.fileExists(atPath: smilURL.path) else {
                try collector.record(
                    DaisyDiagnostic(
                        severity: .warning,
                        code: "smil.file-missing",
                        message: "SMIL file referenced by OPF is missing.",
                        sourcePath: path
                    )
                )
                continue
            }

            let parsed = try DaisySMILParser.parseRefs(
                smilURL: smilURL,
                relativePath: path,
                opfBaseDirectory: opfBaseDirectory,
                workspaceRootURL: workspaceRootURL,
                collector: collector
            )
            refs.append(contentsOf: parsed)
        }

        return refs
    }

    private func fileURLs(withExtension expectedExtension: String, in rootURL: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var urls: [URL] = []
        for case let url as URL in enumerator {
            if url.pathExtension.lowercased() == expectedExtension.lowercased() {
                urls.append(url.standardizedFileURL)
            }
        }

        return urls.sorted { $0.path < $1.path }
    }
}
