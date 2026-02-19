import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

public typealias OutlineCellProvider<OutlineNode: OutlineNodeType & Differentiable & Hashable> = (_ outlineView: NSOutlineView, _ tableColumn: NSTableColumn?, _ node: OutlineNode) -> NSView?

public typealias OutlineRowProvider<OutlineNode: OutlineNodeType & Differentiable & Hashable> = (_ outlineView: NSOutlineView, _ node: OutlineNode) -> NSTableRowView?

extension Reactive where Base: NSOutlineView {
    private var _outlineViewDelegate: RxNSOutlineViewDelegateProxy {
        .proxy(for: base)
    }

    public var outlineViewDelegate: DelegateProxy<NSOutlineView, NSOutlineViewDelegate> {
        _outlineViewDelegate
    }

    public func setDataSource(_ dataSource: NSOutlineViewDataSource) -> Disposable {
        RxNSOutlineViewDataSourceProxy.installForwardDelegate(dataSource, retainDelegate: false, onProxyForObject: base)
    }

    public func setDelegate(_ delegate: NSOutlineViewDelegate) -> Disposable {
        RxNSOutlineViewDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    public func rootNode<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellProvider<OutlineNode>)
        -> Disposable
        where Source.Element == OutlineNode {
        return { viewForItem in
            self.rootNode(source: source)(viewForItem, nil)
        }
    }

    public func rootNode<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellProvider<OutlineNode>, OutlineRowProvider<OutlineNode>?)
        -> Disposable
        where Source.Element == OutlineNode {
        return { viewForItem, rowForItem in
            let adapter = RxNSOutlineViewRootNodeAdapter<OutlineNode>(viewForItem: viewForItem)
            if let rowForItem {
                adapter.rowForItem = rowForItem
            }
            return self.nodes(adapter: adapter)(source)
        }
    }

    public func nodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellProvider<OutlineNode>)
        -> Disposable
        where Source.Element == [OutlineNode] {
        return { viewForItem in
            self.nodes(source: source)(viewForItem, nil)
        }
    }

    public func nodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellProvider<OutlineNode>, OutlineRowProvider<OutlineNode>?)
        -> Disposable
        where Source.Element == [OutlineNode] {
        return { viewForItem, rowForItem in
            let adapter = RxNSOutlineViewAdapter<OutlineNode>(viewForItem: viewForItem)
            if let rowForItem {
                adapter.rowForItem = rowForItem
            }
            return self.nodes(adapter: adapter)(source)
        }
    }

    public func nodes<Source: ObservableType, Adapter: RxNSOutlineViewDataSourceType & NSOutlineViewDataSource & NSOutlineViewDelegate>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Source.Element == Adapter.Element {
        return { source in
            let dataSourceSubscription = source.subscribeProxyDataSource(ofObject: base, dataSource: adapter, retainDataSource: true) { [weak outlineView = base] (_: RxNSOutlineViewDataSourceProxy, event) in
                guard let outlineView = outlineView else { return }
                adapter.outlineView(outlineView, observedEvent: event)
            }
            let delegateSubscription = RxNSOutlineViewDelegateProxy.proxy(for: base).setRequiredMethodDelegate(adapter)
            return Disposables.create([dataSourceSubscription, delegateSubscription])
        }
    }

    /// Binds an observable source to a reorderable adapter, automatically registering the outline view for drag-and-drop reordering.
    public func reorderableNodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellProvider<OutlineNode>)
        -> Disposable
        where Source.Element == [OutlineNode] {
        return { viewForItem in
            self.reorderableNodes(source: source)(viewForItem, nil)
        }
    }

    /// Binds an observable source to a reorderable adapter, automatically registering the outline view for drag-and-drop reordering.
    public func reorderableNodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellProvider<OutlineNode>, OutlineRowProvider<OutlineNode>?)
        -> Disposable
        where Source.Element == [OutlineNode] {
        return { viewForItem, rowForItem in
            let adapter = RxNSReorderableOutlineViewAdapter<OutlineNode>(viewForItem: viewForItem)
            if let rowForItem {
                adapter.rowForItem = rowForItem
            }
            return self.reorderableNodes(adapter: adapter)(source)
        }
    }

    /// Binds an observable source to a reorderable adapter, automatically registering the outline view for drag-and-drop reordering.
    public func reorderableNodes<Source: ObservableType, Adapter: RxNSOutlineViewReorderableDataSourceType & RxNSOutlineViewDataSourceType & NSOutlineViewDataSource & NSOutlineViewDelegate>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Source.Element == Adapter.Element {
        return { source in
            adapter.setupReordering(for: self.base)
            let dataSourceSubscription = source.subscribeProxyDataSource(ofObject: base, dataSource: adapter, retainDataSource: true) { [weak outlineView = base] (_: RxNSOutlineViewReorderableDataSourceProxy, event) in
                guard let outlineView = outlineView else { return }
                adapter.outlineView(outlineView, observedEvent: event)
            }
            let delegateSubscription = RxNSOutlineViewDelegateProxy.proxy(for: base).setRequiredMethodDelegate(adapter)
            return Disposables.create([dataSourceSubscription, delegateSubscription])
        }
    }

    /// Emits move info when nodes have been reordered via drag-and-drop.
    /// This supports moving nodes across any level in the outline hierarchy.
    public func nodeMoved() -> ControlEvent<OutlineMove> {
        let source = Observable<OutlineMove>.deferred { [weak base] in
            let adapter = (base?.dataSource as? RxNSOutlineViewDataSourceProxy)?._requiredMethodsDelegate.object
            return (adapter as? RxNSOutlineViewReorderableDataSourceType)?.outlineItemMoved.asObservable()
                ?? Observable.empty()
        }
        return ControlEvent(events: source)
    }

    /// Emits the new complete root-level nodes array after drag-and-drop reordering.
    /// Use this to sync your upstream data source (e.g. `BehaviorRelay`).
    public func modelMoved<T>() -> ControlEvent<[T]> {
        let source = Observable<[T]>.deferred { [weak base] in
            let adapter = (base?.dataSource as? RxNSOutlineViewDataSourceProxy)?._requiredMethodsDelegate.object
            return (adapter as? RxNSOutlineViewReorderableDataSourceType)?.modelMoved.compactMap { $0 as? [T] }.asObservable()
                ?? Observable.empty()
        }
        return ControlEvent(events: source)
    }

    public func modelDoubleClicked<Item>() -> ControlEvent<Item> {
        return _modelForControlEvent(itemDoubleClicked())
    }

    public func modelClicked<Item>() -> ControlEvent<Item> {
        return _modelForControlEvent(itemClicked())
    }

    public func modelSelected<Item>() -> ControlEvent<Item> {
        return _modelForControlEvent(itemSelected())
    }

    private func _modelForControlEvent<Item>(_ controlEvent: ControlEvent<TableIndex>) -> ControlEvent<Item> {
        let source = controlEvent.compactMap { [weak base] clickedIndex -> Item? in
            guard let base, let item = base.item(atRow: clickedIndex.row) as? Item else { return nil }
            return item
        }
        return ControlEvent(events: source)
    }
}
