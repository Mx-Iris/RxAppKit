import AppKit
import RxSwift
import RxCocoa

open class TableViewArrayAdapter<T>: NSObject, NSTableViewDataSource, NSTableViewDelegate, RowsViewDataSourceType {
    public typealias CellViewProvider = (_ tableView: NSTableView, _ tableColumn: NSTableColumn?, _ row: Int, _ item: T) -> NSView?
    public typealias RowViewProvider = (_ tableView: NSTableView, _ row: Int, _ items: [T]) -> NSTableRowView

    public let cellViewProvider: CellViewProvider
    public let rowViewProvider: RowViewProvider?

    public internal(set) var items: [T] = []

    public init(
        cellViewProvider: @escaping CellViewProvider,
        rowViewProvider: RowViewProvider?
    ) {
        self.cellViewProvider = cellViewProvider
        self.rowViewProvider = rowViewProvider
        super.init()
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
}
