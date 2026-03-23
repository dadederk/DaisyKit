import Foundation
import OSLog

struct DaisyZipLimits: Sendable {
    let maxEntries: Int
    let maxEntrySize: UInt64
    let maxTotalUncompressedSize: UInt64

    static let v1Defaults = DaisyZipLimits(
        maxEntries: 20_000,
        maxEntrySize: 25 * 1_024 * 1_024,
        maxTotalUncompressedSize: 250 * 1_024 * 1_024
    )
}

struct DaisyResourceReference: Sendable {
    let path: String
    let fragment: String?

    var pathWithFragment: String {
        guard let fragment else { return path }
        return "\(path)#\(fragment)"
    }
}

struct DaisyWorkspace {
    let rootURL: URL
    let cleanup: @Sendable () -> Void
}

final class DaisyDiagnosticCollector {
    private let mode: DaisyParseMode
    private(set) var diagnostics: [DaisyDiagnostic] = []

    init(mode: DaisyParseMode) {
        self.mode = mode
    }

    func record(_ diagnostic: DaisyDiagnostic) throws {
        diagnostics.append(diagnostic)
        DaisyLogger.diagnostics.log(level: level(for: diagnostic.severity), "⚠️ \(diagnostic.code, privacy: .public): \(diagnostic.message, privacy: .public)")
        if mode == .strict, diagnostic.severity == .error {
            throw DaisyParseError(diagnostic: diagnostic)
        }
    }

    private func level(for severity: DaisyDiagnosticSeverity) -> OSLogType {
        switch severity {
        case .error:
            return .error
        case .warning:
            return .default
        case .info:
            return .info
        }
    }
}
