import AppKit
import RxSwift

open class ReorderableTableViewArrayAdapter<T>: TableViewArrayAdapter<T>, RxNSTableViewReorderableDataSourceType {

    // MARK: - Reordering

    /// Handlers that control drag-and-drop reordering behavior.
    public struct ReorderingHandlers {
        /// Return the items that are allowed to be reordered (filter from the proposed items).
        /// Return an empty array to deny the drag. When `nil`, all items are allowed.
        public var canReorder: ((_ items: [T]) -> [T])?
        /// Called before items are moved in the data source.
        public var willReorder: ((_ items: [T], _ newIndex: Int) -> Void)?
        /// Called after items have been moved. Provides the new complete items array.
        /// In Rx usage, update your upstream data source here to stay in sync.
        public var didReorder: ((_ items: [T]) -> Void)?

        public init() {}
    }

    open var reorderingHandlers = ReorderingHandlers()

    public let itemMoved = PublishSubject<(sourceIndexes: IndexSet, destinationIndex: Int)>()
    public let modelMoved = PublishSubject<[Any]>()

    private static var reorderPasteboardType: NSPasteboard.PasteboardType {
        NSPasteboard.PasteboardType("com.RxAppKit.ReorderableTableViewArrayAdapter.reorder")
    }

    private var draggingRowIndexes: IndexSet = []
    private var isReorderingRegistered = false

    /// Register the table view for internal drag-and-drop reordering.
    /// Called automatically by `rx.reorderableItems(adapter:)` when using Rx bindings.
    open func setupReordering(for tableView: NSTableView) {
        guard !isReorderingRegistered else { return }
        isReorderingRegistered = true
        tableView.registerForDraggedTypes([Self.reorderPasteboardType])
        tableView.setDraggingSourceOperationMask(.move, forLocal: true)
    }

    // MARK: - Drag & Drop Data Source

    @objc open func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> (any NSPasteboardWriting)? {
        let item = NSPasteboardItem()
        item.setString(String(row), forType: Self.reorderPasteboardType)
        return item
    }

    @objc open func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard !draggingRowIndexes.isEmpty, dropOperation == .above else { return [] }
        guard info.draggingSource as? NSTableView === tableView else { return [] }
        return .move
    }

    @objc open func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard !draggingRowIndexes.isEmpty else { return false }

        let draggedItems = draggingRowIndexes.map { items[$0] }
        let sortedIndexes = draggingRowIndexes.sorted(by: >)

        // Calculate the target index after removing dragged items
        var targetRow = row
        for index in sortedIndexes {
            if index < targetRow {
                targetRow -= 1
            }
        }

        reorderingHandlers.willReorder?(draggedItems, targetRow)

        // Remove dragged items (from high to low to preserve indices)
        for index in sortedIndexes {
            items.remove(at: index)
        }

        // Insert at target position
        for (offset, item) in draggedItems.enumerated() {
            items.insert(item, at: targetRow + offset)
        }

        // Animate row moves
        tableView.beginUpdates()
        let sortedAscending = draggingRowIndexes.sorted()
        for (moveOffset, oldIndex) in sortedAscending.enumerated() {
            let adjustedTarget = targetRow + moveOffset
            tableView.moveRow(at: oldIndex, to: adjustedTarget)
        }
        tableView.endUpdates()

        reorderingHandlers.didReorder?(items)
        itemMoved.onNext((sourceIndexes: draggingRowIndexes, destinationIndex: targetRow))
        modelMoved.onNext(items.map { $0 as Any })
        draggingRowIndexes = []
        return true
    }

    @objc(tableView:draggingSession:willBeginAtPoint:forRowIndexes:)
    open func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {
        var allowedItems = rowIndexes.map { items[$0] }
        if let canReorder = reorderingHandlers.canReorder {
            allowedItems = canReorder(allowedItems)
        }

        if allowedItems.isEmpty {
            draggingRowIndexes = []
            session.animatesToStartingPositionsOnCancelOrFail = true
        } else {
            // Map allowed items back to row indexes (by position in the original set)
            draggingRowIndexes = rowIndexes
            session.animatesToStartingPositionsOnCancelOrFail = false
        }
    }

    @objc(tableView:draggingSession:endedAtPoint:operation:)
    open func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        draggingRowIndexes = []
    }
}
