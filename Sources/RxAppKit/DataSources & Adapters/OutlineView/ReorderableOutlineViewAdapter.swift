import AppKit
import RxSwift
import RxCocoa

// MARK: - Debug logging
//
// Verbose drag-and-drop diagnostics. Disabled by default; flip
// `RxAppKitDebugLogging.isEnabled = true` to print to the console.
// When disabled the message expressions are never evaluated (`@autoclosure`),
// so leaving the call sites in place is effectively free.

public enum RxAppKitDebugLogging {
    /// Set to `true` to enable verbose RxAppKit drag-and-drop logging.
    public static var isEnabled: Bool = false
}

private let _rxAppKitDebugFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
}()

@inline(never) internal func _RxAppKitDebugLog(_ message: @autoclosure () -> String) {
    guard RxAppKitDebugLogging.isEnabled else { return }
    let timestamp = _rxAppKitDebugFormatter.string(from: Date())
    let threadTag = Thread.isMainThread ? "main" : "bg"
    print("[RxAppKitDebug \(timestamp) \(threadTag)] \(message())")
}

internal func _rxAppKitDebugDescribe(_ value: Any?) -> String {
    guard let value else { return "nil" }
    let object = value as AnyObject
    let pointer = String(format: "%p", unsafeBitCast(object, to: Int.self))
    return "<\(type(of: value)):\(pointer)>"
}

internal func _rxAppKitDebugExpansionState(_ outlineView: NSOutlineView, item: Any?) -> String {
    if item == nil { return "root(N/A)" }
    let expanded = outlineView.isItemExpanded(item)
    let row = outlineView.row(forItem: item)
    let childIdx = outlineView.childIndex(forItem: item as Any)
    return "expanded=\(expanded), row=\(row), childIdx=\(childIdx)"
}

open class ReorderableOutlineViewAdapter<OutlineNode: OutlineNodeType>: OutlineViewAdapter<OutlineNode>, RxNSOutlineViewReorderableDataSourceType {

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

    open var isReorderingEnabled: Bool = true

    open var isRootLevelReorderingOnly: Bool = false

    /// When `true`, after a drag completes the destination parent is automatically
    /// expanded if it was collapsed. Lets users see the item they just dropped
    /// onto a collapsed group without having to manually disclose it. Defaults
    /// to `true`. Set to `false` to keep the destination's expansion state
    /// untouched.
    open var expandsDropDestination: Bool = true

    public let outlineItemMoved = PublishSubject<OutlineMove>()
    public let modelMoved = PublishSubject<[Any]>()

    private static var reorderPasteboardType: NSPasteboard.PasteboardType {
        NSPasteboard.PasteboardType("com.RxAppKit.OutlineViewAdapter.reorder")
    }

    private var childOverrides: [AnyHashable: [OutlineNode]] = [:]
    private var rootNodesOverride: [OutlineNode]?
    private var draggingChildIndexes: IndexSet = []
    private var draggingParentItem: OutlineNode?
    private var isReorderingRegistered = false

    /// Records the AppKit-level move that just happened in `acceptDrop:`, so that
    /// downstream consumers (like the Rx binder) can drive `NSOutlineView.moveItem(at:inParent:to:inParent:)`
    /// directly instead of going through a flat-array diff — diffs cannot represent
    /// cross-parent moves correctly and leave the view's row mapping stale.
    internal struct PendingDragOperation {
        let sourceParent: OutlineNode?
        /// Ascending order.
        let sortedSourceChildIndexes: [Int]
        let destinationParent: OutlineNode?
        /// Same-parent: final-state index of the FIRST dragged item (after source-removal adjustment).
        /// Cross-parent: destination index where dragged items are inserted.
        let baseInsertionIndex: Int
        let isSameParent: Bool
    }

    internal var pendingDragOperation: PendingDragOperation?

