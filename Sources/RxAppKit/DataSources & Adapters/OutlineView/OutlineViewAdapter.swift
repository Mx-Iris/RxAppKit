import AppKit
import RxSwift
import RxCocoa

open class OutlineViewAdapter<OutlineNode: OutlineNodeType>: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, RxNSOutlineViewProposedSelectionEmitting {
    public typealias CellViewProvider = (NSOutlineView, NSTableColumn?, OutlineNode) -> NSView?
    public typealias RowViewProvider = (NSOutlineView, OutlineNode) -> NSTableRowView?

    public internal(set) var rootNode: OutlineNode?
    public internal(set) var nodes: [OutlineNode] = []

    public let cellViewProvider: CellViewProvider
    public let rowViewProvider: RowViewProvider?

    let _proposedSelection = PublishSubject<NSOutlineView.ProposedSelection>()

    public init(cellViewProvider: @escaping CellViewProvider, rowViewProvider: RowViewProvider?) {
        self.cellViewProvider = cellViewProvider
        self.rowViewProvider = rowViewProvider
    }

    deinit {
        _proposedSelection.onCompleted()
    }

    // MARK: - Data

    open func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? OutlineNode else {
            return rootNode != nil ? 1 : nodes.count
        }
        return node.children.count
    }

    open func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let node = item as? OutlineNode else {
            return rootNode ?? nodes[index]
        }
        return node.children[index]
    }

    open func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? OutlineNode else {
            return rootNode?.isExpandable ?? false
        }
        return node.isExpandable
    }

    // MARK: - View

    open func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? OutlineNode else { return nil }
        return cellViewProvider(outlineView, tableColumn, node)
    }

    open func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        guard let rowViewProvider else { return nil }
        guard let node = item as? OutlineNode else { return nil }
        return rowViewProvider(outlineView, node)
    }

    // MARK: - User-initiated selection

    /// AppKit invokes this only for user-driven selection changes (mouse,
    /// keyboard, type-select). Emitting here lets `Reactive.proposedSelection()`
    /// expose a clean stream without the programmatic-selection noise that
    /// `selectionDidChangeNotification` carries.
    open func outlineView(_ outlineView: NSOutlineView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        _proposedSelection.onNext(.init(indexes: proposedSelectionIndexes, triggeringEvent: outlineView.window?.currentEvent))
        return proposedSelectionIndexes
    }
}
