import Foundation
import Testing
@testable import DaisyKit

@Suite("Path Resolution Unit")
struct PathResolutionUnitTests {
    @Test("Given dot segments when resolving href then path is normalized relative to OPF base")
    func test_givenDotSegments_whenResolvingHref_thenPathIsNormalizedRelativeToOPFBase() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("daisykit-path-root-\(UUID().uuidString)", isDirectory: true)
        let base = root.appendingPathComponent("OPS", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { TestFixtureBuilder.removeIfPresent(root) }

        let resolved = DaisyPathResolution.resolveHref(
            href: "./text/../chapter1.xml#p1",
            relativeTo: base,
            workspaceRootURL: root
        )

        #expect(resolved?.path == "OPS/chapter1.xml")
        #expect(resolved?.fragment == "p1")
        #expect(resolved?.pathWithFragment == "OPS/chapter1.xml#p1")
    }

    @Test("Given backslash separators when resolving href then separators are normalized")
    func test_givenBackslashSeparators_whenResolvingHref_thenSeparatorsAreNormalized() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("daisykit-path-root-\(UUID().uuidString)", isDirectory: true)
        let base = root.appendingPathComponent("OPS", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { TestFixtureBuilder.removeIfPresent(root) }

        let resolved = DaisyPathResolution.resolveHref(
            href: "text\\chapter1.xml#p2",
            relativeTo: base,
            workspaceRootURL: root
        )

        #expect(resolved?.path == "OPS/text/chapter1.xml")
        #expect(resolved?.fragment == "p2")
    }

    @Test("Given fragment-only href when resolving then base directory is preserved")
    func test_givenFragmentOnlyHref_whenResolving_thenBaseDirectoryIsPreserved() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("daisykit-path-root-\(UUID().uuidString)", isDirectory: true)
        let base = root.appendingPathComponent("OPS", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { TestFixtureBuilder.removeIfPresent(root) }

        let resolved = DaisyPathResolution.resolveHref(
            href: "#frag-only",
            relativeTo: base,
            workspaceRootURL: root
        )

        #expect(resolved?.path == "OPS")
        #expect(resolved?.fragment == "frag-only")
    }

    @Test("Given href escaping workspace when resolving then nil is returned")
    func test_givenHrefEscapingWorkspace_whenResolving_thenNilIsReturned() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("daisykit-path-root-\(UUID().uuidString)", isDirectory: true)
        let base = root.appendingPathComponent("OPS", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { TestFixtureBuilder.removeIfPresent(root) }

        let resolved = DaisyPathResolution.resolveHref(
            href: "../../outside.xml",
            relativeTo: base,
            workspaceRootURL: root
        )

        #expect(resolved == nil)
    }

    @Test("Given root and file URL when deriving relative path then canonical relative path is returned")
    func test_givenRootAndFileURL_whenDerivingRelativePath_thenCanonicalRelativePathIsReturned() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("daisykit-path-root-\(UUID().uuidString)", isDirectory: true)
        let nested = root.appendingPathComponent("OPS/text/chapter1.xml")
        try FileManager.default.createDirectory(at: nested.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: nested)
        defer { TestFixtureBuilder.removeIfPresent(root) }

        let relative = DaisyPathResolution.relativePath(from: root, to: nested)
        #expect(relative == "OPS/text/chapter1.xml")
    }
}
