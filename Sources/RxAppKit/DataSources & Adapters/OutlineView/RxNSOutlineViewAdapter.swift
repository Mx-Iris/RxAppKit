import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

/// Shared implementation for the Rx outline-view adapters.
///
/// Holds `options`, the `animatedReloadThreshold`, the drag-registration
/// short-circuit, and the staged update flow (drag path / diff path /
/// reload path). The two concrete subclasses below differ only in their
/// `Element` associated type and how they project the latest event into
/// the array form `performUpdate` expects.
///
/// Not intended for direct binding. Use `RxNSOutlineViewAdapter` for
/// `[OutlineNode]` sources or `RxNSOutlineViewRootNodeAdapter` for a
/// single root `OutlineNode`. Subclassing is allowed when you need a
/// different `Element` shape but the same staged update pipeline.
open class RxNSOutlineViewAdapterBase<OutlineNode: OutlineNodeType & Hashable & Differentiable>:
    ReorderableOutlineViewAdapter<OutlineNode> {

    public let options: RxNSOutlineViewAdapterOptions

    /// When using `.diffable`, changesets whose element-change count exceeds
    /// this threshold fall back to `reloadData()` instead of animating.
    open var animatedReloadThreshold: Int = 100

    public init(
        options: RxNSOutlineViewAdapterOptions = [],
        cellViewProvider: @escaping CellViewProvider,
        rowViewProvider: RowViewProvider? = nil
    ) {
        self.options = options
        super.init(cellViewProvider: cellViewProvider, rowViewProvider: rowViewProvider)
        if !options.contains(.reorderable) {
            isReorderingEnabled = false
        }
    }

    open override func setupReordering(for outlineView: NSOutlineView) {
        guard options.contains(.reorderable) else { return }
        super.setupReordering(for: outlineView)
    }

    /// Shared update path used by every concrete Rx outline adapter.
    /// `oldArray` / `newArray` are the array-form view of the model so the
    /// diff engine can be uniform; `commit` is the subclass's sink that
    /// writes the new data back to wherever the subclass stores it
    /// (`nodes` for the array binder, `rootNode` for the single-root binder).
    internal func performUpdate(
        outlineView: NSOutlineView,
        oldArray: [OutlineNode],
        newArray: [OutlineNode],
        commit: @escaping ([OutlineNode]) -> Void
    ) {
        _RxAppKitDebugLog("performUpdate ENTER: options=\(options.rawValue), oldArray.count=\(oldArray.count), newArray.count=\(newArray.count), pendingDragOperation=\(pendingDragOperation == nil ? "nil" : "set"), outlineView.rows=\(outlineView.numberOfRows)")
        if options.contains(.reorderable) {
            setupReordering(for: outlineView)
        }

        let applyUpdate: () -> Void = {
            if self.options.contains(.reorderable), let pending = self.pendingDragOperation {
                _RxAppKitDebugLog("applyUpdate (drag path) BEGIN: pending=(srcParent=\(_rxAppKitDebugDescribe(pending.sourceParent)), srcIdxs=\(pending.sortedSourceChildIndexes), dstParent=\(_rxAppKitDebugDescribe(pending.destinationParent)), baseIdx=\(pending.baseInsertionIndex), sameParent=\(pending.isSameParent))")
                self.pendingDragOperation = nil
                self.resetReorderingState()
                commit(newArray)
                self.applyDragMove(pending, to: outlineView)
                _RxAppKitDebugLog("applyUpdate (drag path) END: outlineView.rows=\(outlineView.numberOfRows)")
                return
            }

            guard oldArray != newArray else {
                _RxAppKitDebugLog("applyUpdate SKIP: oldArray==newArray")
                return
            }

            if self.options.contains(.diffable) {
                let changeset = StagedChangeset(source: oldArray, target: newArray)
                _RxAppKitDebugLog("applyUpdate (diff path) BEGIN: stages=\(changeset.count)")
                if changeset.isEmpty {
                    commit(newArray)
                    return
                }
                outlineView.reload(using: changeset, with: [], inParent: nil) { changeset in
                    !changeset.isOutlineViewSafe
                        || changeset.totalElementChangeCount > self.animatedReloadThreshold
                } setData: { staged in
                    commit(staged)
                }
                _RxAppKitDebugLog("applyUpdate (diff path) END: outlineView.rows=\(outlineView.numberOfRows)")
            } else {
                _RxAppKitDebugLog("applyUpdate (reload path): reloadData()")
                commit(newArray)
                outlineView.reloadData()
            }
        }

        // Drag updates flow synchronously through `acceptDrop:` -> Rx, but
        // `NSOutlineView` is still inside its drag-and-drop bookkeeping when
        // the event lands. Deferring lets AppKit finish before we touch rows;
        // otherwise its row-to-item mapping ends up out of sync and the next
        // drag misaligns.
        if options.contains(.reorderable), pendingDragOperation != nil {
            _RxAppKitDebugLog("performUpdate: pending != nil → DISPATCH ASYNC")
            DispatchQueue.main.async(execute: applyUpdate)
        } else {
            _RxAppKitDebugLog("performUpdate: pending == nil → SYNC")
            applyUpdate()
        }
    }
}

/// Rx data source adapter for `NSOutlineView` that maps an observable
/// sequence of root-level nodes (`[OutlineNode]`) onto the outline view.
/// See `RxNSOutlineViewAdapterOptions` for the supported behavior
/// combinations.
open class RxNSOutlineViewAdapter<OutlineNode: OutlineNodeType & Hashable & Differentiable>:
    RxNSOutlineViewAdapterBase<OutlineNode>,
    RxNSOutlineViewDataSourceType {
    public typealias Element = [OutlineNode]

    open func outlineView(_ outlineView: NSOutlineView, observedEvent: Event<Element>) {
        Binder<Element>(self) { (dataSource: RxNSOutlineViewAdapter<OutlineNode>, newNodes) in
            dataSource.performUpdate(
                outlineView: outlineView,
                oldArray: dataSource.nodes,
                newArray: newNodes,
                commit: { dataSource.nodes = $0 }
            )
        }.on(observedEvent)
    }
}

/// Rx data source adapter for `NSOutlineView` that maps an observable
/// sequence emitting a single root `OutlineNode` onto the outline view.
/// Use this when the outline shows one explicit root whose descendants
/// are the actual content. See `RxNSOutlineViewAdapterOptions` for the
/// supported behavior combinations.
open class RxNSOutlineViewRootNodeAdapter<OutlineNode: OutlineNodeType & Hashable & Differentiable>:
    RxNSOutlineViewAdapterBase<OutlineNode>,
    RxNSOutlineViewDataSourceType {
    public typealias Element = OutlineNode

    open func outlineView(_ outlineView: NSOutlineView, observedEvent: Event<Element>) {
        Binder<Element>(self) { (dataSource: RxNSOutlineViewRootNodeAdapter<OutlineNode>, newRoot) in
            let oldArray = dataSource.rootNode.map { [$0] } ?? []
            dataSource.performUpdate(
                outlineView: outlineView,
                oldArray: oldArray,
                newArray: [newRoot],
                commit: { dataSource.rootNode = $0.first }
            )
        }.on(observedEvent)
    }
}
