import AppKit

@objc
public protocol RxNSTableViewDelegateAdapter: AnyObject {
    @MainActor @objc optional func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool

    @MainActor @objc optional func tableView(_ tableView: NSTableView, toolTipFor cell: NSCell, rect: NSRectPointer, tableColumn: NSTableColumn?, row: Int, mouseLocation: NSPoint) -> String

    @MainActor @objc optional func tableView(_ tableView: NSTableView, shouldShowCellExpansionFor tableColumn: NSTableColumn?, row: Int) -> Bool

    @MainActor @objc optional func tableView(_ tableView: NSTableView, shouldTrackCell cell: NSCell, for tableColumn: NSTableColumn?, row: Int) -> Bool

    @MainActor @objc optional func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell?

    @MainActor @objc optional func selectionShouldChange(in tableView: NSTableView) -> Bool

    @MainActor @objc optional func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool

    @MainActor @objc optional func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet

    @MainActor @objc optional func tableView(_ tableView: NSTableView, shouldSelect tableColumn: NSTableColumn?) -> Bool

    @MainActor @objc optional func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat

    @MainActor @objc optional func tableView(_ tableView: NSTableView, typeSelectStringFor tableColumn: NSTableColumn?, row: Int) -> String?

    @MainActor @objc optional func tableView(_ tableView: NSTableView, nextTypeSelectMatchFromRow startRow: Int, toRow endRow: Int, for searchString: String) -> Int

    @MainActor @objc optional func tableView(_ tableView: NSTableView, shouldTypeSelectFor event: NSEvent, withCurrentSearch searchString: String?) -> Bool

    @MainActor @objc optional func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool

    @MainActor @objc optional func tableView(_ tableView: NSTableView, sizeToFitWidthOfColumn column: Int) -> CGFloat

    @MainActor @objc optional func tableView(_ tableView: NSTableView, shouldReorderColumn columnIndex: Int, toColumn newColumnIndex: Int) -> Bool

    @MainActor @objc optional func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction]
}
