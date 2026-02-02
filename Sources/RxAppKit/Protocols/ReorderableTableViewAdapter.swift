import AppKit

/// An adapter that supports drag-and-drop reordering for table views.
public protocol ReorderableTableViewAdapter: AnyObject {
    /// Register the table view for internal drag-and-drop reordering.
    func setupReordering(for tableView: NSTableView)
}
