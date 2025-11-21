import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

extension Reactive where Base: NSOutlineView {
    public typealias OutlineCellProvider<OutlineNode: OutlineNodeType & Differentiable & Hashable> = (_ outlineView: NSOutlineView, _ tableColumn: NSTableColumn?, _ node: OutlineNode) -> NSView?
    public typealias OutlineRowProvider<OutlineNode: OutlineNodeType & Differentiable & Hashable> = (_ outlineView: NSOutlineView, _ node: OutlineNode) -> NSTableRowView?

    private var _outlineViewDataSource: RxNSOutlineViewDataSourceProxy {
        .proxy(for: base)
    }

    public var outlineViewDataSource: DelegateProxy<NSOutlineView, NSOutlineViewDataSource> {
        _outlineViewDataSource
    }

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
        where OutlineNode.NodeType == OutlineNode, Source.Element == OutlineNode {
        return { viewForItem in
            self.rootNode(source: source)(viewForItem, nil)
        }
    }

    public func rootNode<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellProvider<OutlineNode>, OutlineRowProvider<OutlineNode>?)
        -> Disposable
        where OutlineNode.NodeType == OutlineNode, Source.Element == OutlineNode {
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
        where OutlineNode.NodeType == OutlineNode, Source.Element == [OutlineNode] {
        return { viewForItem in
            self.nodes(source: source)(viewForItem, nil)
        }
    }

    public func nodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellProvider<OutlineNode>, OutlineRowProvider<OutlineNode>?)
        -> Disposable
        where OutlineNode.NodeType == OutlineNode, Source.Element == [OutlineNode] {
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
