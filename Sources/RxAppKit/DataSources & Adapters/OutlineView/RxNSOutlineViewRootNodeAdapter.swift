import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

/// Rx data source adapter for `NSOutlineView` that maps an observable
/// sequence emitting a single root `OutlineNode` onto the outline view.
///
/// Behavior is controlled by `options`:
///
/// - `[]` — every event triggers `reloadData()` (default).
/// - `[.diffable]` — animated incremental updates via DifferenceKit.
/// - `[.reorderable]` — drag-and-drop reordering of the root's descendants;
///   non-drag updates still reload.
/// - `[.diffable, .reorderable]` — both.
///
/// Inherits from `ReorderableOutlineViewAdapter` so a single class can cover
/// all four combinations; without `.reorderable` the adapter short-circuits
/// drag registration and disables `isReorderingEnabled`.
open class RxNSOutlineViewRootNodeAdapter<OutlineNode: OutlineNodeType & Hashable & Differentiable>:
    ReorderableOutlineViewAdapter<OutlineNode>,
    RxNSOutlineViewDataSourceType {
    public typealias Element = OutlineNode

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

    open func outlineView(_ outlineView: NSOutlineView, observedEvent: Event<Element>) {
        Binder<Element>(self) { (dataSource: RxNSOutlineViewRootNodeAdapter<OutlineNode>, newRoot) in
            if dataSource.options.contains(.reorderable) {
                dataSource.setupReordering(for: outlineView)
            }

            let applyUpdate: () -> Void = {
                if dataSource.options.contains(.reorderable),
                   let pending = dataSource.pendingDragOperation {
                    dataSource.pendingDragOperation = nil
                    dataSource.resetReorderingState()
                    dataSource.rootNode = newRoot
                    dataSource.applyDragMove(pending, to: outlineView)
                    return
                }

                if dataSource.options.contains(.diffable) {
                    let oldRoots = dataSource.rootNode.map { [$0] } ?? []
                    let newRoots = [newRoot]
                    let changeset = StagedChangeset(source: oldRoots, target: newRoots)
                    if changeset.isEmpty {
                        dataSource.rootNode = newRoot
                        return
                    }
                    outlineView.reload(using: changeset, with: [], inParent: nil) { changeset in
                        !changeset.isOutlineViewSafe
                            || changeset.totalElementChangeCount > dataSource.animatedReloadThreshold
                    } setData: {
                        dataSource.rootNode = $0.first
                    }
                } else {
                    dataSource.rootNode = newRoot
                    outlineView.reloadData()
                }
            }

            if dataSource.options.contains(.reorderable), dataSource.pendingDragOperation != nil {
                DispatchQueue.main.async(execute: applyUpdate)
            } else {
                applyUpdate()
            }
        }.on(observedEvent)
    }
}
