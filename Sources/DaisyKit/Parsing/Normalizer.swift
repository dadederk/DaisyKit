import Foundation

enum DaisyNormalizer {
    static func buildPublication(
        metadata: DaisyMetadata,
        sections: [DaisySection]
    ) -> DaisyPublication {
        DaisyLogger.normalize.info("🧱 Normalizing publication with \(sections.count, privacy: .public) sections")
        let title = metadata.title ?? sections.compactMap(\.title).first ?? "Untitled"
        return DaisyPublication(title: title, sections: sections)
    }

    static func validateSmilTargets(
        smilRefs: [DaisySmilRef],
        sections: [DaisySection],
        collector: DaisyDiagnosticCollector
    ) throws {
        let anchorSet = Set(
            sections.flatMap { section in
                section.anchors.map(\.href)
            }
        )

        for ref in smilRefs where !anchorSet.contains(ref.resolvedTextTarget) {
            try collector.record(
                DaisyDiagnostic(
                    severity: .warning,
                    code: "smil.unresolved-text-target",
                    message: "SMIL text target could not be resolved to a known anchor.",
                    sourcePath: ref.sourcePath,
                    elementID: ref.id
                )
            )
        }
    }
}
