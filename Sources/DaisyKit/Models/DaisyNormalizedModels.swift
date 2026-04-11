import Foundation

public struct DaisyPublication: Sendable, Equatable {
    public let title: String
    public let sections: [DaisySection]

    public init(title: String, sections: [DaisySection]) {
        self.title = title
        self.sections = sections
    }
}

/// The structural role of a section within a DTBook document.
///
/// DTBook defines three structural containers: `<frontmatter>` for preliminary material such as a table of contents,
/// preface, or dedication; `<bodymatter>` for the primary narrative or informational body; and `<rearmatter>` for
/// supplementary content such as indices or bibliographies. When none of these containers are present, the
/// section represents the full document content without explicit structural division.
public enum DaisySectionRole: Sendable, Equatable {
    /// Content from the `<frontmatter>` element — typically introductory or navigational material such as a
    /// table of contents, preface, or dedication.
    case frontmatter
    /// Content from the `<bodymatter>` element — the primary narrative or informational body of the publication.
    case bodymatter
    /// Content from the `<rearmatter>` element — supplementary content following the body, such as indices,
    /// glossaries, or bibliographies.
    case rearmatter
    /// Content collected from the full document when no structural `<frontmatter>`, `<bodymatter>`, or
    /// `<rearmatter>` elements were found.
    case fullDocument
}

public struct DaisySection: Sendable, Equatable {
    public let sourcePath: String
    public let title: String?
    public let paragraphs: [DaisyParagraph]
    public let headings: [DaisyHeading]
    public let anchors: [DaisyAnchor]
    /// The structural role this section plays within the source DTBook document.
    ///
    /// Consumers can use this to selectively process sections — for example, to skip `frontmatter` sections
    /// when building a reading-optimised text representation.
    public let role: DaisySectionRole

    public init(
        sourcePath: String,
        title: String?,
        paragraphs: [DaisyParagraph],
        headings: [DaisyHeading],
        anchors: [DaisyAnchor],
        role: DaisySectionRole = .fullDocument
    ) {
        self.sourcePath = sourcePath
        self.title = title
        self.paragraphs = paragraphs
        self.headings = headings
        self.anchors = anchors
        self.role = role
    }
}

public struct DaisyParagraph: Sendable, Equatable {
    public let id: String?
    public let text: String

    public init(id: String?, text: String) {
        self.id = id
        self.text = text
    }
}

public struct DaisyHeading: Sendable, Equatable {
    public let id: String?
    public let level: Int
    public let text: String
    public let anchor: String?

    public init(id: String?, level: Int, text: String, anchor: String?) {
        self.id = id
        self.level = level
        self.text = text
        self.anchor = anchor
    }
}

public struct DaisyAnchor: Sendable, Equatable {
    public let id: String
    public let href: String

    public init(id: String, href: String) {
        self.id = id
        self.href = href
    }
}
