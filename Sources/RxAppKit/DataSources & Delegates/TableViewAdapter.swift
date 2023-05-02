import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

open class TableViewAdapter<T>: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    public typealias CellProvider = (_ tableView: NSTableView, _ tableColumn: NSTableColumn?, _ row: Int, _ item: T) -> NSView?

    public typealias RowProvider = (_ tableView: NSTableView, _ row: Int, _ items: [T]) -> NSTableRowView

    weak var delegateAdapter: RxNSTableViewDelegateAdapter?

    open var cellProvider: CellProvider

    open var rowProvider: RowProvider

    public init(
        cellProvider: @escaping CellProvider,
        rowProvider: @escaping RowProvider = { _, _, _ in NSTableRowView() }
    ) {
        self.cellProvider = cellProvider
        self.rowProvider = rowProvider
        super.init()
    }
    
    open func numberOfRows(in tableView: NSTableView) -> Int {
        return 0
    }
    
    open func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return nil
    }
    
    open func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return nil
    }

    open func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        delegateAdapter?.tableView?(tableView, shouldEdit: tableColumn, row: row) ?? false
    }

    open func tableView(_ tableView: NSTableView, toolTipFor cell: NSCell, rect: NSRectPointer, tableColumn: NSTableColumn?, row: Int, mouseLocation: NSPoint) -> String {
        delegateAdapter?.tableView?(tableView, toolTipFor: cell, rect: rect, tableColumn: tableColumn, row: row, mouseLocation: mouseLocation) ?? ""
    }

    open func tableView(_ tableView: NSTableView, shouldShowCellExpansionFor tableColumn: NSTableColumn?, row: Int) -> Bool {
        delegateAdapter?.tableView?(tableView, shouldShowCellExpansionFor: tableColumn, row: row) ?? false
    }

    open func tableView(_ tableView: NSTableView, shouldTrackCell cell: NSCell, for tableColumn: NSTableColumn?, row: Int) -> Bool {
        delegateAdapter?.tableView?(tableView, shouldTrackCell: cell, for: tableColumn, row: row) ?? true
    }

    open func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        delegateAdapter?.tableView?(tableView, dataCellFor: tableColumn, row: row)
    }

    open func selectionShouldChange(in tableView: NSTableView) -> Bool {
        delegateAdapter?.selectionShouldChange?(in: tableView) ?? true
    }

    open func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        delegateAdapter?.tableView?(tableView, shouldSelectRow: row) ?? true
    }

    open func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        delegateAdapter?.tableView?(tableView, selectionIndexesForProposedSelection: proposedSelectionIndexes) ?? proposedSelectionIndexes
    }

    open func tableView(_ tableView: NSTableView, shouldSelect tableColumn: NSTableColumn?) -> Bool {
        delegateAdapter?.tableView?(tableView, shouldSelect: tableColumn) ?? false
    }

    open func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        delegateAdapter?.tableView?(tableView, heightOfRow: row) ?? -1
    }

    open func tableView(_ tableView: NSTableView, typeSelectStringFor tableColumn: NSTableColumn?, row: Int) -> String? {
        delegateAdapter?.tableView?(tableView, typeSelectStringFor: tableColumn, row: row)
    }

    open func tableView(_ tableView: NSTableView, nextTypeSelectMatchFromRow startRow: Int, toRow endRow: Int, for searchString: String) -> Int {
        delegateAdapter?.tableView?(tableView, nextTypeSelectMatchFromRow: startRow, toRow: endRow, for: searchString) ?? 0
    }

    open func tableView(_ tableView: NSTableView, shouldTypeSelectFor event: NSEvent, withCurrentSearch searchString: String?) -> Bool {
        delegateAdapter?.tableView?(tableView, shouldTypeSelectFor: event, withCurrentSearch: searchString) ?? true
    }

    open func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        delegateAdapter?.tableView?(tableView, isGroupRow: row) ?? false
    }

    open func tableView(_ tableView: NSTableView, sizeToFitWidthOfColumn column: Int) -> CGFloat {
        delegateAdapter?.tableView?(tableView, sizeToFitWidthOfColumn: column) ?? -1
    }

    open func tableView(_ tableView: NSTableView, shouldReorderColumn columnIndex: Int, toColumn newColumnIndex: Int) -> Bool {
        delegateAdapter?.tableView?(tableView, shouldReorderColumn: columnIndex, toColumn: newColumnIndex) ?? true
    }

    open func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        delegateAdapter?.tableView?(tableView, rowActionsForRow: row, edge: edge) ?? []
    }
}
