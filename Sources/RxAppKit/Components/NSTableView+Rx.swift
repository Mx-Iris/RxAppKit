import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

extension NSTableView: HasDoubleAction {}

public typealias TableIndexSet = (rowIndexes: IndexSet, columnIndexes: IndexSet)

public typealias TableIndex = (row: Int, column: Int)

public extension Reactive where Base: NSTableView {
    
    typealias CellProvider<Item: Hashable> = (_ tableView: NSTableView, _ tableColumn: NSTableColumn?, _ row: Int, _ item: Item) -> NSView?
    typealias RowProvider<Item: Hashable> = (_ tableView: NSTableView, _ row: Int, _ items: [Item]) -> NSTableRowView
    
    var tableViewDataSource: DelegateProxy<NSTableView, NSTableViewDataSource> {
        RxNSTableViewDataSourceProxy.proxy(for: base)
    }

    var tableViewDelegate: DelegateProxy<NSTableView, NSTableViewDelegate> {
        RxNSTableViewDelegateProxy.proxy(for: base)
    }

    func setDelegate(_ delegate: NSTableViewDelegate) -> Disposable {
        RxNSTableViewDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    func items<Element: Hashable, Source: ObservableType>(_ source: Source)
        -> (_ cellProvider: @escaping CellProvider<Element>)
        -> Disposable where Source.Element == [Element] {
        return { cellProvider in
            return self.items(source)(cellProvider, { _, _, _ in NSTableRowView() })
        }
    }

    func items<Element: Hashable, Source: ObservableType>(_ source: Source)
        -> (_ cellProvider: @escaping CellProvider<Element>, _ rowProvider: @escaping RowProvider<Element>)
        -> Disposable where Source.Element == [Element] {
        return { cellProvider, rowProvider in
            let adapter = RxNSTableViewArrayAdapter<Element>(cellProvider: cellProvider, rowProvider: rowProvider)
            return self.items(adapter: adapter)(source)
        }
    }

    func items<Source: ObservableType, Adapter: RxNSTableViewDataSourceType & NSTableViewDataSource & NSTableViewDelegate>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Source.Element == Adapter.Element {
        return { source in
            let dataSourceSubscription = source.subscribeProxyDataSource(ofObject: base, dataSource: adapter, retainDataSource: true) { [weak tableView = self.base] (_: RxNSTableViewDataSourceProxy, event) in
                guard let tableView = tableView else { return }
                adapter.tableView(tableView, observedEvent: event)
            }
            let delegateSubscription = RxNSTableViewDelegateProxy.proxy(for: base).setRequiredMethodsDelegate(adapter)
            return Disposables.create([dataSourceSubscription, delegateSubscription])
        }
    }

    var didDoubleClick: ControlEvent<TableIndex> {
        controlEventForDoubleAction { ($0.clickedRow, $0.clickedColumn) }
    }

    var didClick: ControlEvent<TableIndex> {
        controlEventForBaseAction { ($0.clickedRow, $0.clickedColumn) }
    }

    var didSelect: ControlEvent<TableIndex> {
        controlEventForBaseAction { ($0.selectedRow, $0.selectedColumn) }
    }

    var didAddRow: ControlEvent<(rowView: NSTableRowView, row: Int)> {
        let source = tableViewDelegate.methodInvoked(#selector(NSTableViewDelegate.tableView(_:didAdd:forRow:)))
            .map { a -> (rowView: NSTableRowView, row: Int) in
                try (castOrThrow(NSTableRowView.self, a[1]), castOrThrow(Int.self, a[2]))
            }
        return ControlEvent(events: source)
    }

    var didRemoveRow: ControlEvent<(rowView: NSTableRowView, row: Int)> {
        let source = tableViewDelegate.methodInvoked(#selector(NSTableViewDelegate.tableView(_:didRemove:forRow:)))
            .map { a -> (rowView: NSTableRowView, row: Int) in
                try (castOrThrow(NSTableRowView.self, a[1]), castOrThrow(Int.self, a[2]))
            }
        return ControlEvent(events: source)
    }

    var didClickColumn: ControlEvent<NSTableColumn> {
        let source = tableViewDelegate.methodInvoked(#selector(NSTableViewDelegate.tableView(_:didClick:)))
            .map { a -> NSTableColumn in
                try castOrThrow(NSTableColumn.self, a[1])
            }
        return ControlEvent(events: source)
    }

    var didDragColumn: ControlEvent<NSTableColumn> {
        let source = tableViewDelegate.methodInvoked(#selector(NSTableViewDelegate.tableView(_:didDrag:)))
            .map { a -> NSTableColumn in
                try castOrThrow(NSTableColumn.self, a[1])
            }
        return ControlEvent(events: source)
    }
}
