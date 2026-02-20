import AppKit
import RxSwift

/// Marks data source as `NSOutlineView` reactive data source enabling it to be used with one of the `bindTo` methods.
public protocol RxNSOutlineViewDataSourceType /*: NSOutlineViewDataSource */ {
    /// Type of elements that can be bound to outline view.
    associatedtype Element

    /// New observable sequence event observed.
    ///
    /// - parameter outlineView: Bound outline view.
    /// - parameter observedEvent: Event
    func outlineView(_ outlineView: NSOutlineView, observedEvent: Event<Element>)
}

/// Marks data source as `NSOutlineView` reorderable reactive data source.
public protocol RxNSOutlineViewReorderableDataSourceType: AnyObject /*: NSOutlineViewDataSource */ {
    /// Register the outline view for internal drag-and-drop reordering.
    func setupReordering(for outlineView: NSOutlineView)

    /// Controls whether drag-and-drop reordering is currently allowed.
    var isReorderingEnabled: Bool { get set }

    /// When `true`, only root-level nodes can be dragged and they can only be
    /// reordered within the root level (no promoting children or demoting roots).
    var isRootLevelReorderingOnly: Bool { get set }

    /// Emits detailed move info when items have been reordered via drag-and-drop.
    var outlineItemMoved: PublishSubject<OutlineMove> { get }

    /// Emits the new complete root-level nodes array (type-erased) after root-level reordering.
    var modelMoved: PublishSubject<[Any]> { get }
}
