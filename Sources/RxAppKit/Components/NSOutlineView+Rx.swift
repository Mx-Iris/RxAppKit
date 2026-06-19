import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

extension Reactive where Base: NSOutlineView {
    public typealias OutlineCellViewProvider<OutlineNode: OutlineNodeType & Differentiable & Hashable> = (_ outlineView: NSOutlineView, _ tableColumn: NSTableColumn?, _ node: OutlineNode) -> NSView?

    public typealias OutlineRowViewProvider<OutlineNode: OutlineNodeType & Differentiable & Hashable> = (_ outlineView: NSOutlineView, _ node: OutlineNode) -> NSTableRowView?

    /// A section for a sectioned `NSOutlineView` binding: a `SectionHeader` model
    /// plus its child `ChildNode`s. Each child node may itself be a tree, so the
    /// outline keeps its hierarchy under every section. Backed by DifferenceKit's
    /// `ArraySection`, symmetric with the sectioned `NSTableView` binding.
    public typealias OutlineViewSection<SectionHeader: Differentiable & Hashable, ChildNode: OutlineNodeType & Differentiable & Hashable> = ArraySection<SectionHeader, ChildNode>

    public typealias OutlineSectionHeaderViewProvider<SectionHeader: Differentiable & Hashable> = (_ outlineView: NSOutlineView, _ tableColumn: NSTableColumn?, _ header: SectionHeader) -> NSView?

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

    // MARK: - rootNode