    /// Register the outline view for internal drag-and-drop reordering.
    /// Called automatically by `rx.reorderableNodes(adapter:)` when using Rx bindings.
    open func setupReordering(for outlineView: NSOutlineView) {
        guard !isReorderingRegistered else { return }
        isReorderingRegistered = true
        outlineView.registerForDraggedTypes([Self.reorderPasteboardType])
        outlineView.setDraggingSourceOperationMask(.move, forLocal: true)
    }

    var hasReorderingOverrides: Bool {
        !childOverrides.isEmpty || rootNodesOverride != nil
    }

    func resetReorderingState() {
        childOverrides.removeAll()
        rootNodesOverride = nil
        draggingChildIndexes = []
        draggingParentItem = nil
    }

    // MARK: - Data (overridden to use currentChildren)

    open override func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? OutlineNode else {
            if rootNode != nil {
                return 1
            }
            return currentChildren(of: nil).count
        }
        return currentChildren(of: node).count
    }

    open override func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let node = item as? OutlineNode else {
            if let rootNode {
                return rootNode
            }
            return currentChildren(of: nil)[index]
        }
        return currentChildren(of: node)[index]
    }

    open override func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? OutlineNode else {
            if let rootNode {
                return !currentChildren(of: rootNode).isEmpty
            }
            return !currentChildren(of: nil).isEmpty
        }
        return !currentChildren(of: node).isEmpty
    }

    // MARK: - Reordering Helpers

    private func nodeKey(_ node: OutlineNode) -> AnyHashable? {
        node as? AnyHashable
    }

    private func isSameNode(_ lhs: OutlineNode?, _ rhs: OutlineNode?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (lhs?, rhs?):
            if let lhsKey = nodeKey(lhs), let rhsKey = nodeKey(rhs) {
                return lhsKey == rhsKey
            }
            return (lhs as AnyObject) === (rhs as AnyObject)
        default:
            return false
        }
    }

    private func isParentHashable(_ parent: OutlineNode?) -> Bool {
        guard let parent else { return true }
        return nodeKey(parent) != nil
    }

    private func currentChildren(of parent: OutlineNode?) -> [OutlineNode] {
        guard let parent else { return rootNodesOverride ?? nodes }
        if let key = nodeKey(parent), let override = childOverrides[key] {
            return override
        }
        return parent.children
    }

    private func setChildren(_ children: [OutlineNode], for parent: OutlineNode?) {
        guard let parent else {
            rootNodesOverride = children
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

    @objc open func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> (any NSPasteboardWriting)? {
        guard isReorderingEnabled else { return nil }
        guard let node = item as? OutlineNode else { return nil }
        if let rootNode, isSameNode(node, rootNode) {
            return nil
        }
        if isRootLevelReorderingOnly {
            let parent = outlineView.parent(forItem: item)
            if rootNode != nil {
                guard let parentNode = parent as? OutlineNode, isSameNode(parentNode, rootNode) else { return nil }
            } else {
                guard parent == nil else { return nil }
            }
        }
        let pbItem = NSPasteboardItem()
        let childIndex = outlineView.childIndex(forItem: node)
        pbItem.setString(String(childIndex), forType: Self.reorderPasteboardType)
        return pbItem
    }

    @objc open func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        guard !draggingChildIndexes.isEmpty else { return [] }
        guard info.draggingSource as? NSOutlineView === outlineView else { return [] }
        if rootNode != nil, item == nil { return [] }

        if isRootLevelReorderingOnly {
            if rootNode != nil {
                guard let destNode = item as? OutlineNode, isSameNode(destNode, rootNode) else { return [] }
            } else {
                guard item == nil else { return [] }
            }
        }

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

    @objc open func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex: Int) -> Bool {
        let destExpansion: String = {
            if let dest = item { return _rxAppKitDebugExpansionState(outlineView, item: dest) }
            return "root(no item)"
        }()
        _RxAppKitDebugLog("acceptDrop ENTER: childIndex=\(childIndex), item=\(_rxAppKitDebugDescribe(item)) [\(destExpansion)], draggingChildIndexes=\(Array(draggingChildIndexes)), draggingParent=\(_rxAppKitDebugDescribe(draggingParentItem)), nodes.count=\(nodes.count), outlineView.rows=\(outlineView.numberOfRows), rootOverride=\(rootNodesOverride.map { "set(\($0.count))" } ?? "nil"), childOverrides.count=\(childOverrides.count)")
        guard !draggingChildIndexes.isEmpty else {
            _RxAppKitDebugLog("acceptDrop ABORT: empty draggingChildIndexes")
            return false
        }
        guard info.draggingSource as? NSOutlineView === outlineView else {
            _RxAppKitDebugLog("acceptDrop ABORT: foreign draggingSource")
            return false
        }
        if rootNode != nil, item == nil {
            _RxAppKitDebugLog("acceptDrop ABORT: rootNode mode but item=nil")
            return false
        }

        let sourceParent = draggingParentItem
        let destinationParent = item as? OutlineNode
        let isDropOnItem = childIndex == NSOutlineViewDropOnItemIndex

        let sourceParentPath = indexPath(for: sourceParent, in: outlineView)
        let destinationParentPath = indexPath(for: destinationParent, in: outlineView)
        _RxAppKitDebugLog("acceptDrop paths: sourceParentPath=\(sourceParentPath as Any), destinationParentPath=\(destinationParentPath as Any), isDropOnItem=\(isDropOnItem)")

        let isRootOnlyMove = destinationParent == nil && sourceParent == nil
        if !isRootOnlyMove {
            guard isParentHashable(sourceParent), isParentHashable(destinationParent) else { return false }
        }

        let dropTargetIndex = isDropOnItem ? currentChildren(of: destinationParent).count : childIndex
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

        // Adjusted index for array manipulation (accounts for removed items shifting indices)
        var insertionIndex = dropTargetIndex
        if isSameNode(sourceParent, destinationParent) {
            for index in sortedDescending where index < insertionIndex {
                insertionIndex -= 1
            }
        }

        if isRootOnlyMove {
            reorderingHandlers.willReorder?(draggedNodes, insertionIndex)
        }

        if isSameNode(sourceParent, destinationParent) {
            for index in sortedDescending {
                sourceChildren.remove(at: index)
            }
            for (offset, node) in draggedNodes.enumerated() {
                sourceChildren.insert(node, at: insertionIndex + offset)
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
                destinationChildren.insert(node, at: dropTargetIndex + offset)
            }
            setChildren(destinationChildren, for: destinationParent)
        }

        // Record the AppKit-level move so downstream code (the Rx binder) can drive
        // `outlineView.moveItem(at:inParent:to:inParent:)` precisely instead of
        // computing a flat-array diff that can't represent cross-parent moves.
        let pending = PendingDragOperation(
            sourceParent: sourceParent,
            sortedSourceChildIndexes: sortedAscending,
            destinationParent: destinationParent,
            baseInsertionIndex: insertionIndex,
            isSameParent: isSameNode(sourceParent, destinationParent)
        )
        pendingDragOperation = pending
        _RxAppKitDebugLog("acceptDrop after-mutate: pending=(srcParent=\(_rxAppKitDebugDescribe(pending.sourceParent)), srcIdxs=\(pending.sortedSourceChildIndexes), dstParent=\(_rxAppKitDebugDescribe(pending.destinationParent)), baseIdx=\(pending.baseInsertionIndex), sameParent=\(pending.isSameParent)), rootOverride=\(rootNodesOverride.map { "[\($0.count)]" } ?? "nil"), childOverrides.count=\(childOverrides.count)")

        if isRootOnlyMove {
            let newRootNodes = currentChildren(of: nil)
            reorderingHandlers.didReorder?(newRootNodes)
            _RxAppKitDebugLog("acceptDrop EMIT modelMoved (rootOnly)")
            modelMoved.onNext(newRootNodes.map { $0 as Any })
            _RxAppKitDebugLog("acceptDrop EMIT modelMoved DONE")
        }

        let move = OutlineMove(
            sourceParentPath: sourceParentPath,
            sourceIndexes: draggingChildIndexes,
            destinationParentPath: destinationParentPath,
            destinationIndex: dropTargetIndex,
            isDropOnItem: isDropOnItem
        )
        _RxAppKitDebugLog("acceptDrop EMIT outlineItemMoved: move=\(move)")
        outlineItemMoved.onNext(move)
        _RxAppKitDebugLog("acceptDrop EMIT outlineItemMoved DONE")

        draggingChildIndexes = []
        draggingParentItem = nil
        _RxAppKitDebugLog("acceptDrop EXIT (return true): nodes.count=\(nodes.count), outlineView.rows=\(outlineView.numberOfRows), pendingDragOperation=\(pendingDragOperation == nil ? "consumed" : "still-pending")")
        return true
    }

    @objc(outlineView:draggingSession:willBeginAtPoint:forItems:)
    open func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
        let perItemDescribe = draggedItems.map { item -> String in
            "\(_rxAppKitDebugDescribe(item))[\(_rxAppKitDebugExpansionState(outlineView, item: item))]"
        }.joined(separator: ",")
        _RxAppKitDebugLog("willBeginAt: draggedItems=[\(perItemDescribe)], outlineView.rows=\(outlineView.numberOfRows), nodes.count=\(nodes.count), rootOverride=\(rootNodesOverride.map { "[\($0.count)]" } ?? "nil")")
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
        _RxAppKitDebugLog("willBeginAt FINISHED: draggingChildIndexes=\(Array(draggingChildIndexes)), draggingParent=\(_rxAppKitDebugDescribe(parent))")
    }

    @objc(outlineView:draggingSession:endedAtPoint:operation:)
    open func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        _RxAppKitDebugLog("endedAt: operation=\(operation.rawValue), nodes.count=\(nodes.count), outlineView.rows=\(outlineView.numberOfRows), pendingDragOperation=\(pendingDragOperation == nil ? "nil" : "set")")
        draggingChildIndexes = []
        draggingParentItem = nil
    }
}

