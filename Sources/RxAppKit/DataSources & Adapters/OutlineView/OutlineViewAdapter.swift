import AppKit
import RxSwift
import RxCocoa

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

open class OutlineViewAdapter<OutlineNode: OutlineNodeType>: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, ReorderableOutlineViewAdapter, _ItemMovedEventEmitting {
    public typealias ViewForItem = (NSOutlineView, NSTableColumn?, OutlineNode) -> NSView?
    public typealias RowForItem = (NSOutlineView, OutlineNode) -> NSTableRowView?

    public internal(set) var rootNode: OutlineNode?
    public internal(set) var nodes: [OutlineNode] = []

    open var viewForItem: ViewForItem
    open var rowForItem: RowForItem

    // MARK: - Reordering

    /// Handlers that control drag-and-drop reordering behavior for root-level nodes.
    public struct ReorderingHandlers {
        /// Return the items that are allowed to be reordered (filter from the proposed items).
        /// Return an empty array to deny the drag. When `nil`, all items are allowed.
        public var canReorder: ((_ items: [OutlineNode]) -> [OutlineNode])?
        /// Called before items are moved in the data source.
        public var willReorder: ((_ items: [OutlineNode], _ newIndex: Int) -> Void)?
        /// Called after items have been moved. Provides the new complete root-level nodes array.
        /// In Rx usage, update your upstream data source here to stay in sync.
        public var didReorder: ((_ nodes: [OutlineNode]) -> Void)?

        public init() {}
    }

    open var reorderingHandlers = ReorderingHandlers()

    let _itemMoved = PublishSubject<(sourceIndexes: IndexSet, destinationIndex: Int)>()
    let _modelMoved = PublishSubject<[Any]>()

    private static var reorderPasteboardType: NSPasteboard.PasteboardType {
        NSPasteboard.PasteboardType("com.RxAppKit.OutlineViewAdapter.reorder")
    }

    private var draggingChildIndexes: IndexSet = []
    private var isReorderingRegistered = false

    /// Register the outline view for internal drag-and-drop reordering.
    /// Called automatically by `rx.reorderableNodes(adapter:)` when using Rx bindings.
    open func setupReordering(for outlineView: NSOutlineView) {
        guard !isReorderingRegistered else { return }
        isReorderingRegistered = true
        outlineView.registerForDraggedTypes([Self.reorderPasteboardType])
        outlineView.setDraggingSourceOperationMask(.move, forLocal: true)
    }

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

    // MARK: - Drag & Drop Data Source

    open func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> (any NSPasteboardWriting)? {
        guard reorderingHandlers.canReorder != nil else { return nil }
        // Only allow dragging root-level items (not in rootNode mode)
        guard rootNode == nil, outlineView.parent(forItem: item) == nil else { return nil }
        let pbItem = NSPasteboardItem()
        let childIndex = outlineView.childIndex(forItem: item)
        pbItem.setString(String(childIndex), forType: Self.reorderPasteboardType)
        return pbItem
    }

    open func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        // Only accept drops at root level (item == nil), between items (not on an item)
        guard !draggingChildIndexes.isEmpty else { return [] }
        guard item == nil, index != NSOutlineViewDropOnItemIndex else { return [] }
        guard info.draggingSource as? NSOutlineView === outlineView else { return [] }
        return .move
    }

    open func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex: Int) -> Bool {
        guard !draggingChildIndexes.isEmpty else { return false }

        let draggedNodes = draggingChildIndexes.map { nodes[$0] }
        let sortedIndexes = draggingChildIndexes.sorted(by: >)

        // Calculate the target index after removing dragged items
        var targetIndex = childIndex
        for index in sortedIndexes {
            if index < targetIndex {
                targetIndex -= 1
            }
        }

        reorderingHandlers.willReorder?(draggedNodes, targetIndex)

        // Remove dragged items (from high to low to preserve indices)
        for index in sortedIndexes {
            nodes.remove(at: index)
        }

        // Insert at target position
        for (offset, node) in draggedNodes.enumerated() {
            nodes.insert(node, at: targetIndex + offset)
        }

        // Animate moves
        outlineView.beginUpdates()
        var oldOffset = 0
        let sortedAscending = draggingChildIndexes.sorted()
        for (moveOffset, oldIndex) in sortedAscending.enumerated() {
            let adjustedTarget = targetIndex + moveOffset
            outlineView.moveItem(at: oldIndex - oldOffset, inParent: nil, to: adjustedTarget, inParent: nil)
            if oldIndex < targetIndex {
                oldOffset += 1
            }
        }
        outlineView.endUpdates()

        reorderingHandlers.didReorder?(nodes)
        _itemMoved.onNext((sourceIndexes: draggingChildIndexes, destinationIndex: targetIndex))
        _modelMoved.onNext(nodes.map { $0 as Any })
        draggingChildIndexes = []
        return true
    }

    open func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
        let draggedNodes = draggedItems.compactMap { $0 as? OutlineNode }

        var allowedNodes = draggedNodes
        if let canReorder = reorderingHandlers.canReorder {
            allowedNodes = canReorder(draggedNodes)
        }

        if allowedNodes.isEmpty {
            draggingChildIndexes = []
            session.animatesToStartingPositionsOnCancelOrFail = true
        } else {
            draggingChildIndexes = IndexSet(draggedItems.map { outlineView.childIndex(forItem: $0) })
            session.animatesToStartingPositionsOnCancelOrFail = false
        }
    }

    open func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        draggingChildIndexes = []
    }
}
