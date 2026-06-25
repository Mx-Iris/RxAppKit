import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

extension NSTableView: HasDoubleAction {}

extension NSTableView {
    /// Payload of ``Reactive/proposedSelection()`` — the indexes AppKit is about
    /// to apply plus the input event that triggered the change (mouse, key, or
    /// `nil` for changes the system itself originates).
    public struct ProposedSelection {
        public let indexes: IndexSet
        public let triggeringEvent: NSEvent?

        public init(indexes: IndexSet, triggeringEvent: NSEvent?) {
            self.indexes = indexes
            self.triggeringEvent = triggeringEvent
        }
    }
}

extension Reactive where Base: NSTableView {
    public typealias TableIndexSet = (rowIndexes: IndexSet, columnIndexes: IndexSet)
    
    public typealias TableIndex = (row: Int, column: Int)
    
    public typealias TableCellViewProvider<Item: Differentiable> = (_ tableView: NSTableView, _ tableColumn: NSTableColumn?, _ row: Int, _ item: Item) -> NSView?
    
    public typealias TableRowViewProvider<Item: Differentiable> = (_ tableView: NSTableView, _ row: Int, _ items: [Item]) -> NSTableRowView

    /// A section for a sectioned `NSTableView` binding: a `SectionHeader` model
    /// plus its `Item` elements. Backed by DifferenceKit's `ArraySection`, the
    /// same container the sectioned `NSCollectionView` bindings use.
    public typealias TableViewSection<SectionHeader: Differentiable, Item: Differentiable> = ArraySection<SectionHeader, Item>

    public typealias TableSectionHeaderViewProvider<SectionHeader: Differentiable> = (_ tableView: NSTableView, _ sectionIndex: Int, _ header: SectionHeader) -> NSView?

    public typealias TableSectionCellViewProvider<Item: Differentiable> = (_ tableView: NSTableView, _ tableColumn: NSTableColumn?, _ indexPath: IndexPath, _ item: Item) -> NSView?

    public typealias TableSectionRowViewProvider<SectionHeader: Differentiable, Item: Differentiable> = (_ tableView: NSTableView, _ row: Int, _ rowKind: SectionedTableViewAdapter<SectionHeader, Item>.RowKind) -> NSTableRowView?

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
        -> (_ cellProvider: @escaping TableCellViewProvider<Element>) -> Disposable
    where Source.Element == [Element] {
        return { cellProvider in
            self.items(source, options: [])(cellProvider, nil)
        }
    }

    public func items<Element: Differentiable, Source: ObservableType>(_ source: Source)
        -> (_ cellViewProvider: @escaping TableCellViewProvider<Element>, _ rowViewProvider: TableRowViewProvider<Element>?) -> Disposable
    where Source.Element == [Element] {
        return { cellViewProvider, rowViewProvider in
            self.items(source, options: [])(cellViewProvider, rowViewProvider)
        }
    }

    public func items<Element: Differentiable, Source: ObservableType>(
        _ source: Source,
        options: RxNSTableViewAdapterOptions
    ) -> (_ cellProvider: @escaping TableCellViewProvider<Element>) -> Disposable
    where Source.Element == [Element] {
        return { cellProvider in
            self.items(source, options: options)(cellProvider, nil)
        }
    }

    public func items<Element: Differentiable, Source: ObservableType>(
        _ source: Source,
        options: RxNSTableViewAdapterOptions
    ) -> (_ cellViewProvider: @escaping TableCellViewProvider<Element>, _ rowViewProvider: TableRowViewProvider<Element>?) -> Disposable
    where Source.Element == [Element] {
        return { cellViewProvider, rowViewProvider in
            let adapter = RxNSTableViewAdapter<Element>(
                options: options,
                cellViewProvider: cellViewProvider,
                rowViewProvider: rowViewProvider
            )
            return self.items(adapter: adapter)(source)
        }
    }

