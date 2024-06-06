import AppKit

open class TableViewArrayAdapter<T>: NSObject, NSTableViewDataSource, NSTableViewDelegate, RowsViewDataSourceType {
    public typealias CellViewProvider = (_ tableView: NSTableView, _ tableColumn: NSTableColumn?, _ row: Int, _ item: T) -> NSView?
    public typealias RowViewProvider = (_ tableView: NSTableView, _ row: Int, _ items: [T]) -> NSTableRowView

    open var cellProvider: CellViewProvider
    open var rowProvider: RowViewProvider

    public internal(set) var items: [T] = []

    public init(
        cellProvider: @escaping CellViewProvider,
        rowProvider: @escaping RowViewProvider
    ) {
        self.cellProvider = cellProvider
        self.rowProvider = rowProvider
        super.init()
    }

    open func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }

    open func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return cellProvider(tableView, tableColumn, row, items[row])
    }

    open func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return rowProvider(tableView, row, [items[row]])
    }
    
    public func model(at row: Int) throws -> Any {
        items[row]
    }
}
