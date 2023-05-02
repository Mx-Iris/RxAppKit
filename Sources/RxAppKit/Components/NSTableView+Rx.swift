import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

extension NSTableView: HasDoubleAction {}

public extension Reactive where Base: NSTableView {
    typealias CellProvider<Item: Differentiable> = (_ tableView: NSTableView, _ tableColumn: NSTableColumn?, _ row: Int, _ item: Item) -> NSView?

    var doubleClick: ControlEvent<(clickedRow: Int, clickedColumn: Int)> {
        controlEventForDoubleAction { ($0.clickedRow, $0.clickedColumn) }
    }

    var dataSource: DelegateProxy<NSTableView, NSTableViewDataSource> {
        RxNSTableViewDataSourceProxy.proxy(for: base)
    }

    var delegate: RxNSTableViewDelegateProxy {
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
            self.delegate.setRequiredMethodsDelegate(adapter)
            let dataSourceSubscription = source.subscribeProxyDataSource(ofObject: base, dataSource: adapter, retainDataSource: true) { [weak tableView = self.base] (_: RxNSTableViewDataSourceProxy, event) in
                guard let tableView = tableView else { return }
                adapter.tableView(tableView, observedEvent: event)
            }
            return Disposables.create([dataSourceSubscription])
        }
    }

    var itemSelected: ControlEvent<(selectedRowIndexes: IndexSet, selectedColumnIndexes: IndexSet)> {
        let source = delegate.methodInvoked(#selector(NSTableViewDelegate.tableViewSelectionDidChange(_:)))
            .map { a -> (selectedRowIndexes: IndexSet, selectedColumnIndexes: IndexSet) in
                let note = try castOrThrow(Notification.self, a[0])
                let tableView = (note.object as! NSTableView)
                return (tableView.selectedRowIndexes, tableView.selectedColumnIndexes)
            }
        return ControlEvent(events: source)
    }

    var itemAdded: ControlEvent<(rowView: NSTableRowView, row: Int)> {
        let source = delegate.methodInvoked(#selector(NSTableViewDelegate.tableView(_:didAdd:forRow:)))
            .map { a -> (rowView: NSTableRowView, row: Int) in
                (try castOrThrow(NSTableRowView.self, a[1]), try castOrThrow(Int.self, a[2]))
            }
        return ControlEvent(events: source)
    }

    var itemRemoved: ControlEvent<(rowView: NSTableRowView, row: Int)> {
        let source = delegate.methodInvoked(#selector(NSTableViewDelegate.tableView(_:didRemove:forRow:)))
            .map { a -> (rowView: NSTableRowView, row: Int) in
                (try castOrThrow(NSTableRowView.self, a[1]), try castOrThrow(Int.self, a[2]))
            }
        return ControlEvent(events: source)
    }
}
