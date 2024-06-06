import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

extension NSTableView: HasDoubleAction {}

public typealias TableIndexSet = (rowIndexes: IndexSet, columnIndexes: IndexSet)

public typealias TableIndex = (row: Int, column: Int)

extension Reactive where Base: NSTableView {
    public typealias CellProvider<Item: Differentiable> = (_ tableView: NSTableView, _ tableColumn: NSTableColumn?, _ row: Int, _ item: Item) -> NSView?
    public typealias RowProvider<Item: Differentiable> = (_ tableView: NSTableView, _ row: Int, _ items: [Item]) -> NSTableRowView

    public var tableViewDataSource: DelegateProxy<NSTableView, NSTableViewDataSource> {
        RxNSTableViewDataSourceProxy.proxy(for: base)
    }

    public var tableViewDelegate: DelegateProxy<NSTableView, NSTableViewDelegate> {
        RxNSTableViewDelegateProxy.proxy(for: base)
    }

    public func setDataSource(_ dataSource: NSTableViewDataSource) -> Disposable {
        RxNSTableViewDataSourceProxy.installForwardDelegate(dataSource, retainDelegate: false, onProxyForObject: base)
    }

    public func setDelegate(_ delegate: NSTableViewDelegate) -> Disposable {
        RxNSTableViewDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    public func items<Element: Differentiable, Source: ObservableType>(_ source: Source)
        -> (_ cellProvider: @escaping CellProvider<Element>)
        -> Disposable where Source.Element == [Element] {
        return { cellProvider in
            return self.items(source)(cellProvider, { _, _, _ in NSTableRowView() })
        }
    }

    public func items<Element: Differentiable, Source: ObservableType>(_ source: Source)
        -> (_ cellProvider: @escaping CellProvider<Element>, _ rowProvider: @escaping RowProvider<Element>)
        -> Disposable where Source.Element == [Element] {
        return { cellProvider, rowProvider in
            let adapter = RxNSTableViewArrayReloadAdapter<Element>(cellProvider: cellProvider, rowProvider: rowProvider)
            return self.items(adapter: adapter)(source)
        }
    }

    public func items<Source: ObservableType, Adapter: RxNSTableViewDataSourceType & NSTableViewDataSource & NSTableViewDelegate>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Source.Element == Adapter.Element {
        return { source in
            let dataSourceSubscription = source.subscribeProxyDataSource(ofObject: base, dataSource: adapter, retainDataSource: true) { [weak tableView = self.base] (_: RxNSTableViewDataSourceProxy, event) in
                guard let tableView else { return }
                adapter.tableView(tableView, observedEvent: event)
            }
            let delegateSubscription = RxNSTableViewDelegateProxy.installRequiredMethodDelegate(adapter, retainDelegate: false, onProxyForObject: base)
            return Disposables.create([dataSourceSubscription, delegateSubscription])
        }
    }

    public func itemDoubleClicked() -> ControlEvent<TableIndex> {
        _controlEventForDoubleAction { ($0.clickedRow, $0.clickedColumn) }
    }

    public func itemClicked() -> ControlEvent<TableIndex> {
        _controlEventForBaseAction { ($0.clickedRow, $0.clickedColumn) }
    }

    public func itemSelected() -> ControlEvent<TableIndex> {
        _controlEventForBaseAction { ($0.selectedRow, $0.selectedColumn) }
    }

    public func didAddRow() -> ControlEvent<(rowView: NSTableRowView, row: Int)> {
        let source = tableViewDelegate.methodInvoked(#selector(NSTableViewDelegate.tableView(_:didAdd:forRow:)))
            .map { a -> (rowView: NSTableRowView, row: Int) in
                try (castOrThrow(NSTableRowView.self, a[1]), castOrThrow(Int.self, a[2]))
            }
        return ControlEvent(events: source)
    }

    public func didRemoveRow() -> ControlEvent<(rowView: NSTableRowView, row: Int)> {
        let source = tableViewDelegate.methodInvoked(#selector(NSTableViewDelegate.tableView(_:didRemove:forRow:)))
            .map { a -> (rowView: NSTableRowView, row: Int) in
                try (castOrThrow(NSTableRowView.self, a[1]), castOrThrow(Int.self, a[2]))
            }
        return ControlEvent(events: source)
    }

    public func didClickColumn() -> ControlEvent<NSTableColumn> {
        let source = tableViewDelegate.methodInvoked(#selector(NSTableViewDelegate.tableView(_:didClick:)))
            .map { a -> NSTableColumn in
                try castOrThrow(NSTableColumn.self, a[1])
            }
        return ControlEvent(events: source)
    }

    public func didDragColumn() -> ControlEvent<NSTableColumn> {
        let source = tableViewDelegate.methodInvoked(#selector(NSTableViewDelegate.tableView(_:didDrag:)))
            .map { a -> NSTableColumn in
                try castOrThrow(NSTableColumn.self, a[1])
            }
        return ControlEvent(events: source)
    }

    public func didScrollEnd() -> ControlEvent<(rowView: NSTableRowView, row: Int)> {
        let source = didAddRow().filter { $0.row == base.numberOfRows - 1 }
        return ControlEvent(events: source)
    }
    
    public func modelSelected<T>() -> ControlEvent<T> {
        let source = itemSelected().compactMap { [weak view = base] clickedIndex -> T? in
            guard let view else { return nil }
            return try view.rx.model(at: clickedIndex.row)
        }
        return ControlEvent(events: source)
    }
    
    public func model<T>(at row: Int) throws -> T {
        let dataSource: RowsViewDataSourceType = castOrFatalError(self.tableViewDataSource.forwardToDelegate(), message: "This method only works in case one of the `rx.items*` methods was used.")
        let element = try dataSource.model(at: row)
        return castOrFatalError(element)
    }
}
