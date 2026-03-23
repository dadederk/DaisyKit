import Foundation

struct DaisyXMLElement: Sendable {
    let name: String
    let attributes: [String: String]
    let children: [DaisyXMLElement]
    let textChunks: [String]

    var textValue: String? {
        let ownText = textChunks.joined()
        let childrenText = children.compactMap(\.textValue).joined(separator: " ")
        let combined = [ownText, childrenText]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " ")
        return combined.trimmedOrNil
    }

    func firstChild(named expectedName: String) -> DaisyXMLElement? {
        children.first { $0.name == expectedName }
    }

    func children(named expectedName: String) -> [DaisyXMLElement] {
        children.filter { $0.name == expectedName }
    }

    func firstDescendant(named expectedName: String) -> DaisyXMLElement? {
        if name == expectedName {
            return self
        }
        for child in children {
            if let match = child.firstDescendant(named: expectedName) {
                return match
            }
        }
        return nil
    }

    func descendants(named expectedName: String) -> [DaisyXMLElement] {
        var matches: [DaisyXMLElement] = []
        if name == expectedName {
            matches.append(self)
        }
        for child in children {
            matches.append(contentsOf: child.descendants(named: expectedName))
        }
        return matches
    }
}

enum DaisyXML {
    static func rootElement(at url: URL) throws -> DaisyXMLElement {
        let parserDelegate = DaisyXMLTreeBuilder()
        guard let parser = XMLParser(contentsOf: url) else {
            throw DaisyParseError(
                diagnostic: DaisyDiagnostic(
                    severity: .error,
                    code: "io.xml-open-failed",
                    message: "XML file could not be opened.",
                    sourcePath: url.lastPathComponent
                )
            )
        }
        parser.delegate = parserDelegate
        parser.shouldResolveExternalEntities = false

        if parser.parse(), let root = parserDelegate.root {
            return root
        }

        throw DaisyParseError(
            diagnostic: DaisyDiagnostic(
                severity: .error,
                code: "io.xml-parse-failed",
                message: parser.parserError?.localizedDescription ?? "XML parse failed.",
                sourcePath: url.lastPathComponent
            )
        )
    }
}

private final class DaisyXMLTreeBuilder: NSObject, XMLParserDelegate {
    private final class MutableNode {
        let name: String
        let attributes: [String: String]
        var children: [MutableNode] = []
        var textChunks: [String] = []
        
        init(name: String, attributes: [String: String]) {
            self.name = name
            self.attributes = attributes
        }
    }

    private var stack: [MutableNode] = []
    private(set) var root: DaisyXMLElement?

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        let normalizedName = localName(from: qName ?? elementName)
        let normalizedAttributes = Dictionary(
            uniqueKeysWithValues: attributeDict.map { key, value in
                (localName(from: key), value)
            }
        )
        let node = MutableNode(name: normalizedName, attributes: normalizedAttributes)
        stack.last?.children.append(node)
        stack.append(node)
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        stack.last?.textChunks.append(string)
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard let finished = stack.popLast() else { return }
        if stack.isEmpty {
            root = freeze(node: finished)
        }
    }

    private func freeze(node: MutableNode) -> DaisyXMLElement {
        DaisyXMLElement(
            name: node.name,
            attributes: node.attributes,
            children: node.children.map(freeze),
            textChunks: node.textChunks
        )
    }

    private func localName(from qualified: String) -> String {
        qualified.split(separator: ":").last.map { String($0).lowercased() } ?? qualified.lowercased()
    }
}

extension String {
    var trimmedOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
