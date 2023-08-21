import AppKit
import RxSwift
import DifferenceKit

open class RxNSTableViewArrayAdapter<T: Hashable>: TableViewAdapter<T>, RxNSTableViewDataSourceType {
    public typealias Element = [T]

    public var items: [T] = []

    open override func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }

    open override func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return cellProvider(tableView, tableColumn, row, items[row])
    }

    open override func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return rowProvider(tableView, row, [items[row]])
    }

    open func tableView(_ tableView: NSTableView, observedEvent: Event<Element>) {
        Binder(self) { dataSource, newItems in
            let oldItems = dataSource.items.map { AnyDifferentiable($0) }
            let newItems = newItems.map { AnyDifferentiable($0) }
            let changeset = StagedChangeset(source: oldItems, target: newItems)
            tableView.reload(using: changeset, with: []) {
                dataSource.items = $0.map { $0.base }
            }
        }.on(observedEvent)
    }
}