extension ReorderableOutlineViewAdapter {
    /// Translates a recorded `PendingDragOperation` into one or more
    /// `NSOutlineView.moveItem(at:inParent:to:inParent:)` calls inside a
    /// single `beginUpdates`/`endUpdates` batch. Assumes `nodes` and any
    /// hierarchical model state already reflect the post-move state.
    internal func applyDragMove(_ pending: PendingDragOperation, to outlineView: NSOutlineView) {
        let sortedAscending = pending.sortedSourceChildIndexes
        guard !sortedAscending.isEmpty else {
            _RxAppKitDebugLog("applyDragMove ABORT: empty sortedSourceChildIndexes")
            return
        }
        let count = sortedAscending.count

        _RxAppKitDebugLog("applyDragMove BEGIN: count=\(count), sameParent=\(pending.isSameParent), srcParent=\(_rxAppKitDebugDescribe(pending.sourceParent)), dstParent=\(_rxAppKitDebugDescribe(pending.destinationParent)), baseIdx=\(pending.baseInsertionIndex), outlineView.rows(pre)=\(outlineView.numberOfRows)")
        if let dst = pending.destinationParent {
            _RxAppKitDebugLog("applyDragMove dst PRE-batch: \(_rxAppKitDebugExpansionState(outlineView, item: dst))")
        }

        let needsExpandDestination = expandsDropDestination
            && pending.destinationParent != nil
            && !outlineView.isItemExpanded(pending.destinationParent)

        outlineView.beginUpdates()
        if pending.isSameParent {
            // Process largest-source-index first so earlier (larger) indices
            // aren't shifted by previous moves. Each item's final index in
            // the parent's children is `baseInsertionIndex + offsetInAsc`,
            // where `offsetInAsc` is the item's position in the ascending
            // source order; for the i-th item iterated descending,
            // `offsetInAsc = count - 1 - i`. NSOutlineView's same-parent
            // `moveItem(at:to:)` interprets `to` as the final index.
            let sortedDescending = sortedAscending.reversed()
            for (i, sourceIndex) in sortedDescending.enumerated() {
                let offsetInAscending = count - 1 - i
                let finalDestinationIndex = pending.baseInsertionIndex + offsetInAscending
                _RxAppKitDebugLog("applyDragMove moveItem (sameParent #\(i)): at=\(sourceIndex) → to=\(finalDestinationIndex) inParent=\(_rxAppKitDebugDescribe(pending.destinationParent))")
                outlineView.moveItem(at: sourceIndex, inParent: pending.sourceParent,
                                     to: finalDestinationIndex, inParent: pending.destinationParent)
            }
        } else {
            // Cross-parent: process ascending. After i moves the source has
            // lost i items (live source index = original - i) and the
            // destination has gained i items (live destination index = base + i).
            for (i, sourceIndex) in sortedAscending.enumerated() {
                let liveSourceIndex = sourceIndex - i
                let liveDestinationIndex = pending.baseInsertionIndex + i
                _RxAppKitDebugLog("applyDragMove moveItem (crossParent #\(i)): at=\(liveSourceIndex) inParent=\(_rxAppKitDebugDescribe(pending.sourceParent)) → to=\(liveDestinationIndex) inParent=\(_rxAppKitDebugDescribe(pending.destinationParent))")
                outlineView.moveItem(at: liveSourceIndex, inParent: pending.sourceParent,
                                     to: liveDestinationIndex, inParent: pending.destinationParent)
            }
        }
        outlineView.endUpdates()

        if let dst = pending.destinationParent {
            _RxAppKitDebugLog("applyDragMove dst POST-batch: \(_rxAppKitDebugExpansionState(outlineView, item: dst))")
        }
        _RxAppKitDebugLog("applyDragMove END: outlineView.rows(post)=\(outlineView.numberOfRows)")

        // Reveal the dropped item by expanding the destination if it was
        // collapsed. NSOutlineView does NOT do this automatically — what looks
        // like an automatic expansion in some cases is just spring-load
        // residue from the drag, which is timing-dependent. Without this,
        // dropping onto a collapsed group silently swallows the item.
        //
        // Two subtleties:
        //   1. `animator().expandItem(_:)` doesn't actually expand — `animator()`
        //      is for animatable property setters, not for arbitrary methods.
        //   2. If `dst` was a leaf before the move, `NSOutlineView` has cached
        //      `isItemExpandable=false` and refuses to expand it. We need to
        //      `reloadItem` first (without reloadChildren — we don't want to
        //      drop children of a still-collapsed item) so the view re-queries
        //      `isItemExpandable` against the new data source.
        if needsExpandDestination, let dst = pending.destinationParent {
            let expandableBefore = outlineView.isExpandable(dst)
            _RxAppKitDebugLog("applyDragMove EXPAND destination: \(_rxAppKitDebugDescribe(dst)), isExpandable(pre-reload)=\(expandableBefore)")
            outlineView.reloadItem(dst)
            let expandableAfterReload = outlineView.isExpandable(dst)
            _RxAppKitDebugLog("applyDragMove EXPAND: isExpandable(post-reload)=\(expandableAfterReload)")
            outlineView.expandItem(dst)
            _RxAppKitDebugLog("applyDragMove EXPAND DONE: isItemExpanded=\(outlineView.isItemExpanded(dst)), outlineView.rows=\(outlineView.numberOfRows)")
        }
    }
}
