import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

extension NSTableView: HasDoubleAction {}

public typealias TableIndexSet = (rowIndexes: IndexSet, columnIndexes: IndexSet)

public typealias TableIndex = (row: Int, column: Int)

public extension Reactive where Base: NSTableView {
    typealias CellProvider<Item: Differentiable> = (_ tableView: NSTableView, _ tableColumn: NSTableColumn?, _ row: Int, _ item: Item) -> NSView?

    var dataSource: DelegateProxy<NSTableView, NSTableViewDataSource> {
        RxNSTableViewDataSourceProxy.proxy(for: base)
    }

    var delegate: DelegateProxy<NSTableView, NSTableViewDelegate> {
        _delegate
    }

    private var _delegate: RxNSTableViewDelegateProxy {
        RxNSTableViewDelegateProxy.proxy(for: base)
    }

    func setDelegate(_ delegate: NSTableViewDelegate) -> Disposable {
        RxNSTableViewDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    func items<Element: Differentiable, Source: ObservableType>(_ source: Source)
        -> (@escaping CellProvider<Element>)
        -> Disposable where Source.Element == [Element] {
        return { cellProvider in
            let adapter = RxNSTableViewArrayAdapter<Element>(cellProvider: cellProvider)
            return self.items(adapter: adapter)(source)
        }
    }

    func items<Source: ObservableType, Adapter: RxNSTableViewDataSourceType & NSTableViewDataSource & NSTableViewDelegate>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Source.Element == Adapter.Element {
        return { source in
            self._delegate.setRequiredMethodsDelegate(adapter)
            let dataSourceSubscription = source.subscribeProxyDataSource(ofObject: base, dataSource: adapter, retainDataSource: true) { [weak tableView = self.base] (_: RxNSTableViewDataSourceProxy, event) in
                guard let tableView = tableView else { return }
                adapter.tableView(tableView, observedEvent: event)
            }
            return Disposables.create([dataSourceSubscription])
        }
    }

    var didDoubleClick: ControlEvent<TableIndex> {
        controlEventForDoubleAction { ($0.clickedRow, $0.clickedColumn) }
    }

    var didClick: ControlEvent<TableIndex> {
        controlEventForBaseAction { ($0.clickedRow, $0.clickedColumn) }
    }

    var didAddRow: ControlEvent<(rowView: NSTableRowView, row: Int)> {
        let source = delegate.methodInvoked(#selector(NSTableViewDelegate.tableView(_:didAdd:forRow:)))
            .map { a -> (rowView: NSTableRowView, row: Int) in
                try (castOrThrow(NSTableRowView.self, a[1]), castOrThrow(Int.self, a[2]))
            }
        return ControlEvent(events: source)
    }

    var didRemoveRow: ControlEvent<(rowView: NSTableRowView, row: Int)> {
        let source = delegate.methodInvoked(#selector(NSTableViewDelegate.tableView(_:didRemove:forRow:)))
            .map { a -> (rowView: NSTableRowView, row: Int) in
                try (castOrThrow(NSTableRowView.self, a[1]), castOrThrow(Int.self, a[2]))
            }
        return ControlEvent(events: source)
    }

    var didClickColumn: ControlEvent<NSTableColumn> {
        let source = delegate.methodInvoked(#selector(NSTableViewDelegate.tableView(_:didClick:)))
            .map { a -> NSTableColumn in
                try castOrThrow(NSTableColumn.self, a[1])
            }
        return ControlEvent(events: source)
    }

    var didDragColumn: ControlEvent<NSTableColumn> {
        let source = delegate.methodInvoked(#selector(NSTableViewDelegate.tableView(_:didDrag:)))
            .map { a -> NSTableColumn in
                try castOrThrow(NSTableColumn.self, a[1])
            }
        return ControlEvent(events: source)
    }
}
