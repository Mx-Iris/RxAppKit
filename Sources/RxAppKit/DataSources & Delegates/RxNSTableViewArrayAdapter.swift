import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

open class RxNSTableViewArrayAdapter<T: Differentiable>: TableViewAdapter<T>, RxNSTableViewDataSourceType, RxNSTableViewDelegateType {
    
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
            let oldItems = dataSource.items
            let changeset = StagedChangeset(source: oldItems, target: newItems)
            tableView.reload(using: changeset, with: []) {
                dataSource.items = $0
            }
        }.on(observedEvent)
    }
}
