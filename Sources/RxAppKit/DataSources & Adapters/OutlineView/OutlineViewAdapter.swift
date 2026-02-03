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

open class OutlineViewAdapter<OutlineNode: OutlineNodeType>: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, ReorderableOutlineViewAdapter, _ItemMovedEventEmitting, _OutlineItemMovedEventEmitting {
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
    let _outlineItemMoved = PublishSubject<OutlineMove>()

    private static var reorderPasteboardType: NSPasteboard.PasteboardType {
        NSPasteboard.PasteboardType("com.RxAppKit.OutlineViewAdapter.reorder")
    }

    private var childOverrides: [AnyHashable: [OutlineNode]] = [:]
    private var draggingChildIndexes: IndexSet = []
    private var draggingParentItem: OutlineNode?
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

    var hasReorderingOverrides: Bool {
        !childOverrides.isEmpty
    }

    func resetReorderingState() {
        childOverrides.removeAll()
        draggingChildIndexes = []
        draggingParentItem = nil
    }

    // MARK: - Data

    open func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? OutlineNode else {
            return rootNode != nil ? 1 : nodes.count
        }
        return currentChildren(of: node).count
    }

    open func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let node = item as? OutlineNode else {
            return rootNode ?? nodes[index]
        }
        return currentChildren(of: node)[index]
    }

    open func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? OutlineNode else {
            return rootNode.map { !currentChildren(of: $0).isEmpty } ?? false
        }
        return !currentChildren(of: node).isEmpty
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

    // MARK: - Reordering Helpers

    private func nodeKey(_ node: OutlineNode) -> AnyHashable? {
        node as? AnyHashable
    }

    private func isSameNode(_ lhs: OutlineNode?, _ rhs: OutlineNode?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (l?, r?):
            if let lk = nodeKey(l), let rk = nodeKey(r) {
                return lk == rk
            }
            if let lObj = l as? AnyObject, let rObj = r as? AnyObject {
                return lObj === rObj
            }
            return false
        default:
            return false
        }
    }

    private func isParentHashable(_ parent: OutlineNode?) -> Bool {
        guard let parent else { return true }
        return nodeKey(parent) != nil
    }

    private func currentChildren(of parent: OutlineNode?) -> [OutlineNode] {
        guard let parent else { return nodes }
        if let key = nodeKey(parent), let override = childOverrides[key] {
            return override
        }
        return parent.children
    }

    private func setChildren(_ children: [OutlineNode], for parent: OutlineNode?) {
        guard let parent else {
            nodes = children
            return
        }
        guard let key = nodeKey(parent) else { return }
        childOverrides[key] = children
    }

    private func indexPath(for item: OutlineNode?, in outlineView: NSOutlineView) -> IndexPath? {
        guard let item else { return nil }
        var indices: [Int] = []
        var current: Any? = item
        while let node = current as? OutlineNode {
            let index = outlineView.childIndex(forItem: node)
            guard index != NSOutlineViewDropOnItemIndex else { return nil }
            indices.insert(index, at: 0)
            current = outlineView.parent(forItem: node)
        }
        return IndexPath(indexes: indices)
    }

    private func draggedNodes(from parent: OutlineNode?) -> [OutlineNode] {
        let children = currentChildren(of: parent)
        return draggingChildIndexes.compactMap { index in
            guard index >= 0, index < children.count else { return nil }
            return children[index]
        }
    }

    private func isDescendant(_ candidate: OutlineNode?, ofAny items: [OutlineNode], in outlineView: NSOutlineView) -> Bool {
        guard let candidate else { return false }
        let draggedKeys = Set(items.compactMap(nodeKey))
        guard !draggedKeys.isEmpty else { return false }

        var current: Any? = candidate
        while let node = current as? OutlineNode {
            if let key = nodeKey(node), draggedKeys.contains(key) {
                return true
            }
            current = outlineView.parent(forItem: node)
        }
        return false
    }

    // MARK: - Drag & Drop Data Source

    open func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> (any NSPasteboardWriting)? {
        guard reorderingHandlers.canReorder != nil else { return nil }
        guard let node = item as? OutlineNode else { return nil }
        if let rootNode, isSameNode(node, rootNode) {
            return nil
        }
        let pbItem = NSPasteboardItem()
        let childIndex = outlineView.childIndex(forItem: node)
        pbItem.setString(String(childIndex), forType: Self.reorderPasteboardType)
        return pbItem
    }

    open func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        guard !draggingChildIndexes.isEmpty else { return [] }
        guard info.draggingSource as? NSOutlineView === outlineView else { return [] }
        if rootNode != nil, item == nil { return [] }

        let destinationParent = item as? OutlineNode
        let sourceParent = draggingParentItem
        let draggedItems = draggedNodes(from: sourceParent)
        guard !draggedItems.isEmpty else { return [] }

        let isRootOnlyMove = destinationParent == nil && sourceParent == nil
        if !isRootOnlyMove {
            guard draggedItems.allSatisfy({ nodeKey($0) != nil }) else { return [] }
            guard isParentHashable(sourceParent), isParentHashable(destinationParent) else { return [] }
        }

        if isDescendant(destinationParent, ofAny: draggedItems, in: outlineView) {
            return []
        }

        return .move
    }

    open func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex: Int) -> Bool {
        guard !draggingChildIndexes.isEmpty else { return false }
        guard info.draggingSource as? NSOutlineView === outlineView else { return false }
        if rootNode != nil, item == nil { return false }

        let sourceParent = draggingParentItem
        let destinationParent = item as? OutlineNode
        let isDropOnItem = childIndex == NSOutlineViewDropOnItemIndex

        let sourceParentPath = indexPath(for: sourceParent, in: outlineView)
        let destinationParentPath = indexPath(for: destinationParent, in: outlineView)

        let isRootOnlyMove = destinationParent == nil && sourceParent == nil
        if !isRootOnlyMove {
            guard isParentHashable(sourceParent), isParentHashable(destinationParent) else { return false }
        }

        var targetIndex = isDropOnItem ? currentChildren(of: destinationParent).count : childIndex
        var sourceChildren = currentChildren(of: sourceParent)
        let sortedDescending = draggingChildIndexes.sorted(by: >)
        let sortedAscending = draggingChildIndexes.sorted()
        let draggedNodes = sortedAscending.compactMap { index -> OutlineNode? in
            guard index >= 0, index < sourceChildren.count else { return nil }
            return sourceChildren[index]
        }
        guard draggedNodes.count == sortedAscending.count else { return false }
        if !isRootOnlyMove, !draggedNodes.allSatisfy({ nodeKey($0) != nil }) {
            return false
        }

        if isSameNode(sourceParent, destinationParent) {
            for index in sortedDescending where index < targetIndex {
                targetIndex -= 1
            }
        }

        if isRootOnlyMove {
            reorderingHandlers.willReorder?(draggedNodes, targetIndex)
        }

        if isSameNode(sourceParent, destinationParent) {
            for index in sortedDescending {
                sourceChildren.remove(at: index)
            }
            for (offset, node) in draggedNodes.enumerated() {
                sourceChildren.insert(node, at: targetIndex + offset)
            }
            setChildren(sourceChildren, for: sourceParent)
        } else {
            var sourceUpdated = sourceChildren
            for index in sortedDescending {
                sourceUpdated.remove(at: index)
            }
            setChildren(sourceUpdated, for: sourceParent)

            var destinationChildren = currentChildren(of: destinationParent)
            for (offset, node) in draggedNodes.enumerated() {
                destinationChildren.insert(node, at: targetIndex + offset)
            }
            setChildren(destinationChildren, for: destinationParent)
        }

        outlineView.beginUpdates()
        if isSameNode(sourceParent, destinationParent) {
            var oldOffset = 0
            for (moveOffset, oldIndex) in sortedAscending.enumerated() {
                let adjustedTarget = targetIndex + moveOffset
                outlineView.moveItem(at: oldIndex - oldOffset, inParent: sourceParent, to: adjustedTarget, inParent: sourceParent)
                if oldIndex < targetIndex {
                    oldOffset += 1
                }
            }
        } else {
            outlineView.removeItems(at: draggingChildIndexes, inParent: sourceParent, withAnimation: .effectGap)
            let insertRange = targetIndex ..< (targetIndex + draggedNodes.count)
            let insertIndexes = IndexSet(integersIn: insertRange)
            outlineView.insertItems(at: insertIndexes, inParent: destinationParent, withAnimation: .effectGap)
        }
        outlineView.endUpdates()

        if isRootOnlyMove {
            reorderingHandlers.didReorder?(nodes)
            _itemMoved.onNext((sourceIndexes: draggingChildIndexes, destinationIndex: targetIndex))
            _modelMoved.onNext(nodes.map { $0 as Any })
        }

        let move = OutlineMove(
            sourceParentPath: sourceParentPath,
            sourceIndexes: draggingChildIndexes,
            destinationParentPath: destinationParentPath,
            destinationIndex: targetIndex,
            isDropOnItem: isDropOnItem
        )
        _outlineItemMoved.onNext(move)

        draggingChildIndexes = []
        draggingParentItem = nil
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
            draggingParentItem = nil
            session.animatesToStartingPositionsOnCancelOrFail = true
            return
        }

        if let rootNode, allowedNodes.contains(where: { isSameNode($0, rootNode) }) {
            draggingChildIndexes = []
            draggingParentItem = nil
            session.animatesToStartingPositionsOnCancelOrFail = true
            return
        }

        let parent = outlineView.parent(forItem: allowedNodes[0]) as? OutlineNode
        let sameParent = allowedNodes.allSatisfy { node in
            isSameNode(outlineView.parent(forItem: node) as? OutlineNode, parent)
        }
        guard sameParent else {
            draggingChildIndexes = []
            draggingParentItem = nil
            session.animatesToStartingPositionsOnCancelOrFail = true
            return
        }

        let indices = allowedNodes.map { outlineView.childIndex(forItem: $0) }.filter { $0 != NSOutlineViewDropOnItemIndex }
        if indices.isEmpty {
            draggingChildIndexes = []
            draggingParentItem = nil
            session.animatesToStartingPositionsOnCancelOrFail = true
            return
        }

        draggingParentItem = parent
        draggingChildIndexes = IndexSet(indices)
        session.animatesToStartingPositionsOnCancelOrFail = false
    }

    open func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        draggingChildIndexes = []
        draggingParentItem = nil
    }
}
