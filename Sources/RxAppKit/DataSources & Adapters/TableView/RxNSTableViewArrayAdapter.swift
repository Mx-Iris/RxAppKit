import AppKit
import RxSwift
import DifferenceKit

open class RxNSTableViewArrayReloadAdapter<T: Differentiable>: TableViewArrayAdapter<T>, RxNSTableViewDataSourceType {
    public typealias Element = [T]
    
    open func tableView(_ tableView: NSTableView, observedEvent: Event<Element>) {
        Binder(self) { dataSource, newItems in
            let oldItems = dataSource.items
            let newItems = newItems
            let changeset = StagedChangeset(source: oldItems, target: newItems)
            tableView.reload(using: changeset, with: []) { _ in
                return true
            } setData: {
                dataSource.items = $0
            }
        }.on(observedEvent)
    }
}

