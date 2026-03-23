import Foundation

public enum DaisyDiagnosticSeverity: String, Sendable, Equatable, CaseIterable {
    case error
    case warning
    case info
}

public struct DaisyDiagnostic: Sendable, Equatable {
    public let severity: DaisyDiagnosticSeverity
    public let code: String
    public let message: String
    public let sourcePath: String?
    public let elementID: String?

    public init(
        severity: DaisyDiagnosticSeverity,
        code: String,
        message: String,
        sourcePath: String? = nil,
        elementID: String? = nil
    ) {
        self.severity = severity
        self.code = code
        self.message = message
        self.sourcePath = sourcePath
        self.elementID = elementID
    }
}

public struct DaisyParseError: Error, Sendable, Equatable {
    public let diagnostic: DaisyDiagnostic

    public init(diagnostic: DaisyDiagnostic) {
        self.diagnostic = diagnostic
    }
}
