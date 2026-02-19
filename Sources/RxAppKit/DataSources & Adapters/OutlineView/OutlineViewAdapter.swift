import AppKit
import RxSwift
import RxCocoa

public protocol OutlineNodeType {
    var parent: Self? { get }
    var children: [Self] { get }
}

extension OutlineNodeType {
    public var isExpandable: Bool {
        children.count > 0
    }
}

/// Describes a move operation inside an outline view.
/// Paths are based on the outline state before the move is applied.
public struct OutlineMove: Equatable {
    /// The index path of the source parent item. `nil` means the root level.
    public let sourceParentPath: IndexPath?
    /// The indexes (within the source parent) of the moved items.
    public let sourceIndexes: IndexSet
    /// The index path of the destination parent item. `nil` means the root level.
    public let destinationParentPath: IndexPath?
    /// The destination index (within the destination parent) where the items are inserted.
    public let destinationIndex: Int
    /// Whether the drop was performed "on" an item (vs. between items).
    public let isDropOnItem: Bool

    public init(
        sourceParentPath: IndexPath?,
        sourceIndexes: IndexSet,
        destinationParentPath: IndexPath?,
        destinationIndex: Int,
        isDropOnItem: Bool
    ) {
        self.sourceParentPath = sourceParentPath
        self.sourceIndexes = sourceIndexes
        self.destinationParentPath = destinationParentPath
        self.destinationIndex = destinationIndex
        self.isDropOnItem = isDropOnItem
    }
}

open class OutlineViewAdapter<OutlineNode: OutlineNodeType>: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    public typealias ViewForItem = (NSOutlineView, NSTableColumn?, OutlineNode) -> NSView?
    public typealias RowForItem = (NSOutlineView, OutlineNode) -> NSTableRowView?

    public internal(set) var rootNode: OutlineNode?
    public internal(set) var nodes: [OutlineNode] = []

    open var viewForItem: ViewForItem
    open var rowForItem: RowForItem

    public init(viewForItem: @escaping ViewForItem, rowForItem: @escaping RowForItem = { _, _ in nil }) {
        self.viewForItem = viewForItem
        self.rowForItem = rowForItem
    }

    // MARK: - Data

    open func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? OutlineNode else {
            return rootNode != nil ? 1 : nodes.count
        }
        return node.children.count
    }

    open func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let node = item as? OutlineNode else {
            return rootNode ?? nodes[index]
        }
        return node.children[index]
    }

    open func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? OutlineNode else {
            return rootNode?.isExpandable ?? false
        }
        return node.isExpandable
    }

    // MARK: - View

    open func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? OutlineNode else { return nil }
        return viewForItem(outlineView, tableColumn, node)
    }

    open func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        guard let node = item as? OutlineNode else { return nil }
        return rowForItem(outlineView, node)
    }
}
