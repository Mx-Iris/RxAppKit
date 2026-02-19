import Foundation
import XcodeProj
import RxAppKit
import AppKit

final class FileNode: OutlineNodeType, Hashable, Differentiable {
    private let fileElement: PBXFileElement

    var name: String? {
        fileElement.name ?? fileElement.path
    }

    var path: String? {
        fileElement.path
    }

    var icon: NSImage? {
        guard let path = path else { return nil }
        let url = URL(filePath: path)
        return try? url.resourceValues(forKeys: [.effectiveIconKey]).effectiveIcon as? NSImage
    }

    var parent: FileNode? {
        if let parent = fileElement.parent {
            return FileNode(fileElement: parent)
        } else {
            return nil
        }
    }

    private var _children: [FileNode]?

    var internalChildren: [FileNode] {
        get { children }
        set { _children = newValue }
    }

    var children: [FileNode] {
        if let cached = _children {
            return cached
        }
        let result: [FileNode]
        if let group = fileElement as? PBXGroup {
            result = group.children.map(FileNode.init(fileElement:))
        } else {
            result = []
        }
        _children = result
        return result
    }

    init(fileElement: PBXFileElement) {
        self.fileElement = fileElement
    }

    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        lhs.fileElement == rhs.fileElement
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(fileElement)
    }
}
