//
//  Directory.swift
//  NSTableView
//
//  Created by JH on 2022/12/23.
//

import AppKit
import RxAppKit
import DifferenceKit

public struct Metadata: CustomDebugStringConvertible, Hashable, Differentiable {
    let name: String
    let date: Date
    let size: Int64
    let icon: NSImage
    let color: NSColor
    let isFolder: Bool
    let url: URL

    init(fileURL: URL, name: String, date: Date, size: Int64, icon: NSImage, isFolder: Bool, color: NSColor) {
        self.name = name
        self.date = date
        self.size = size
        self.icon = icon
        self.color = color
        self.isFolder = isFolder
        self.url = fileURL
    }

    public var debugDescription: String {
        return name + " " + "Folder: \(isFolder)" + " Size: \(size)"
    }
}

// MARK: Metadata  Equatable

public func == (lhs: Metadata, rhs: Metadata) -> Bool {
    return (lhs.url == rhs.url)
}

public struct Directory {
    fileprivate var files: [Metadata] = []
    let url: URL

    public enum FileOrder: String {
        case name
        case date
        case size
    }

    public init(folderURL: URL) {
        self.url = folderURL
        let requiredAttributes = [URLResourceKey.localizedNameKey, URLResourceKey.effectiveIconKey,
                                  URLResourceKey.typeIdentifierKey, URLResourceKey.contentModificationDateKey,
                                  URLResourceKey.fileSizeKey, URLResourceKey.isDirectoryKey,
                                  URLResourceKey.isPackageKey]
        if let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: requiredAttributes,
            options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants],
            errorHandler: nil
        ) {
            while let url = enumerator.nextObject() as? URL {
                print("\(url)")

                do {
                    let properties = try (url as NSURL).resourceValues(forKeys: requiredAttributes)
                    files.append(Metadata(
                        fileURL: url,
                        name: properties[URLResourceKey.localizedNameKey] as? String ?? "",
                        date: properties[URLResourceKey.contentModificationDateKey] as? Date ?? Date.distantPast,
                        size: (properties[URLResourceKey.fileSizeKey] as? NSNumber)?.int64Value ?? 0,
                        icon: properties[URLResourceKey.effectiveIconKey] as? NSImage ?? NSImage(),
                        isFolder: (properties[URLResourceKey.isDirectoryKey] as? NSNumber)?.boolValue ?? false,
                        color: NSColor()
                    ))
                } catch {
                    print("Error reading file attributes")
                }
            }
        }
    }

    func contentsOrderedBy(_ orderedBy: FileOrder, ascending: Bool) -> [Metadata] {
        let sortedFiles: [Metadata]
        switch orderedBy {
        case .name:
            sortedFiles = files.sorted {
                sortMetadata(
                    lhsIsFolder: true,
                    rhsIsFolder: true,
                    ascending: ascending,
                    attributeComparation: itemComparator(lhs: $0.name, rhs: $1.name, ascending: ascending)
                )
            }
        case .size:
            sortedFiles = files.sorted {
                sortMetadata(
                    lhsIsFolder: true,
                    rhsIsFolder: true,
                    ascending: ascending,
                    attributeComparation: itemComparator(lhs: $0.size, rhs: $1.size, ascending: ascending)
                )
            }
        case .date:
            sortedFiles = files.sorted {
                sortMetadata(
                    lhsIsFolder: true,
                    rhsIsFolder: true,
                    ascending: ascending,
                    attributeComparation: itemComparator(lhs: $0.date, rhs: $1.date, ascending: ascending)
                )
            }
        }
        return sortedFiles
    }
}

// MARK: - Sorting

func sortMetadata(
    lhsIsFolder: Bool,
    rhsIsFolder: Bool,
    ascending: Bool,
    attributeComparation: Bool
) -> Bool {
    if lhsIsFolder, !rhsIsFolder {
        return ascending ? true : false
    } else if !lhsIsFolder, rhsIsFolder {
        return ascending ? false : true
    }
    return attributeComparation
}

func itemComparator<T: Comparable>(lhs: T, rhs: T, ascending: Bool) -> Bool {
    return ascending ? (lhs < rhs) : (lhs > rhs)
}

public func == (lhs: Date, rhs: Date) -> Bool {
    if lhs.compare(rhs) == .orderedSame {
        return true
    }
    return false
}

public func < (lhs: Date, rhs: Date) -> Bool {
    if lhs.compare(rhs) == .orderedAscending {
        return true
    }
    return false
}
