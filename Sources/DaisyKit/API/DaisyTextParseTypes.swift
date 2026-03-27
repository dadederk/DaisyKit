// DaisyTextParseTypes.swift
// DaisyKit

import Foundation

public struct DaisyTextHeading: Sendable, Equatable {
    public let text: String
    public let level: Int
    public let lineIndex: Int

    public init(text: String, level: Int, lineIndex: Int) {
        self.text = text
        self.level = level
        self.lineIndex = lineIndex
    }
}

public struct DaisyTextPublication: Sendable, Equatable {
    public let title: String
    public let language: String?
    public let lines: [String]
    public let headings: [DaisyTextHeading]

    public init(
        title: String,
        language: String?,
        lines: [String],
        headings: [DaisyTextHeading]
    ) {
        self.title = title
        self.language = language
        self.lines = lines
        self.headings = headings
    }
}

public struct DaisyTextParseReport: Sendable, Equatable {
    public let publication: DaisyTextPublication
    public let diagnostics: [DaisyDiagnostic]

    public init(publication: DaisyTextPublication, diagnostics: [DaisyDiagnostic]) {
        self.publication = publication
        self.diagnostics = diagnostics
    }
}
