import Foundation
import ZIPFoundation

enum DaisyWorkspaceResolver {
    static func resolveWorkspace(
        from inputURL: URL,
        limits: DaisyZipLimits
    ) throws -> DaisyWorkspace {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: inputURL.path, isDirectory: &isDirectory) else {
            throw DaisyParseError(
                diagnostic: DaisyDiagnostic(
                    severity: .error,
                    code: "resolver.input-not-found",
                    message: "Input URL does not exist.",
                    sourcePath: inputURL.path
                )
            )
        }

        if isDirectory.boolValue {
            DaisyLogger.resolver.info("📦 Using directory workspace: \(inputURL.path, privacy: .public)")
            return DaisyWorkspace(rootURL: inputURL.standardizedFileURL, cleanup: {})
        }

        guard inputURL.pathExtension.lowercased() == "zip" else {
            throw DaisyParseError(
                diagnostic: DaisyDiagnostic(
                    severity: .error,
                    code: "resolver.unsupported-input",
                    message: "Only directory and .zip URLs are supported.",
                    sourcePath: inputURL.lastPathComponent
                )
            )
        }

        let extractionRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("daisykit-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: extractionRoot, withIntermediateDirectories: true)
        DaisyLogger.resolver.info("📦 Extracting ZIP input: \(inputURL.path, privacy: .public)")

        do {
            try extractZip(inputURL: inputURL, destination: extractionRoot, limits: limits)
            return DaisyWorkspace(rootURL: extractionRoot, cleanup: {
                try? FileManager.default.removeItem(at: extractionRoot)
            })
        } catch {
            try? FileManager.default.removeItem(at: extractionRoot)
            throw error
        }
    }

    private static func extractZip(
        inputURL: URL,
        destination: URL,
        limits: DaisyZipLimits
    ) throws {
        let archive: Archive
        do {
            archive = try Archive(url: inputURL, accessMode: .read)
        } catch {
            throw DaisyParseError(
                diagnostic: DaisyDiagnostic(
                    severity: .error,
                    code: "resolver.invalid-zip",
                    message: "ZIP archive cannot be opened.",
                    sourcePath: inputURL.lastPathComponent
                )
            )
        }

        var entryCount = 0
        var totalUncompressedSize: UInt64 = 0

        for entry in archive {
            entryCount += 1
            if entryCount > limits.maxEntries {
                throw DaisyParseError(
                    diagnostic: DaisyDiagnostic(
                        severity: .error,
                        code: "resolver.zip-entry-limit-exceeded",
                        message: "ZIP contains too many entries.",
                        sourcePath: inputURL.lastPathComponent
                    )
                )
            }

            let entrySize = UInt64(entry.uncompressedSize)
            if entrySize > limits.maxEntrySize {
                throw DaisyParseError(
                    diagnostic: DaisyDiagnostic(
                        severity: .error,
                        code: "resolver.zip-entry-size-limit-exceeded",
                        message: "A ZIP entry exceeds the maximum allowed uncompressed size.",
                        sourcePath: entry.path
                    )
                )
            }

            totalUncompressedSize += entrySize
            if totalUncompressedSize > limits.maxTotalUncompressedSize {
                throw DaisyParseError(
                    diagnostic: DaisyDiagnostic(
                        severity: .error,
                        code: "resolver.zip-total-size-limit-exceeded",
                        message: "ZIP total uncompressed size exceeds the allowed limit.",
                        sourcePath: inputURL.lastPathComponent
                    )
                )
            }

            let normalizedEntryPath = entry.path.replacingOccurrences(of: "\\", with: "/")
            guard let safeRelativePath = safeRelativePath(from: normalizedEntryPath) else {
                throw DaisyParseError(
                    diagnostic: DaisyDiagnostic(
                        severity: .error,
                        code: "resolver.zip-unsafe-entry-path",
                        message: "ZIP contains an unsafe entry path.",
                        sourcePath: entry.path
                    )
                )
            }

            let entryDestination = destination.appendingPathComponent(safeRelativePath)
            let destinationPath = entryDestination.standardizedFileURL.path
            let rootPath = destination.standardizedFileURL.path
            guard destinationPath.hasPrefix(rootPath) else {
                throw DaisyParseError(
                    diagnostic: DaisyDiagnostic(
                        severity: .error,
                        code: "resolver.zip-path-traversal-blocked",
                        message: "ZIP entry attempted to escape extraction root.",
                        sourcePath: entry.path
                    )
                )
            }

            if entry.type == .directory {
                try FileManager.default.createDirectory(at: entryDestination, withIntermediateDirectories: true)
                continue
            }

            let parentDirectory = entryDestination.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
            _ = try archive.extract(entry, to: entryDestination)
        }

        DaisyLogger.resolver.notice("📦 ZIP extracted with \(entryCount, privacy: .public) entries")
    }

    private static func safeRelativePath(from entryPath: String) -> String? {
        if entryPath.hasPrefix("/") || entryPath.hasPrefix("~") {
            return nil
        }

        let parts = entryPath.split(separator: "/", omittingEmptySubsequences: true)
        if parts.isEmpty {
            return nil
        }

        var normalizedParts: [String] = []
        for part in parts {
            if part == "." {
                continue
            }
            if part == ".." {
                return nil
            }
            normalizedParts.append(String(part))
        }

        guard !normalizedParts.isEmpty else {
            return nil
        }
        return normalizedParts.joined(separator: "/")
    }
}
