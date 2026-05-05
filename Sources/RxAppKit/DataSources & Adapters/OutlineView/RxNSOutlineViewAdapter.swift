import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

open class RxNSOutlineViewRootNodeAdapter<OutlineNode: OutlineNodeType & Hashable & Differentiable>: OutlineViewAdapter<OutlineNode>, RxNSOutlineViewDataSourceType {
    public typealias Element = OutlineNode

    open var animatedReloadThreshold: Int = 100

    open func outlineView(_ outlineView: NSOutlineView, observedEvent: Event<Element>) {
        Binder<Element>(self) { (dataSource: RxNSOutlineViewRootNodeAdapter<OutlineNode>, rootNode) in
            let oldRoots = dataSource.rootNode.map { [$0] } ?? []
            let newRoots = [rootNode]
            let changeset = StagedChangeset(source: oldRoots, target: newRoots)
            outlineView.reload(using: changeset, with: [], inParent: nil) { changeset in
                !changeset.isOutlineViewSafe
                    || changeset.totalElementChangeCount > dataSource.animatedReloadThreshold
            } setData: {
                dataSource.rootNode = $0.first
            }
        }.on(observedEvent)
    }
}

open class RxNSOutlineViewAdapter<OutlineNode: OutlineNodeType & Hashable & Differentiable>: OutlineViewAdapter<OutlineNode>, RxNSOutlineViewDataSourceType {
    public typealias Element = [OutlineNode]

    open var animatedReloadThreshold: Int = 100

    open func outlineView(_ outlineView: NSOutlineView, observedEvent: Event<Element>) {
        Binder<Element>(self) { (dataSource: RxNSOutlineViewAdapter<OutlineNode>, newNodes) in
            let changeset = StagedChangeset(source: dataSource.nodes, target: newNodes)
            outlineView.reload(using: changeset, with: [], inParent: nil) { changeset in
                !changeset.isOutlineViewSafe
                    || changeset.totalElementChangeCount > dataSource.animatedReloadThreshold
            } setData: {
                dataSource.nodes = $0
            }
        }.on(observedEvent)
    }
}

open class RxNSReorderableOutlineViewAdapter<OutlineNode: OutlineNodeType & Hashable & Differentiable>: ReorderableOutlineViewAdapter<OutlineNode>, RxNSOutlineViewDataSourceType {
    public typealias Element = [OutlineNode]

    open var animatedReloadThreshold: Int = 100

