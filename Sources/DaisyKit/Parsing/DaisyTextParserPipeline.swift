// DaisyTextParserPipeline.swift
// DaisyKit

import Foundation

struct DaisyTextParserPipeline {
    private let options: DaisyParseOptions
    private let zipLimits: DaisyZipLimits

    init(options: DaisyParseOptions, zipLimits: DaisyZipLimits) {
        self.options = options
        self.zipLimits = zipLimits
    }

    func parse(at inputURL: URL) async throws -> DaisyTextParseReport {
        do {
            let baseReport = try await DaisyParserPipeline(options: options, zipLimits: zipLimits).parse(at: inputURL)
            let textPublication = mapTextPublication(from: baseReport)
            if !textPublication.lines.isEmpty {
                return DaisyTextParseReport(publication: textPublication, diagnostics: baseReport.diagnostics)
            }

            if options.mode == .lenient {
                if let fallback = try parseDTBookOnlyFallback(
                    at: inputURL,
                    preexistingDiagnostics: baseReport.diagnostics
                ) {
                    return fallback
                }
            }

            throw DaisyParseError(
                diagnostic: DaisyDiagnostic(
                    severity: .error,
                    code: "normalize.no-readable-text",
                    message: "No readable text was found in the DAISY publication."
                )
            )
        } catch let parseError as DaisyParseError {
            guard options.mode == .lenient, shouldAttemptDTBookOnlyFallback(for: parseError) else {
                throw parseError
            }

            if let fallback = try parseDTBookOnlyFallback(
                at: inputURL,
                preexistingDiagnostics: [parseError.diagnostic]
            ) {
                return fallback
            }

            throw parseError
        }
    }

    private func shouldAttemptDTBookOnlyFallback(for parseError: DaisyParseError) -> Bool {
        parseError.diagnostic.code == "io.opf-not-found"
    }

    private func parseDTBookOnlyFallback(
        at inputURL: URL,
        preexistingDiagnostics: [DaisyDiagnostic]
    ) throws -> DaisyTextParseReport? {
        let collector = DaisyDiagnosticCollector(mode: options.mode)
        let workspace = try DaisyWorkspaceResolver.resolveWorkspace(from: inputURL, limits: zipLimits)
        defer { workspace.cleanup() }

        let candidates = findDTBookCandidates(in: workspace.rootURL)
        guard !candidates.isEmpty else {
            return nil
        }

        var sections: [DaisySection] = []
        sections.reserveCapacity(candidates.count)

        var discoveredTitle: String?
        var discoveredLanguage: String?
        for candidate in candidates {
            let section = try DaisyDTBookParser.parseSection(
                dtbookURL: candidate.url,
                relativePath: candidate.relativePath,
                collector: collector
            )
            sections.append(section)

            if discoveredTitle == nil {
                discoveredTitle = candidate.title
            }
            if discoveredLanguage == nil {
                discoveredLanguage = candidate.language
            }
        }

        let metadata = DaisyMetadata(
            title: discoveredTitle,
            creator: nil,
            identifier: nil,
            language: discoveredLanguage
        )
        let publication = DaisyNormalizer.buildPublication(metadata: metadata, sections: sections)
        let raw = DaisyPublicationRaw(
            metadata: metadata,
            manifest: [],
            spine: [],
            navPoints: [],
            smilRefs: []
        )
        let fallbackDiagnostic = DaisyDiagnostic(
            severity: .info,
            code: "normalize.dtbook-fallback-used",
            message: "Recovered readable text by parsing DTBook files directly without OPF metadata."
        )
        var diagnostics = preexistingDiagnostics
        diagnostics.append(contentsOf: collector.diagnostics)
        diagnostics.append(fallbackDiagnostic)

        let fallbackReport = DaisyParseReport(raw: raw, publication: publication, diagnostics: diagnostics)
        let textPublication = mapTextPublication(from: fallbackReport)
        guard !textPublication.lines.isEmpty else {
            return nil
        }

        return DaisyTextParseReport(publication: textPublication, diagnostics: diagnostics)
    }

