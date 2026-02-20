import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

extension Reactive where Base: NSOutlineView {
    public typealias OutlineCellViewProvider<OutlineNode: OutlineNodeType & Differentiable & Hashable> = (_ outlineView: NSOutlineView, _ tableColumn: NSTableColumn?, _ node: OutlineNode) -> NSView?

    public typealias OutlineRowViewProvider<OutlineNode: OutlineNodeType & Differentiable & Hashable> = (_ outlineView: NSOutlineView, _ node: OutlineNode) -> NSTableRowView?
    
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
        -> (@escaping OutlineCellViewProvider<OutlineNode>)
        -> Disposable
        where Source.Element == OutlineNode {
        return { viewForItem in
            self.rootNode(source: source)(viewForItem, nil)
        }
    }

    public func rootNode<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellViewProvider<OutlineNode>, OutlineRowViewProvider<OutlineNode>?)
        -> Disposable
        where Source.Element == OutlineNode {
        return { cellViewProvider, rowViewProvider in
            let adapter = RxNSOutlineViewRootNodeAdapter<OutlineNode>(cellViewProvider: cellViewProvider, rowViewProvider: rowViewProvider)
            return self.nodes(adapter: adapter)(source)
        }
    }

    public func nodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellViewProvider<OutlineNode>)
        -> Disposable
        where Source.Element == [OutlineNode] {
        return { viewForItem in
            self.nodes(source: source)(viewForItem, nil)
        }
    }

    public func nodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellViewProvider<OutlineNode>, OutlineRowViewProvider<OutlineNode>?)
        -> Disposable
        where Source.Element == [OutlineNode] {
        return { cellViewProvider, rowViewProvider in
            let adapter = RxNSOutlineViewAdapter<OutlineNode>(cellViewProvider: cellViewProvider, rowViewProvider: rowViewProvider)
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
        -> (@escaping OutlineCellViewProvider<OutlineNode>)
        -> Disposable
        where Source.Element == [OutlineNode] {
        return { viewForItem in
            self.reorderableNodes(source: source)(viewForItem, nil)
        }
    }

    /// Binds an observable source to a reorderable adapter, automatically registering the outline view for drag-and-drop reordering.
    public func reorderableNodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellViewProvider<OutlineNode>, OutlineRowViewProvider<OutlineNode>?)
        -> Disposable
        where Source.Element == [OutlineNode] {
        return { cellViewProvider, rowViewProvider in
            let adapter = RxNSReorderableOutlineViewAdapter<OutlineNode>(cellViewProvider: cellViewProvider, rowViewProvider: rowViewProvider)
            return self.reorderableNodes(adapter: adapter)(source)
        }
    }

    /// Binds an observable source to a reorderable adapter, automatically registering the outline view for drag-and-drop reordering.
    public func reorderableNodes<Source: ObservableType, Adapter: RxNSOutlineViewReorderableDataSourceType & RxNSOutlineViewDataSourceType & NSOutlineViewDataSource & NSOutlineViewDelegate>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Source.Element == Adapter.Element {
        return { source in
            adapter.setupReordering(for: self.base)
            let dataSourceSubscription = source.subscribeProxyDataSource(ofObject: base, dataSource: adapter, retainDataSource: true) { [weak outlineView = base] (_: RxNSOutlineViewDataSourceProxy, event) in
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

    /// Controls whether drag-and-drop reordering is allowed on the reorderable adapter.
    public var isReorderingEnabled: Binder<Bool> {
        Binder(base) { view, enabled in
            let adapter = (view.dataSource as? RxNSOutlineViewDataSourceProxy)?._requiredMethodsDelegate.object
            (adapter as? RxNSOutlineViewReorderableDataSourceType)?.isReorderingEnabled = enabled
        }
    }

    /// When bound to `true`, only root-level nodes can be dragged and they can
    /// only be reordered within the root level — children cannot be promoted and
    /// roots cannot be demoted.
    public var isRootLevelReorderingOnly: Binder<Bool> {
        Binder(base) { view, value in
            let adapter = (view.dataSource as? RxNSOutlineViewDataSourceProxy)?._requiredMethodsDelegate.object
            (adapter as? RxNSOutlineViewReorderableDataSourceType)?.isRootLevelReorderingOnly = value
        }
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
