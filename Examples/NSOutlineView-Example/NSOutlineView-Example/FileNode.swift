//
//  FileNode.swift
//  SourceTree
//
//  Created by JH on 2023/5/10.
//

import Foundation
import XcodeProj
import RxAppKit
import AppKit

class FileNode: OutlineNodeType, Hashable, Differentiable {
    private let fileElement: PBXFileElement

    var name: String? { fileElement.name }

    var path: String? { fileElement.path }
    
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
    var internalChildren: [FileNode] = []
    
    var childrenDirty: Bool = false
    
    var children: [FileNode] {
        if internalChildren.isEmpty || childrenDirty {
            if let group = fileElement as? PBXGroup {
                internalChildren = group.children.map(FileNode.init(fileElement:))
            } else {
                internalChildren = []
            }
        }
        return internalChildren
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
