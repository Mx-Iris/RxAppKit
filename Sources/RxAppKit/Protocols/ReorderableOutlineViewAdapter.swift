import AppKit

/// An adapter that supports drag-and-drop reordering for outline views.
public protocol ReorderableOutlineViewAdapter: AnyObject {
    /// Register the outline view for internal drag-and-drop reordering.
    func setupReordering(for outlineView: NSOutlineView)
}
