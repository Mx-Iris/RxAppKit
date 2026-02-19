import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

extension NSTableView: HasDoubleAction {}

public typealias TableIndexSet = (rowIndexes: IndexSet, columnIndexes: IndexSet)

public typealias TableIndex = (row: Int, column: Int)

public typealias TableCellProvider<Item: Differentiable> = (_ tableView: NSTableView, _ tableColumn: NSTableColumn?, _ row: Int, _ item: Item) -> NSView?

public typealias TableRowProvider<Item: Differentiable> = (_ tableView: NSTableView, _ row: Int, _ items: [Item]) -> NSTableRowView

extension Reactive where Base: NSTableView {

    private var _tableViewDelegate: RxNSTableViewDelegateProxy {
        .proxy(for: base)
    }

    public var tableViewDelegate: DelegateProxy<NSTableView, NSTableViewDelegate> {
        _tableViewDelegate
    }

    public func setDataSource(_ dataSource: NSTableViewDataSource) -> Disposable {
        RxNSTableViewDataSourceProxy.installForwardDelegate(dataSource, retainDelegate: false, onProxyForObject: base)
    }

    public func setDelegate(_ delegate: NSTableViewDelegate) -> Disposable {
        RxNSTableViewDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    public func items<Element: Differentiable, Source: ObservableType>(_ source: Source)
        -> (_ cellProvider: @escaping TableCellProvider<Element>)
        -> Disposable where Source.Element == [Element] {
        return { cellProvider in
            return self.items(source)(cellProvider, nil)
        }
    }

    public func items<Element: Differentiable, Source: ObservableType>(_ source: Source)
        -> (_ cellProvider: @escaping TableCellProvider<Element>, _ rowProvider: TableRowProvider<Element>?)
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

    /// Binds an observable source to a reorderable adapter, automatically registering the table view for drag-and-drop reordering.
    public func reorderableItems<Element: Differentiable, Source: ObservableType>(_ source: Source)
        -> (_ cellProvider: @escaping TableCellProvider<Element>)
        -> Disposable where Source.Element == [Element] {
        return { cellProvider in
            self.reorderableItems(source)(cellProvider, nil)
        }
    }

    /// Binds an observable source to a reorderable adapter, automatically registering the table view for drag-and-drop reordering.
    public func reorderableItems<Element: Differentiable, Source: ObservableType>(_ source: Source)
        -> (_ cellProvider: @escaping TableCellProvider<Element>, _ rowProvider: TableRowProvider<Element>?)
        -> Disposable where Source.Element == [Element] {
        return { cellProvider, rowProvider in
            let adapter = RxNSReorderableTableViewArrayReloadAdapter<Element>(cellProvider: cellProvider, rowProvider: rowProvider)
            return self.reorderableItems(adapter: adapter)(source)
        }
    }

    /// Binds an observable source to a reorderable adapter, automatically registering the table view for drag-and-drop reordering.
    public func reorderableItems<Source: ObservableType, Adapter: RxNSTableViewDataSourceType & RxNSTableViewReorderableDataSourceType & NSTableViewDataSource & NSTableViewDelegate>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Source.Element == Adapter.Element {
        return { source in
            adapter.setupReordering(for: base)
            let dataSourceSubscription = source.subscribeProxyDataSource(ofObject: base, dataSource: adapter, retainDataSource: true) { [weak tableView = base] (_: RxNSTableViewReorderableDataSourceProxy, event) in
                guard let tableView else { return }
                adapter.tableView(tableView, observedEvent: event)
            }
            let delegateSubscription = RxNSTableViewDelegateProxy.installRequiredMethodDelegate(adapter, retainDelegate: false, onProxyForObject: base)
            return Disposables.create([dataSourceSubscription, delegateSubscription])
        }
    }

    /// Emits source and destination indexes when items have been reordered via drag-and-drop.
    public func itemMoved() -> ControlEvent<(sourceIndexes: IndexSet, destinationIndex: Int)> {
        let source = Observable<(sourceIndexes: IndexSet, destinationIndex: Int)>.deferred { [weak base] in
            let adapter = (base?.dataSource as? RxNSTableViewDataSourceProxy)?._requiredMethodsDelegate.object
            return (adapter as? RxNSTableViewReorderableDataSourceType)?.itemMoved.asObservable()
                ?? Observable.empty()
        }
        return ControlEvent(events: source)
    }

    /// Emits the new complete items array after drag-and-drop reordering.
    /// Use this to sync your upstream data source (e.g. `BehaviorRelay`).
    public func modelMoved<T>() -> ControlEvent<[T]> {
        let source = Observable<[T]>.deferred { [weak base] in
            let adapter = (base?.dataSource as? RxNSTableViewDataSourceProxy)?._requiredMethodsDelegate.object
            return (adapter as? RxNSTableViewReorderableDataSourceType)?.modelMoved.compactMap { $0 as? [T] }.asObservable()
                ?? Observable.empty()
        }
        return ControlEvent(events: source)
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
            guard let view, view.isValidRowIndex(clickedIndex.row) else { return nil }
            return try view.rx.model(at: clickedIndex.row)
        }
        return ControlEvent(events: source)
    }

    public func model<T>(at row: Int) throws -> T {
        let adapter = (base.dataSource as? RxNSTableViewDataSourceProxy)?._requiredMethodsDelegate.object
        let dataSource: RowsViewDataSourceType = castOrFatalError(adapter, message: "This method only works in case one of the `rx.items*` methods was used.")
        let element = try dataSource.model(at: row)
        return castOrFatalError(element)
    }
}

extension NSTableView {
    var hasValidSelectedRow: Bool {
        isValidRowIndex(selectedRow)
    }

    var hasValidSelectedColumn: Bool {
        isValidColumnIndex(selectedColumn)
    }

    var hasValidClickedRow: Bool {
        isValidRowIndex(clickedRow)
    }

    var hasValidClickedColumn: Bool {
        isValidColumnIndex(clickedColumn)
    }

    var hasValidClickedIndex: Bool {
        isValidTableIndex((clickedRow, clickedColumn))
    }

    var hasValidSelectedIndex: Bool {
        isValidTableIndex((selectedRow, selectedColumn))
    }

    func isValidRowIndex(_ row: Int) -> Bool {
        row >= 0 && row < numberOfRows
    }

    func isValidColumnIndex(_ column: Int) -> Bool {
        column >= 0 && column < numberOfColumns
    }

    func isValidTableIndex(_ tableIndex: TableIndex) -> Bool {
        isValidRowIndex(tableIndex.row) && isValidColumnIndex(tableIndex.column)
    }
}

extension Observable {
    func asControlEvent() -> ControlEvent<Element> {
        .init(events: self)
    }
}