    public func rootNode<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellViewProvider<OutlineNode>) -> Disposable
        where Source.Element == OutlineNode {
        return { viewForItem in
            self.rootNode(source: source, options: [])(viewForItem, nil)
        }
    }

    public func rootNode<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellViewProvider<OutlineNode>, OutlineRowViewProvider<OutlineNode>?) -> Disposable
        where Source.Element == OutlineNode {
        return { cellViewProvider, rowViewProvider in
            self.rootNode(source: source, options: [])(cellViewProvider, rowViewProvider)
        }
    }

    public func rootNode<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(
        source: Source,
        options: RxNSOutlineViewAdapterOptions,
    ) -> (@escaping OutlineCellViewProvider<OutlineNode>) -> Disposable
        where Source.Element == OutlineNode {
        return { viewForItem in
            self.rootNode(source: source, options: options)(viewForItem, nil)
        }
    }

    public func rootNode<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(
        source: Source,
        options: RxNSOutlineViewAdapterOptions,
    ) -> (@escaping OutlineCellViewProvider<OutlineNode>, OutlineRowViewProvider<OutlineNode>?) -> Disposable
        where Source.Element == OutlineNode {
        return { cellViewProvider, rowViewProvider in
            let adapter = RxNSOutlineViewRootNodeAdapter<OutlineNode>(
                options: options,
                cellViewProvider: cellViewProvider,
                rowViewProvider: rowViewProvider,
            )
            return self.nodes(adapter: adapter)(source)
        }
    }

    /// Curried form for `.drive(outlineView.rx.rootNode(options:)) { ... }` /
    /// `.bind(to: outlineView.rx.rootNode(options:)) { ... }` usage.
    public func rootNode<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(
        options: RxNSOutlineViewAdapterOptions,
    ) -> (_ source: Source) -> (@escaping OutlineCellViewProvider<OutlineNode>) -> Disposable
        where Source.Element == OutlineNode {
        return { source in
            self.rootNode(source: source, options: options)
        }
    }

    /// Curried form for `.drive(outlineView.rx.rootNode(options:)) { ... }` with
    /// a row-view provider.
    public func rootNode<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(
        options: RxNSOutlineViewAdapterOptions,
    ) -> (_ source: Source) -> (@escaping OutlineCellViewProvider<OutlineNode>, OutlineRowViewProvider<OutlineNode>?) -> Disposable
        where Source.Element == OutlineNode {
        return { source in
            self.rootNode(source: source, options: options)
        }
    }

    // MARK: - nodes

    public func nodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellViewProvider<OutlineNode>) -> Disposable
        where Source.Element == [OutlineNode] {
        return { viewForItem in
            self.nodes(source: source, options: [])(viewForItem, nil)
        }
    }

    public func nodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellViewProvider<OutlineNode>, OutlineRowViewProvider<OutlineNode>?) -> Disposable
        where Source.Element == [OutlineNode] {
        return { cellViewProvider, rowViewProvider in
            self.nodes(source: source, options: [])(cellViewProvider, rowViewProvider)
        }
    }

    public func nodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(
        source: Source,
        options: RxNSOutlineViewAdapterOptions,
    ) -> (@escaping OutlineCellViewProvider<OutlineNode>) -> Disposable
        where Source.Element == [OutlineNode] {
        return { viewForItem in
            self.nodes(source: source, options: options)(viewForItem, nil)
        }
    }

    public func nodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(
        source: Source,
        options: RxNSOutlineViewAdapterOptions,
    ) -> (@escaping OutlineCellViewProvider<OutlineNode>, OutlineRowViewProvider<OutlineNode>?) -> Disposable
        where Source.Element == [OutlineNode] {
        return { cellViewProvider, rowViewProvider in
            let adapter = RxNSOutlineViewAdapter<OutlineNode>(
                options: options,
                cellViewProvider: cellViewProvider,
                rowViewProvider: rowViewProvider,
            )
            return self.nodes(adapter: adapter)(source)
        }
    }

    /// Curried form for `.drive(outlineView.rx.nodes(options:)) { ... }` /
    /// `.bind(to: outlineView.rx.nodes(options:)) { ... }` usage.
    public func nodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(
        options: RxNSOutlineViewAdapterOptions,
    ) -> (_ source: Source) -> (@escaping OutlineCellViewProvider<OutlineNode>) -> Disposable
        where Source.Element == [OutlineNode] {
        return { source in
            self.nodes(source: source, options: options)
        }
    }

    /// Curried form for `.drive(outlineView.rx.nodes(options:)) { ... }` with
    /// a row-view provider.
    public func nodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(
        options: RxNSOutlineViewAdapterOptions,
    ) -> (_ source: Source) -> (@escaping OutlineCellViewProvider<OutlineNode>, OutlineRowViewProvider<OutlineNode>?) -> Disposable
        where Source.Element == [OutlineNode] {
        return { source in
            self.nodes(source: source, options: options)
        }
    }

    public func nodes<Source: ObservableType, Adapter: RxNSOutlineViewDataSourceType & NSOutlineViewDataSource & NSOutlineViewDelegate>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Source.Element == Adapter.Element {
        return { source in
            let dataSourceSubscription = source.subscribeProxyDataSource(ofObject: base, dataSource: adapter, retainDataSource: true) { [weak outlineView = base] (_: RxNSOutlineViewDataSourceProxy, event) in
                guard let outlineView else { return }
                adapter.outlineView(outlineView, observedEvent: event)
            }
            let delegateSubscription = RxNSOutlineViewDelegateProxy.proxy(for: base).setRequiredMethodDelegate(adapter)
            return Disposables.create([dataSourceSubscription, delegateSubscription])
        }
    }

    // MARK: - sections

    public func sections<SectionHeader: Differentiable & Hashable, ChildNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (_ sectionHeaderViewProvider: @escaping OutlineSectionHeaderViewProvider<SectionHeader>,
            _ cellViewProvider: @escaping OutlineCellViewProvider<ChildNode>) -> Disposable
        where Source.Element == [OutlineViewSection<SectionHeader, ChildNode>] {
        return { sectionHeaderViewProvider, cellViewProvider in
            self.sections(source: source, options: [])(sectionHeaderViewProvider, cellViewProvider, nil)
        }
    }

    public func sections<SectionHeader: Differentiable & Hashable, ChildNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (_ sectionHeaderViewProvider: @escaping OutlineSectionHeaderViewProvider<SectionHeader>,
            _ cellViewProvider: @escaping OutlineCellViewProvider<ChildNode>,
            _ rowViewProvider: OutlineRowViewProvider<ChildNode>?) -> Disposable
        where Source.Element == [OutlineViewSection<SectionHeader, ChildNode>] {
        return { sectionHeaderViewProvider, cellViewProvider, rowViewProvider in
            self.sections(source: source, options: [])(sectionHeaderViewProvider, cellViewProvider, rowViewProvider)
        }
    }

    public func sections<SectionHeader: Differentiable & Hashable, ChildNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(
        source: Source,
        options: RxNSOutlineViewAdapterOptions,
    ) -> (_ sectionHeaderViewProvider: @escaping OutlineSectionHeaderViewProvider<SectionHeader>,
          _ cellViewProvider: @escaping OutlineCellViewProvider<ChildNode>) -> Disposable
        where Source.Element == [OutlineViewSection<SectionHeader, ChildNode>] {
        return { sectionHeaderViewProvider, cellViewProvider in
            self.sections(source: source, options: options)(sectionHeaderViewProvider, cellViewProvider, nil)
        }
    }

    public func sections<SectionHeader: Differentiable & Hashable, ChildNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(
        source: Source,
        options: RxNSOutlineViewAdapterOptions,
    ) -> (_ sectionHeaderViewProvider: @escaping OutlineSectionHeaderViewProvider<SectionHeader>,
          _ cellViewProvider: @escaping OutlineCellViewProvider<ChildNode>,
          _ rowViewProvider: OutlineRowViewProvider<ChildNode>?) -> Disposable
        where Source.Element == [OutlineViewSection<SectionHeader, ChildNode>] {
        return { sectionHeaderViewProvider, cellViewProvider, rowViewProvider in
            let adapter = RxNSOutlineViewSectionedAdapter<SectionHeader, ChildNode>(
                options: options,
                sectionHeaderViewProvider: sectionHeaderViewProvider,
                cellViewProvider: cellViewProvider,
                rowViewProvider: rowViewProvider
            )
            return self.nodes(adapter: adapter)(source)
        }
    }

    // MARK: - reorderableNodes (deprecated)

    @available(*, deprecated, message: "Use nodes(source:options: [.reorderable]) instead.")
    public func reorderableNodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellViewProvider<OutlineNode>)
        -> Disposable
        where Source.Element == [OutlineNode] {
        return { viewForItem in
            self.nodes(source: source, options: [.reorderable])(viewForItem, nil)
        }
    }

    @available(*, deprecated, message: "Use nodes(source:options: [.reorderable]) instead.")
    public func reorderableNodes<OutlineNode: OutlineNodeType & Differentiable & Hashable, Source: ObservableType>(source: Source)
        -> (@escaping OutlineCellViewProvider<OutlineNode>, OutlineRowViewProvider<OutlineNode>?)
        -> Disposable
        where Source.Element == [OutlineNode] {
        return { cellViewProvider, rowViewProvider in
            self.nodes(source: source, options: [.reorderable])(cellViewProvider, rowViewProvider)
        }
    }

    @available(*, deprecated, message: "Use nodes(adapter:) with a reorderable adapter instead. The adapter is responsible for calling setupReordering(for:).")
    public func reorderableNodes<Source: ObservableType, Adapter: RxNSOutlineViewReorderableDataSourceType & RxNSOutlineViewDataSourceType & NSOutlineViewDataSource & NSOutlineViewDelegate>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Source.Element == Adapter.Element {
        return { source in
            adapter.setupReordering(for: self.base)
            return self.nodes(adapter: adapter)(source)
        }
    }

    // MARK: - Reorder events

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

    // MARK: - Model events

    public func itemSelected() -> ControlEvent<TableIndex> {
        return base.rx.controlEventForNotification(NSOutlineView.selectionDidChangeNotification, object: base) { notification in
            guard let base = notification.object as? NSOutlineView else { return nil }
            return (base.selectedRow, base.selectedColumn)
        }
    }
    
    public func modelClicked<Item>() -> ControlEvent<Item> {
        return _modelForControlEvent(itemClicked())
    }

    public func modelDoubleClicked<Item>() -> ControlEvent<Item> {
        return _modelForControlEvent(itemDoubleClicked())
    }

    public func modelSelected<Item>() -> ControlEvent<Item> {
        return itemSelected().compactMap { [weak base] tableIndex in
            guard let base else { return nil }
            return base.item(atRow: tableIndex.row) as? Item
        }.asControlEvent()
    }

    /// Emits selection changes whose triggering `NSEvent` passes `shouldEmit`.
    /// The window's `currentEvent` is forwarded as-is; `nil` means the selection
    /// was changed programmatically (no input event in flight).
    public func modelSelectedFilteringCurrentEvent<Item>(
        _ shouldEmit: @escaping (NSEvent?) -> Bool
    ) -> ControlEvent<Item> {
        modelSelected().filter { [weak base] _ in
            shouldEmit(base?.window?.currentEvent)
        }.asControlEvent()
    }

    private func _modelForControlEvent<Item>(_ controlEvent: ControlEvent<TableIndex>) -> ControlEvent<Item> {
        let source = controlEvent.compactMap { [weak base] clickedIndex -> Item? in
            guard let base, let item = base.item(atRow: clickedIndex.row) as? Item else { return nil }
            return item
        }
        return ControlEvent(events: source)
    }
}
