import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

open class RxNSOutlineViewRootNodeAdapter<OutlineNode: OutlineNodeType & Hashable & Differentiable>: OutlineViewAdapter<OutlineNode>, RxNSOutlineViewDataSourceType {
    public typealias Element = OutlineNode

    open func outlineView(_ outlineView: NSOutlineView, observedEvent: Event<Element>) {
        Binder<Element>(self) { (dataSource: RxNSOutlineViewRootNodeAdapter<OutlineNode>, rootNode) in
            dataSource.rootNode = rootNode
            outlineView.reloadData()
        }.on(observedEvent)
    }
}

open class RxNSOutlineViewAdapter<OutlineNode: OutlineNodeType & Hashable & Differentiable>: OutlineViewAdapter<OutlineNode>, RxNSOutlineViewDataSourceType {
    public typealias Element = [OutlineNode]

    open func outlineView(_ outlineView: NSOutlineView, observedEvent: Event<Element>) {
        Binder<Element>(self) { (dataSource: RxNSOutlineViewAdapter<OutlineNode>, newNodes) in
            dataSource.nodes = newNodes
            outlineView.reloadData()
        }.on(observedEvent)
    }
}

open class RxNSReorderableOutlineViewAdapter<OutlineNode: OutlineNodeType & Hashable & Differentiable>: ReorderableOutlineViewAdapter<OutlineNode>, RxNSOutlineViewDataSourceType {
    public typealias Element = [OutlineNode]

    open func outlineView(_ outlineView: NSOutlineView, observedEvent: Event<Element>) {
        Binder<Element>(self) { (dataSource: RxNSReorderableOutlineViewAdapter<OutlineNode>, newNodes) in
            // Skip reload when data is unchanged (e.g. reorder feedback loop)
            guard dataSource.nodes != newNodes || dataSource.hasReorderingOverrides else { return }
            dataSource.resetReorderingState()
            dataSource.nodes = newNodes
            outlineView.reloadData()
        }.on(observedEvent)
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
        inParent parent: Any? = nil,
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
        inParent parent: Any? = nil,
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        setData: (C) -> Void
    ) {
        if case .none = window, let data = stagedChangeset.last?.data {
            setData(data)
            return reloadData()
        }

        for changeset in stagedChangeset {
            if let interrupt = interrupt, interrupt(changeset), let data = stagedChangeset.last?.data {
                setData(data)
                return reloadData()
            }

            beginUpdates()

            // Snapshot items to reload BEFORE updating data source,
            // because the outline view only recognizes old item references.
            let itemsToReload = changeset.elementUpdated.map { child($0.element, ofItem: parent) }

            setData(changeset.data)

            if !changeset.elementDeleted.isEmpty {
                removeItems(at: IndexSet(changeset.elementDeleted.map { $0.element }), inParent: parent, withAnimation: deleteItemsAnimation())
            }

            for item in itemsToReload {
                reloadItem(item)
            }

            if !changeset.elementMoved.isEmpty {
                let insertionIndices = IndexSet(changeset.elementInserted.map { $0.element })
                var movedSourceIndices = IndexSet()

                for (source, target) in changeset.elementMoved {
                    let sourceElementOffset = movedSourceIndices.count(in: source.element...)
                    let targetElementOffset = insertionIndices.count(in: 0 ..< target.element)

                    moveItem(at: source.element + sourceElementOffset, inParent: parent, to: target.element - targetElementOffset, inParent: parent)

                    movedSourceIndices.insert(source.element)
                }
            }

            if !changeset.elementInserted.isEmpty {
                insertItems(at: IndexSet(changeset.elementInserted.map { $0.element }), inParent: parent, withAnimation: insertItemsAnimation())
            }

            endUpdates()
        }
    }
}