    private func findDTBookCandidates(in workspaceRootURL: URL) -> [DTBookCandidate] {
        guard let enumerator = FileManager.default.enumerator(
            at: workspaceRootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var candidates: [DTBookCandidate] = []
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "xml" else { continue }

            guard let root = try? DaisyXML.rootElement(at: fileURL) else {
                continue
            }

            let dtbookRoot = root.name == "dtbook" ? root : root.firstDescendant(named: "dtbook")
            guard let dtbookRoot else {
                continue
            }

            let relativePath = relativePath(from: workspaceRootURL, to: fileURL)
            let title = dtbookRoot.firstDescendant(named: "doctitle")?.textValue?.trimmedOrNil
            let language = dtbookRoot.attributes["lang"]?.trimmedOrNil
            candidates.append(
                DTBookCandidate(
                    url: fileURL.standardizedFileURL,
                    relativePath: relativePath,
                    title: title,
                    language: language
                )
            )
        }

        return candidates.sorted { $0.relativePath < $1.relativePath }
    }

    private func relativePath(from rootURL: URL, to fileURL: URL) -> String {
        let rootPath = rootURL.standardizedFileURL.path
        let filePath = fileURL.standardizedFileURL.path
        let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        guard filePath.hasPrefix(prefix) else {
            return fileURL.lastPathComponent
        }
        return String(filePath.dropFirst(prefix.count))
    }

    private func mapTextPublication(from report: DaisyParseReport) -> DaisyTextPublication {
        var lines: [String] = []
        var extractedHeadings: [DaisyTextHeading] = []
        var sectionStartByPath: [String: Int] = [:]
        var lineByAnchor: [String: Int] = [:]

        for section in report.publication.sections {
            let sourcePath = normalizedPath(section.sourcePath)
            sectionStartByPath[sourcePath] = lines.count

            let sectionTitle = sanitizedText(section.title)
            if !sectionTitle.isEmpty {
                let lineIndex = lines.count
                lines.append(sectionTitle)
                extractedHeadings.append(DaisyTextHeading(text: sectionTitle, level: 1, lineIndex: lineIndex))
            }

            for heading in section.headings {
                let headingText = sanitizedText(heading.text)
                guard !headingText.isEmpty else { continue }

                let lineIndex = lines.count
                let normalizedLevel = max(1, min(6, heading.level))
                lines.append(headingText)
                extractedHeadings.append(DaisyTextHeading(text: headingText, level: normalizedLevel, lineIndex: lineIndex))

                if let anchor = heading.anchor {
                    lineByAnchor[normalizedPath(anchor)] = lineIndex
                }
                if let headingID = heading.id {
                    lineByAnchor["\(sourcePath)#\(headingID)"] = lineIndex
                }
            }

            for paragraph in section.paragraphs {
                let paragraphText = sanitizedText(paragraph.text)
                guard !paragraphText.isEmpty else { continue }

                let lineIndex = lines.count
                lines.append(paragraphText)

                if let paragraphID = paragraph.id {
                    lineByAnchor["\(sourcePath)#\(paragraphID)"] = lineIndex
                }
            }
        }

        addFallbackHeadings(
            navPoints: report.raw.navPoints,
            sectionStartByPath: sectionStartByPath,
            lineByAnchor: lineByAnchor,
            headings: &extractedHeadings
        )

        let title = resolvedTitle(for: report.publication, metadata: report.raw.metadata)
        let language = report.raw.metadata.language?.trimmedOrNil
        let finalLines = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let finalHeadings = deduplicatedHeadings(extractedHeadings)
            .filter { $0.lineIndex >= 0 && $0.lineIndex < finalLines.count }

        return DaisyTextPublication(
            title: title,
            language: language,
            lines: finalLines,
            headings: finalHeadings
        )
    }

