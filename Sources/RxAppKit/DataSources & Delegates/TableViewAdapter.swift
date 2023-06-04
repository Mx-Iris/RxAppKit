import AppKit

open class TableViewAdapter<T>: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    public typealias CellProvider = (_ tableView: NSTableView, _ tableColumn: NSTableColumn?, _ row: Int, _ item: T) -> NSView?

    public typealias RowProvider = (_ tableView: NSTableView, _ row: Int, _ items: [T]) -> NSTableRowView

    open var cellProvider: CellProvider

    open var rowProvider: RowProvider

    public init(
        cellProvider: @escaping CellProvider,
        rowProvider: @escaping RowProvider = { _, _, _ in NSTableRowView() }
    ) {
        self.cellProvider = cellProvider
        self.rowProvider = rowProvider
        super.init()
    }
    
    open func numberOfRows(in tableView: NSTableView) -> Int {
//        return 0
        rxAbstractMethod()
    }
    
    open func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
//        return nil
        rxAbstractMethod()
    }
    
    open func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
//        return nil
        rxAbstractMethod()
    }

}
