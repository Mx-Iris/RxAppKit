//
//  OutlineViewDataSource.swift
//
//
//  Created by JH on 2023/5/7.
//

import AppKit

public protocol OutlineNodeType {
    associatedtype NodeType = Self
    var parent: NodeType? { get }
    var children: [NodeType] { get }
    var isExpandable: Bool { get }
}

public extension OutlineNodeType {
    var isExpandable: Bool {
        children.count > 0
    }
}

class OutlineViewAdapter<OutlineNode: OutlineNodeType>: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    /// Re-targeting API for drag-n-drop.
    public struct ProposedDrop {
        /// Dropping type.
        public enum `Type` {
            case on
            case before
            case after
        }

        /// Dropping type.
        public var type: Type

        /// Target item.
        public var targetNode: OutlineNode

        /// Items being dragged.
        public var draggedNodes: [OutlineNode]

        /// Proposed operation.
        public var operation: NSDragOperation
    }

    typealias ViewForItem = (NSOutlineView, NSTableColumn?, OutlineNode) -> NSView?

    typealias RowForItem = (NSOutlineView, OutlineNode) -> NSTableRowView?

    typealias ValidateDrop = (NSOutlineView, ProposedDrop) -> ProposedDrop?

    typealias AcceptDrop = (NSOutlineView, ProposedDrop) -> Bool

    public internal(set) var nodes: [OutlineNode] = []

    var viewForItem: ViewForItem

    var rowForItem: RowForItem

    var validateDrop: ValidateDrop?

    var acceptDrop: AcceptDrop?

    init(viewForItem: @escaping ViewForItem, rowForItem: @escaping RowForItem = { _, _ in nil }) {
        self.viewForItem = viewForItem
        self.rowForItem = rowForItem
    }

    // MARK: - Data

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? OutlineNode else {
            return nodes.count
        }
        return node.children.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let node = item as? OutlineNode else {
            return nodes[index]
        }
        return node.children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? OutlineNode else { return false }
        return node.isExpandable
    }

    // MARK: - View

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? OutlineNode else { return nil }
        return viewForItem(outlineView, tableColumn, node)
    }

    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        guard let node = item as? OutlineNode else { return nil }
        return rowForItem(outlineView, node)
    }

    // MARK: - Drag Drop

    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        NSPasteboardItem(pasteboardPropertyList: outlineView.row(forItem: item), ofType: .OutlineViewAdapter.row)
    }

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        // Calculate proposed change if allowed and take decision from the client handler
        guard let proposedDrop = proposedDrop(outlineView, using: info, proposedItem: item, proposedChildIndex: index),
              let validateDrop, let drop = validateDrop(outlineView, proposedDrop) else { return [] }
        switch drop.type {
        // Re-target drop on item
        case .on:
            if drop.operation.isEmpty == false {
                outlineView.setDropItem(drop.targetNode, dropChildIndex: NSOutlineViewDropOnItemIndex)
            }
            return drop.operation

        // Re-target drop before item
        case .before:
            if drop.operation.isEmpty == false {
                let childIndex = outlineView.childIndex(forItem: drop.targetNode)
                let parentItem = outlineView.parent(forItem: drop.targetNode)
                outlineView.setDropItem(parentItem, dropChildIndex: childIndex)
            }
            return drop.operation

        // Re-target drop after item
        case .after:
            if drop.operation.isEmpty == false {
                let childIndex = outlineView.childIndex(forItem: drop.targetNode)
                let parentItem = outlineView.parent(forItem: drop.targetNode)
                outlineView.setDropItem(parentItem, dropChildIndex: childIndex + 1)
            }
            return drop.operation
        }
    }

    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        guard let proposedDrop = proposedDrop(outlineView, using: info, proposedItem: item, proposedChildIndex: index),
              let acceptDrop
        else { return false }
        return acceptDrop(outlineView, proposedDrop)
    }
}

private extension OutlineViewAdapter {
    func proposedDrop(_ outlineView: NSOutlineView, using info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> ProposedDrop? {
        guard let pasteboardItems = info.draggingPasteboard.pasteboardItems,
              pasteboardItems.isEmpty == false else { return nil }

        // Retrieve dragged items
        let draggedItems: [OutlineNode] = pasteboardItems.compactMap { pasteboardItem in
            guard let row = pasteboardItem.propertyList(forType: .OutlineViewAdapter.row) as? Int,
                  let node = outlineView.item(atRow: row) as? OutlineNode else { return nil }
            return node
        }
        guard draggedItems.count == pasteboardItems.count else { return nil }

        // Drop on the item
        let parentItem = item as? OutlineNode
        if index == NSOutlineViewDropOnItemIndex {
            return parentItem.map { .init(type: .on, targetNode: $0, draggedNodes: draggedItems, operation: info.draggingSourceOperationMask) }
        }

        // Drop into the item

        guard outlineView.numberOfChildren(ofItem: parentItem) == 0 else { return nil }

        // Use “before” or “after” depending on index
        return index > 0
            ? (outlineView.child(index - 1, ofItem: parentItem) as? OutlineNode).map { ProposedDrop(type: .after, targetNode: $0, draggedNodes: draggedItems, operation: info.draggingSourceOperationMask) }
            : (outlineView.child(index, ofItem: parentItem) as? OutlineNode).map { ProposedDrop(type: .before, targetNode: $0, draggedNodes: draggedItems, operation: info.draggingSourceOperationMask) }
    }
}

extension NSPasteboard.PasteboardType {
    enum OutlineViewAdapter {
        static let row: NSPasteboard.PasteboardType = .init("OutlineViewAdapter.Row")
    }
}
