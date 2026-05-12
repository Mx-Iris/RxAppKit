import AppKit
import DifferenceKit

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
