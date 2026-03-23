import Foundation

public struct DaisyPublicationRaw: Sendable, Equatable {
    public let metadata: DaisyMetadata
    public let manifest: [DaisyManifestItem]
    public let spine: [DaisySpineItem]
    public let navPoints: [DaisyNavPoint]
    public let smilRefs: [DaisySmilRef]

    public init(
        metadata: DaisyMetadata,
        manifest: [DaisyManifestItem],
        spine: [DaisySpineItem],
        navPoints: [DaisyNavPoint],
        smilRefs: [DaisySmilRef]
    ) {
        self.metadata = metadata
        self.manifest = manifest
        self.spine = spine
        self.navPoints = navPoints
        self.smilRefs = smilRefs
    }
}

public struct DaisyMetadata: Sendable, Equatable {
    public let title: String?
    public let creator: String?
    public let identifier: String?
    public let language: String?

    public init(title: String?, creator: String?, identifier: String?, language: String?) {
        self.title = title
        self.creator = creator
        self.identifier = identifier
        self.language = language
    }
}

public struct DaisyManifestItem: Sendable, Equatable {
    public let id: String
    public let href: String
    public let mediaType: String
    public let normalizedPath: String

    public init(id: String, href: String, mediaType: String, normalizedPath: String) {
        self.id = id
        self.href = href
        self.mediaType = mediaType
        self.normalizedPath = normalizedPath
    }
}

public struct DaisySpineItem: Sendable, Equatable {
    public let idRef: String
    public let linear: Bool

    public init(idRef: String, linear: Bool) {
        self.idRef = idRef
        self.linear = linear
    }
}

public struct DaisyNavPoint: Sendable, Equatable {
    public let id: String?
    public let playOrder: Int?
    public let label: String
    public let contentSource: String
    public let children: [DaisyNavPoint]

    public init(
        id: String?,
        playOrder: Int?,
        label: String,
        contentSource: String,
        children: [DaisyNavPoint]
    ) {
        self.id = id
        self.playOrder = playOrder
        self.label = label
        self.contentSource = contentSource
        self.children = children
    }
}

public struct DaisySmilRef: Sendable, Equatable {
    public let id: String?
    public let sourcePath: String
    public let textTarget: String
    public let resolvedTextTarget: String
    public let audioSource: String?

    public init(
        id: String?,
        sourcePath: String,
        textTarget: String,
        resolvedTextTarget: String,
        audioSource: String?
    ) {
        self.id = id
        self.sourcePath = sourcePath
        self.textTarget = textTarget
        self.resolvedTextTarget = resolvedTextTarget
        self.audioSource = audioSource
    }
}
