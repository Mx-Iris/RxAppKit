import AppKit
import RxSwift
import RxCocoa

open class TableViewAdapter<T>: NSObject, NSTableViewDataSource, NSTableViewDelegate, RowsViewDataSourceType, RxNSTableViewProposedSelectionEmitting {
    public typealias CellViewProvider = (_ tableView: NSTableView, _ tableColumn: NSTableColumn?, _ row: Int, _ item: T) -> NSView?
    public typealias RowViewProvider = (_ tableView: NSTableView, _ row: Int, _ items: [T]) -> NSTableRowView

    public let cellViewProvider: CellViewProvider
    public let rowViewProvider: RowViewProvider?

    public internal(set) var items: [T] = []

    let _proposedSelection = PublishSubject<NSTableView.ProposedSelection>()

    public init(
        cellViewProvider: @escaping CellViewProvider,
        rowViewProvider: RowViewProvider?
    ) {
        self.cellViewProvider = cellViewProvider
        self.rowViewProvider = rowViewProvider
        super.init()
    }

    deinit {
        _proposedSelection.onCompleted()
    }

    open func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }

    open func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return cellViewProvider(tableView, tableColumn, row, items[row])
    }

    open func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return rowViewProvider?(tableView, row, [items[row]])
    }

    public func model(at row: Int) throws -> Any {
        items[row]
    }

    // MARK: - User-initiated selection

    /// AppKit invokes this only for user-driven selection changes (mouse,
    /// keyboard, type-select). Emitting here lets `Reactive.proposedSelection()`
    /// expose a clean stream without the programmatic-selection noise that
    /// `selectionDidChangeNotification` carries.
    open func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        _proposedSelection.onNext(.init(indexes: proposedSelectionIndexes, triggeringEvent: tableView.window?.currentEvent))
        return proposedSelectionIndexes
    }
}
