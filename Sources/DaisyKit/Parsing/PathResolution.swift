import Foundation

enum DaisyPathResolution {
    static func resolveHref(
        href: String,
        relativeTo baseDirectoryURL: URL,
        workspaceRootURL: URL
    ) -> DaisyResourceReference? {
        let sanitizedHref = href.replacingOccurrences(of: "\\", with: "/")
        let components = sanitizedHref.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        let pathPart = String(components.first ?? "")
        let fragment = components.count == 2 ? String(components[1]) : nil

        let resolvedURL: URL
        if pathPart.isEmpty {
            resolvedURL = baseDirectoryURL
        } else {
            resolvedURL = URL(fileURLWithPath: pathPart, relativeTo: baseDirectoryURL).standardizedFileURL
        }

        guard let relativePath = relativePath(from: workspaceRootURL, to: resolvedURL) else {
            return nil
        }

        return DaisyResourceReference(path: relativePath, fragment: fragment)
    }

    static func relativePath(from rootURL: URL, to fileURL: URL) -> String? {
        let standardizedRoot = rootURL.standardizedFileURL.path
        let standardizedFile = fileURL.standardizedFileURL.path
        guard standardizedFile.hasPrefix(standardizedRoot) else {
            return nil
        }

        var suffix = String(standardizedFile.dropFirst(standardizedRoot.count))
        if suffix.hasPrefix("/") {
            suffix.removeFirst()
        }
        return suffix
    }
}
