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


open class RxNSTableViewArrayAnimatedAdapter<T: Differentiable>: TableViewArrayAdapter<T>, RxNSTableViewDataSourceType {
    public typealias Element = [T]
    public typealias DecideViewTransition = (TableViewArrayAdapter<T>, NSTableView, Changeset<[T]>) -> ViewTransition
    public var animationConfiguration: TableViewAnimationConfiguration
    
    public var decideViewTransition: DecideViewTransition
    
    public init(
        animationConfiguration: TableViewAnimationConfiguration,
        decideViewTransition: @escaping DecideViewTransition = { _, _, _ in .animated },
        cellProvider: @escaping TableViewArrayAdapter<T>.CellViewProvider,
        rowProvider: @escaping TableViewArrayAdapter<T>.RowViewProvider
    ) {
        self.animationConfiguration = animationConfiguration
        self.decideViewTransition =  decideViewTransition
        super.init(cellProvider: cellProvider, rowProvider: rowProvider)
    }
    /// there is no longer limitation to load initial sections with reloadData
    /// but it is kept as a feature everyone got used to
    var dataSet = false
    
    open func tableView(_ tableView: NSTableView, observedEvent: Event<Element>) {
        Binder<Element>(self) { dataSource, newItems in
            if !dataSource.dataSet {
                dataSource.dataSet = true
                dataSource.items = newItems
                tableView.reloadData()
            } else {
                let oldItems = dataSource.items
                let newItems = newItems
                let changeset = StagedChangeset(source: oldItems, target: newItems)
                tableView.reload(
                    using: changeset,
                    deleteRowsAnimation: self.animationConfiguration.deleteAnimation,
                    insertRowsAnimation: self.animationConfiguration.insertAnimation,
                    reloadRowsAnimation: self.animationConfiguration.reloadAnimation
                ) { changeset in
                    switch self.decideViewTransition(dataSource, tableView, changeset) {
                    case .animated:
                        return false
                    case .reload:
                        return true
                    }
                } setData: {
                    dataSource.items = $0
                }
            }
        }.on(observedEvent)
    }
}