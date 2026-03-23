import Foundation

public enum DaisyParseMode: Sendable {
    case strict
    case lenient
}

public struct DaisyParseOptions: Sendable {
    public var mode: DaisyParseMode

    public init(mode: DaisyParseMode = .lenient) {
        self.mode = mode
    }
}

public struct DaisyParseReport: Sendable, Equatable {
    public let raw: DaisyPublicationRaw
    public let publication: DaisyPublication
    public let diagnostics: [DaisyDiagnostic]

    public init(
        raw: DaisyPublicationRaw,
        publication: DaisyPublication,
        diagnostics: [DaisyDiagnostic]
    ) {
        self.raw = raw
        self.publication = publication
        self.diagnostics = diagnostics
    }
}