    private func addFallbackHeadings(
        navPoints: [DaisyNavPoint],
        sectionStartByPath: [String: Int],
        lineByAnchor: [String: Int],
        headings: inout [DaisyTextHeading]
    ) {
        guard !navPoints.isEmpty else { return }

        let flattenedNavPoints = flatten(navPoints: navPoints)
        var existingKeys = Set(headings.map { headingKey(text: $0.text, lineIndex: $0.lineIndex) })

        for navPoint in flattenedNavPoints {
            let label = sanitizedText(navPoint.label)
            guard !label.isEmpty else { continue }

            let normalizedSource = normalizedPath(navPoint.contentSource)
            let sourcePath = pathComponent(from: normalizedSource)
            guard let lineIndex = lineByAnchor[normalizedSource] ?? sectionStartByPath[sourcePath] else { continue }

            let key = headingKey(text: label, lineIndex: lineIndex)
            guard !existingKeys.contains(key) else { continue }

            headings.append(DaisyTextHeading(text: label, level: 2, lineIndex: lineIndex))
            existingKeys.insert(key)
        }
    }

    private func flatten(navPoints: [DaisyNavPoint]) -> [DaisyNavPoint] {
        var flattened: [DaisyNavPoint] = []
        for navPoint in navPoints {
            flattened.append(navPoint)
            flattened.append(contentsOf: flatten(navPoints: navPoint.children))
        }
        return flattened
    }

    private func deduplicatedHeadings(_ headings: [DaisyTextHeading]) -> [DaisyTextHeading] {
        guard !headings.isEmpty else { return [] }

        let sorted = headings.sorted {
            if $0.lineIndex != $1.lineIndex { return $0.lineIndex < $1.lineIndex }
            if $0.level != $1.level { return $0.level < $1.level }
            return $0.text < $1.text
        }

        var deduplicated: [DaisyTextHeading] = []
        for heading in sorted {
            if let previous = deduplicated.last {
                let previousText = normalizedValue(previous.text)
                let currentText = normalizedValue(heading.text)
                let sameText = !currentText.isEmpty && currentText == previousText
                let nearSameLine = abs(previous.lineIndex - heading.lineIndex) <= 1
                if sameText && nearSameLine {
                    continue
                }
            }
            deduplicated.append(heading)
        }

        return deduplicated
    }

    private func resolvedTitle(for publication: DaisyPublication, metadata: DaisyMetadata) -> String {
        let metadataTitle = metadata.title?.trimmedOrNil
        if let metadataTitle {
            return metadataTitle
        }

        let publicationTitle = publication.title.trimmedOrNil
        if let publicationTitle, normalizedValue(publicationTitle) != "untitled" {
            return publicationTitle
        }

        if let firstSectionTitle = publication.sections.compactMap(\.title).first?.trimmedOrNil {
            return firstSectionTitle
        }

        return "Untitled"
    }

    private func headingKey(text: String, lineIndex: Int) -> String {
        "\(lineIndex)|\(normalizedValue(text))"
    }

    private func normalizedPath(_ value: String) -> String {
        let normalizedSlashes = value.replacingOccurrences(of: "\\", with: "/")
        if normalizedSlashes.hasPrefix("./") {
            return String(normalizedSlashes.dropFirst(2))
        }
        return normalizedSlashes
    }

    private func pathComponent(from source: String) -> String {
        if let hashIndex = source.firstIndex(of: "#") {
            return String(source[..<hashIndex])
        }
        return source
    }

    private func normalizedValue(_ value: String) -> String {
        sanitizedText(value)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Self.normalizationLocale)
            .lowercased()
            .replacingOccurrences(of: #"[^\p{L}\p{N}\s]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sanitizedText(_ value: String?) -> String {
        guard let value else { return "" }
        return value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private static let normalizationLocale = Locale(identifier: "en_US_POSIX")
}

private struct DTBookCandidate: Sendable {
    let url: URL
    let relativePath: String
    let title: String?
    let language: String?
}
