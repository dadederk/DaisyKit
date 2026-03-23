import Foundation

public struct DaisyPublication: Sendable, Equatable {
    public let title: String
    public let sections: [DaisySection]

    public init(title: String, sections: [DaisySection]) {
        self.title = title
        self.sections = sections
    }
}

public struct DaisySection: Sendable, Equatable {
    public let sourcePath: String
    public let title: String?
    public let paragraphs: [DaisyParagraph]
    public let headings: [DaisyHeading]
    public let anchors: [DaisyAnchor]

    public init(
        sourcePath: String,
        title: String?,
        paragraphs: [DaisyParagraph],
        headings: [DaisyHeading],
        anchors: [DaisyAnchor]
    ) {
        self.sourcePath = sourcePath
        self.title = title
        self.paragraphs = paragraphs
        self.headings = headings
        self.anchors = anchors
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
