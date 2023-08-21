//
//  FileSystemNode.swift
//  NSBrowser-Demo
//
//  Created by JH on 2023/5/3.
//

import AppKit
import RxAppKit
import CoreServices

class FileSystemNode: BrowserNodeType {
    typealias NodeType = FileSystemNode

    let url: URL

    private var childrenDirty: Bool = false

    private var internalChildren: [FileSystemNode] = []

    static var rootNode: FileSystemNode { .init(url: URL(filePath: NSOpenStepRootDirectory())) }

    init(url: URL) {
        self.url = url
    }

    var children: [FileSystemNode] {
        if internalChildren.isEmpty || childrenDirty {
            var newChildren: [FileSystemNode] = []
            if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]) {
                while let url = enumerator.nextObject() as? URL {
                    newChildren.append(.init(url: url))
                }
            }
            childrenDirty = false
            internalChildren = newChildren.sorted()
        }
        return internalChildren
    }

    var isLeaf: Bool {
        !isDirectory || isPackage
    }

    var title: String {
        var displayName = ""
        if let localizedName = try? url.resourceValues(forKeys: [.localizedNameKey]).localizedName {
            displayName = localizedName
        } else if let name = try? url.resourceValues(forKeys: [.nameKey]).name {
            displayName = name
        }
        return displayName
    }

    var icon: NSImage? {
        try? url.resourceValues(forKeys: [.effectiveIconKey]).effectiveIcon as? NSImage
    }

    var documentKind: String? {
        try? url.resourceValues(forKeys: [.localizedTypeDescriptionKey]).localizedTypeDescription
    }

    var creationDate: Date? {
        try? url.resourceValues(forKeys: [.creationDateKey]).creationDate
    }

    var modificationDate: Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    var lastOpened: Date? {
        let item = MDItemCreateWithURL(nil, url as CFURL)
        let lastOpenedDate = MDItemCopyAttribute(item, kMDItemLastUsedDate) as? Date
        return lastOpenedDate
    }

    var size: Int {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    }

    var formattedFileSize: String {
        ByteCountFormatter().string(fromByteCount: .init(size))
    }

    var isDirectory: Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }

    var isPackage: Bool {
        (try? url.resourceValues(forKeys: [.isPackageKey]).isPackage) ?? false
    }

    var labelColor: NSColor? {
        try? url.resourceValues(forKeys: [.labelColorKey]).labelColor
    }

    func invalidateChildren() {
        childrenDirty = true
        internalChildren.forEach { $0.invalidateChildren() }
    }
}

extension FileSystemNode: Comparable {
    static func < (lhs: FileSystemNode, rhs: FileSystemNode) -> Bool {
        lhs.title < rhs.title
    }

    static func == (lhs: FileSystemNode, rhs: FileSystemNode) -> Bool {
        lhs.url == rhs.url
    }
}
