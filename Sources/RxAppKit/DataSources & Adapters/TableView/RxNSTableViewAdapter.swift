import AppKit
import RxSwift
import DifferenceKit

/// Rx data source adapter for `NSTableView` that maps an observable
/// sequence of items (`[T]`) onto the table view. See
/// `RxNSTableViewAdapterOptions` for the supported behavior combinations.
open class RxNSTableViewAdapter<T: Differentiable>:
    ReorderableTableViewAdapter<T>,
    RxNSTableViewDataSourceType {
    public typealias Element = [T]

    public let options: RxNSTableViewAdapterOptions

    public init(
        options: RxNSTableViewAdapterOptions = [],
        cellViewProvider: @escaping CellViewProvider,
        rowViewProvider: RowViewProvider? = nil
    ) {
        self.options = options
        super.init(cellViewProvider: cellViewProvider, rowViewProvider: rowViewProvider)
        if !options.contains(.reorderable) {
            isReorderingEnabled = false
        }
        // Diffable drops animate through the binding pipeline (override + round-trip);
        // reload drops commit immediately inside `acceptDrop`.
        reorderCommitStrategy = options.contains(.diffable) ? .deferredToBinding : .immediate
    }

    open override func setupReordering(for tableView: NSTableView) {
        guard options.contains(.reorderable) else { return }
        super.setupReordering(for: tableView)
    }

    open func tableView(_ tableView: NSTableView, observedEvent: Event<Element>) {
        Binder<Element>(self) { (dataSource: RxNSTableViewAdapter<T>, newItems) in
            if dataSource.options.contains(.reorderable) {
                dataSource.setupReordering(for: tableView)
            }

            if dataSource.options.contains(.diffable) {
                // Diffable: a drop stages the new ordering as an override
                // (see `ReorderableTableViewAdapter`); the upstream emission is
                // applied here through a StagedChangeset. Clear any pending drag
                // override first so the diff runs against the committed `items`.
                let hadOverride = dataSource.hasItemsOverride
                dataSource.resetReorderingState()

                let changeset = StagedChangeset(source: dataSource.items, target: newItems)
                if changeset.isEmpty {
                    if hadOverride { tableView.reloadData() }
                    return
                }
                tableView.reload(using: changeset, with: []) { _ in
                    return true
                } setData: {
                    dataSource.items = $0
                }
            } else {
                // Reload: a drop is already committed in `acceptDrop`. An upstream
                // emission simply replaces the data and reloads (idempotent when
                // it echoes a just-applied drop via `modelMoved`).
                dataSource.items = newItems
                tableView.reloadData()
            }
        }.on(observedEvent)
    }
}
