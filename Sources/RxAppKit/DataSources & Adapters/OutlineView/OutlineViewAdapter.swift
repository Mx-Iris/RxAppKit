import AppKit

public protocol OutlineNodeType {
    associatedtype NodeType = Self
    var parent: NodeType? { get }
    var children: [NodeType] { get }
}

extension OutlineNodeType {
    public var isExpandable: Bool {
        children.count > 0
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
        guard let node = item as? OutlineNode else { return rootNode.map { !$0.children.isEmpty } ?? false }
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