    open func outlineView(_ outlineView: NSOutlineView, observedEvent: Event<Element>) {
        Binder<Element>(self) { (dataSource: RxNSReorderableOutlineViewAdapter<OutlineNode>, newNodes) in
            _RxAppKitDebugLog("observedEvent ENTER: nodes.count=\(dataSource.nodes.count), newNodes.count=\(newNodes.count), pendingDragOperation=\(dataSource.pendingDragOperation == nil ? "nil" : "set"), outlineView.rows=\(outlineView.numberOfRows)")
            let applyUpdate = {
                if let pending = dataSource.pendingDragOperation {
                    _RxAppKitDebugLog("applyUpdate (drag path) BEGIN: pending=(srcParent=\(_rxAppKitDebugDescribe(pending.sourceParent)), srcIdxs=\(pending.sortedSourceChildIndexes), dstParent=\(_rxAppKitDebugDescribe(pending.destinationParent)), baseIdx=\(pending.baseInsertionIndex), sameParent=\(pending.isSameParent))")
                    if let dst = pending.destinationParent {
                        _RxAppKitDebugLog("applyUpdate (drag path) destination state PRE: \(_rxAppKitDebugExpansionState(outlineView, item: dst))")
                    }
                    dataSource.pendingDragOperation = nil
                    dataSource.resetReorderingState()
                    dataSource.nodes = newNodes
                    dataSource.applyDragMove(pending, to: outlineView)
                    if let dst = pending.destinationParent {
                        _RxAppKitDebugLog("applyUpdate (drag path) destination state POST: \(_rxAppKitDebugExpansionState(outlineView, item: dst))")
                    }
                    _RxAppKitDebugLog("applyUpdate (drag path) END: outlineView.rows=\(outlineView.numberOfRows)")
                    return
                }

                guard dataSource.nodes != newNodes else {
                    _RxAppKitDebugLog("applyUpdate (diff path) SKIP: nodes==newNodes, no overrides")
                    return
                }
                let changeset = StagedChangeset(source: dataSource.nodes, target: newNodes)
                _RxAppKitDebugLog("applyUpdate (diff path) BEGIN: stages=\(changeset.count), summary=[\(changeset.enumerated().map { i, c in "stage\(i){ins=\(c.elementInserted.count),del=\(c.elementDeleted.count),upd=\(c.elementUpdated.count),mov=\(c.elementMoved.count)}" }.joined(separator: ","))]")
                if changeset.isEmpty {
                    _RxAppKitDebugLog("applyUpdate (diff path) EMPTY changeset → just commit nodes")
                    dataSource.nodes = newNodes
                    return
                }
                outlineView.reload(using: changeset, with: [], inParent: nil) { changeset in
                    let interrupted = !changeset.isOutlineViewSafe
                        || changeset.totalElementChangeCount > dataSource.animatedReloadThreshold
                    if interrupted {
                        _RxAppKitDebugLog("applyUpdate (diff path) INTERRUPT: safe=\(changeset.isOutlineViewSafe), total=\(changeset.totalElementChangeCount), threshold=\(dataSource.animatedReloadThreshold)")
                    }
                    return interrupted
                } setData: {
                    dataSource.nodes = $0
                }
                _RxAppKitDebugLog("applyUpdate (diff path) END: outlineView.rows=\(outlineView.numberOfRows)")
            }
            // When a drag operation is pending the update was triggered from inside
            // `acceptDrop:` (synchronous chain through Rx). Defer the view update so
            // AppKit can finish its drag-and-drop bookkeeping before we touch rows;
            // otherwise its row-to-item mapping ends up out of sync and the next
            // drag misaligns.
            if dataSource.pendingDragOperation != nil {
                _RxAppKitDebugLog("observedEvent: pending != nil → DISPATCH ASYNC")
                DispatchQueue.main.async(execute: applyUpdate)
            } else {
                _RxAppKitDebugLog("observedEvent: pending == nil → SYNC")
                applyUpdate()
            }
        }.on(observedEvent)
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

extension NSOutlineView {
    /// Applies multiple animated updates in stages using `StagedChangeset`.
    ///
    /// - Note: NSOutlineView updates are hierarchical. This method updates the children of a specific `parent` item.
    ///
    /// - Parameters:
    ///   - stagedChangeset: A staged set of changes.
    ///   - animation: An option to animate the updates.
    ///   - parent: The parent item whose children are being updated. Pass `nil` for root items.
    ///   - interrupt: A closure that takes an changeset as its argument and returns `true` if the animated
    ///                updates should be stopped and performed reloadData. Default is nil.
    ///   - setData: A closure that takes the collection as a parameter.
    ///              The collection should be set to data-source of NSOutlineView.
    func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        with animation: @autoclosure () -> NSTableView.AnimationOptions,
        inParent parent: Any?,
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        setData: (C) -> Void
    ) {
        reload(
            using: stagedChangeset,
            deleteItemsAnimation: animation(),
            insertItemsAnimation: animation(),
            inParent: parent,
            interrupt: interrupt,
            setData: setData
        )
    }

    /// Applies multiple animated updates in stages using `StagedChangeset`.
    ///
    /// - Parameters:
    ///   - stagedChangeset: A staged set of changes.
    ///   - deleteItemsAnimation: An option to animate the item deletion.
    ///   - insertItemsAnimation: An option to animate the item insertion.
    ///   - parent: The parent item whose children are being updated. Pass `nil` for root items.
    ///   - interrupt: A closure that takes an changeset as its argument and returns `true` if the animated
    ///                updates should be stopped and performed reloadData. Default is nil.
    ///   - setData: A closure that takes the collection as a parameter.
    ///              The collection should be set to data-source of NSOutlineView.
    func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        deleteItemsAnimation: @autoclosure () -> NSTableView.AnimationOptions,
        insertItemsAnimation: @autoclosure () -> NSTableView.AnimationOptions,
        inParent parent: Any?,
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        setData: (C) -> Void
    ) {
        if case .none = window, let data = stagedChangeset.last?.data {
            _RxAppKitDebugLog("reload(extension): window=nil → setData + reloadData")
            setData(data)
            return reloadData()
        }

        for (stageIndex, changeset) in stagedChangeset.enumerated() {
            if let interrupt = interrupt, interrupt(changeset), let data = stagedChangeset.last?.data {
                _RxAppKitDebugLog("reload(extension) stage\(stageIndex): INTERRUPT → setData + reloadData (parent=\(_rxAppKitDebugDescribe(parent)))")
                setData(data)
                return reloadData()
            }

            _RxAppKitDebugLog("reload(extension) stage\(stageIndex) BEGIN: parent=\(_rxAppKitDebugDescribe(parent)), ins=\(changeset.elementInserted.map { $0.element }), del=\(changeset.elementDeleted.map { $0.element }), upd=\(changeset.elementUpdated.map { $0.element }), mov=\(changeset.elementMoved.map { "(\($0.source.element)→\($0.target.element))" })")
            beginUpdates()

            // Snapshot items to reload BEFORE updating data source,
            // because the outline view only recognizes old item references.
            let itemsToReload = changeset.elementUpdated.map { child($0.element, ofItem: parent) }

            setData(changeset.data)

            if !changeset.elementDeleted.isEmpty {
                removeItems(at: IndexSet(changeset.elementDeleted.map { $0.element }), inParent: parent, withAnimation: deleteItemsAnimation())
            }

            for item in itemsToReload {
                reloadItem(item, reloadChildren: true)
            }

            if !changeset.elementMoved.isEmpty {
                // The same source/target offset translation DifferenceKit applies in its
                // built-in `NSTableView` extension. `StagedChangeset.elementMoved` indices
                // are expressed in source/target array coordinates, but `NSOutlineView`
                // (like `NSTableView`) interprets `moveItem(at:to:)` against the
                // already-mutating intermediate state inside the begin/endUpdates block.
                let insertionIndices = IndexSet(changeset.elementInserted.map { $0.element })
                var movedSourceIndices = IndexSet()

                for (source, target) in changeset.elementMoved {
                    let sourceElementOffset = movedSourceIndices.count(in: source.element...)
                    let targetElementOffset = insertionIndices.count(in: 0 ..< target.element)
                    moveItem(at: source.element + sourceElementOffset, inParent: parent,
                             to: target.element - targetElementOffset, inParent: parent)
                    movedSourceIndices.insert(source.element)
                }
            }

            if !changeset.elementInserted.isEmpty {
                insertItems(at: IndexSet(changeset.elementInserted.map { $0.element }), inParent: parent, withAnimation: insertItemsAnimation())
            }

            endUpdates()
            _RxAppKitDebugLog("reload(extension) stage\(stageIndex) END: outlineView.numberOfRows=\(numberOfRows)")
        }
    }
}

extension Changeset {
    /// Total number of element-level changes in this changeset.
    var totalElementChangeCount: Int {
        elementInserted.count + elementDeleted.count + elementUpdated.count + elementMoved.count
    }

    /// `true` if applying this changeset incrementally on `NSOutlineView` is safe.
    ///
    /// `elementUpdated` is applied via `reloadItem(_:reloadChildren:)`, which calls back
    /// into the data source with the *original* item reference. With value-typed nodes the
    /// callback returns stale children, so subtree changes never surface — this case must
    /// fall back to `reloadData()` for correctness.
    var isOutlineViewSafe: Bool {
        elementUpdated.isEmpty
    }
}