    /// Curried form for `.drive(tableView.rx.items(options:)) { ... }` /
    /// `.bind(to: tableView.rx.items(options:)) { ... }` usage. Lets the
    /// caller pass options through a partial-reference binder.
    public func items<Element: Differentiable, Source: ObservableType>(
        options: RxNSTableViewAdapterOptions
    ) -> (_ source: Source) -> (_ cellProvider: @escaping TableCellViewProvider<Element>) -> Disposable
    where Source.Element == [Element] {
        return { source in
            self.items(source, options: options)
        }
    }

    /// Curried form for `.drive(tableView.rx.items(options:)) { ... }` with
    /// a row-view provider.
    public func items<Element: Differentiable, Source: ObservableType>(
        options: RxNSTableViewAdapterOptions
    ) -> (_ source: Source) -> (_ cellViewProvider: @escaping TableCellViewProvider<Element>, _ rowViewProvider: TableRowViewProvider<Element>?) -> Disposable
    where Source.Element == [Element] {
        return { source in
            self.items(source, options: options)
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

    // MARK: - sections

    public func sections<SectionHeader: Differentiable, Item: Differentiable, Source: ObservableType>(_ source: Source)
        -> (_ headerViewProvider: @escaping TableSectionHeaderViewProvider<SectionHeader>,
            _ cellViewProvider: @escaping TableSectionCellViewProvider<Item>) -> Disposable
    where Source.Element == [TableViewSection<SectionHeader, Item>] {
        return { headerViewProvider, cellViewProvider in
            self.sections(source, options: [])(headerViewProvider, cellViewProvider, nil)
        }
    }

    public func sections<SectionHeader: Differentiable, Item: Differentiable, Source: ObservableType>(_ source: Source)
        -> (_ headerViewProvider: @escaping TableSectionHeaderViewProvider<SectionHeader>,
            _ cellViewProvider: @escaping TableSectionCellViewProvider<Item>,
            _ rowViewProvider: TableSectionRowViewProvider<SectionHeader, Item>?) -> Disposable
    where Source.Element == [TableViewSection<SectionHeader, Item>] {
        return { headerViewProvider, cellViewProvider, rowViewProvider in
            self.sections(source, options: [])(headerViewProvider, cellViewProvider, rowViewProvider)
        }
    }

    public func sections<SectionHeader: Differentiable, Item: Differentiable, Source: ObservableType>(
        _ source: Source,
        options: RxNSTableViewAdapterOptions
    ) -> (_ headerViewProvider: @escaping TableSectionHeaderViewProvider<SectionHeader>,
          _ cellViewProvider: @escaping TableSectionCellViewProvider<Item>) -> Disposable
    where Source.Element == [TableViewSection<SectionHeader, Item>] {
        return { headerViewProvider, cellViewProvider in
            self.sections(source, options: options)(headerViewProvider, cellViewProvider, nil)
        }
    }

    public func sections<SectionHeader: Differentiable, Item: Differentiable, Source: ObservableType>(
        _ source: Source,
        options: RxNSTableViewAdapterOptions
    ) -> (_ headerViewProvider: @escaping TableSectionHeaderViewProvider<SectionHeader>,
          _ cellViewProvider: @escaping TableSectionCellViewProvider<Item>,
          _ rowViewProvider: TableSectionRowViewProvider<SectionHeader, Item>?) -> Disposable
    where Source.Element == [TableViewSection<SectionHeader, Item>] {
        return { headerViewProvider, cellViewProvider, rowViewProvider in
            let adapter = RxNSTableViewSectionedReloadAdapter<SectionHeader, Item>(
                headerViewProvider: headerViewProvider,
                cellViewProvider: cellViewProvider,
                rowViewProvider: rowViewProvider
            )
            return self.items(adapter: adapter)(source)
        }
    }

    @available(*, deprecated, message: "Use items(_:options: [.reorderable]) instead.")
    public func reorderableItems<Element: Differentiable, Source: ObservableType>(_ source: Source)
        -> (_ cellProvider: @escaping TableCellViewProvider<Element>)
        -> Disposable where Source.Element == [Element] {
        return { cellProvider in
            self.items(source, options: [.reorderable])(cellProvider, nil)
        }
    }

    @available(*, deprecated, message: "Use items(_:options: [.reorderable]) instead.")
    public func reorderableItems<Element: Differentiable, Source: ObservableType>(_ source: Source)
        -> (_ cellViewProvider: @escaping TableCellViewProvider<Element>, _ rowViewProvider: TableRowViewProvider<Element>?)
        -> Disposable where Source.Element == [Element] {
        return { cellViewProvider, rowViewProvider in
            self.items(source, options: [.reorderable])(cellViewProvider, rowViewProvider)
        }
    }

    @available(*, deprecated, message: "Use items(adapter:) with a reorderable adapter instead. The adapter is responsible for calling setupReordering(for:).")
    public func reorderableItems<Source: ObservableType, Adapter: RxNSTableViewDataSourceType & RxNSTableViewReorderableDataSourceType & NSTableViewDataSource & NSTableViewDelegate>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Source.Element == Adapter.Element {
        return { source in
            adapter.setupReordering(for: self.base)
            return self.items(adapter: adapter)(source)
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

    /// Controls whether drag-and-drop reordering is allowed on the reorderable adapter.
    public var isReorderingEnabled: Binder<Bool> {
        Binder(base) { view, enabled in
            let adapter = (view.dataSource as? RxNSTableViewDataSourceProxy)?._requiredMethodsDelegate.object
            (adapter as? RxNSTableViewReorderableDataSourceType)?.isReorderingEnabled = enabled
        }
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

    public func itemClicked() -> ControlEvent<TableIndex> {
        _controlEventForBaseAction { ($0.clickedRow, $0.clickedColumn) }
    }

    public func itemDoubleClicked() -> ControlEvent<TableIndex> {
        _controlEventForDoubleAction { ($0.clickedRow, $0.clickedColumn) }
    }

    public func itemSelected() -> ControlEvent<TableIndex> {
        return base.rx.controlEventForNotification(NSTableView.selectionDidChangeNotification, object: base) { notification in
            guard let base = notification.object as? NSTableView else { return nil }
            return (base.selectedRow, base.selectedColumn)
        }
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

    // MARK: - User-initiated selection

    /// Proposed selection indexes for user-driven selection changes only —
    /// mouse, keyboard arrow, and type-select. Programmatic
    /// `selectRowIndexes(_:byExtendingSelection:)`, `reloadData()` side effects,
    /// and other internal selection adjustments do NOT emit here. Backed by
    /// `tableView(_:selectionIndexesForProposedSelection:)`, emitted from a
    /// `PublishSubject` owned by the delegate proxy so the stream does not
    /// depend on a data-source adapter being installed at subscription time.
    ///
    /// `triggeringEvent` is the window's `currentEvent` captured synchronously
    /// when AppKit invoked the delegate method, so callers can distinguish
    /// click vs. arrow key vs. type-select.
    public func proposedSelection() -> ControlEvent<NSTableView.ProposedSelection> {
        let source = RxNSTableViewDelegateProxy.proxy(for: base)._proposedSelection.asObservable()
        return ControlEvent(events: source)
    }

    /// User-initiated single-row selection. Same source as ``proposedSelection()``;
    /// for the multi-row case (`allowsMultipleSelection == true`) use
    /// ``proposedSelection()`` directly.
    public func userItemSelected() -> ControlEvent<TableIndex> {
        let source = proposedSelection().compactMap { [weak base] proposed -> TableIndex? in
            guard let base, let row = proposed.indexes.first else { return nil }
            return (row, base.selectedColumn)
        }
        return ControlEvent(events: source)
    }

    /// User-initiated selection mapped through `rx.model(at:)`. Symmetric with
    /// ``modelSelected()`` but does NOT fire for programmatic selection.
    public func userModelSelected<T>() -> ControlEvent<T> {
        let source = userItemSelected().compactMap { [weak view = base] selectedIndex -> T? in
            guard let view, view.isValidRowIndex(selectedIndex.row) else { return nil }
            return try view.rx.model(at: selectedIndex.row)
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

    func isValidTableIndex(_ tableIndex: Reactive<NSTableView>.TableIndex) -> Bool {
        isValidRowIndex(tableIndex.row) && isValidColumnIndex(tableIndex.column)
    }
}

extension Observable {
    func asControlEvent() -> ControlEvent<Element> {
        .init(events: self)
    }
}
