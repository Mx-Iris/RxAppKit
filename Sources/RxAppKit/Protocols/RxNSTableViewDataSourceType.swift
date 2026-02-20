import AppKit
import RxSwift

/// Marks data source as `NSTableView` reactive data source enabling it to be used with one of the `bindTo` methods.
public protocol RxNSTableViewDataSourceType /*: NSTableViewDataSource */ {
    /// Type of elements that can be bound to table view.
    associatedtype Element

    /// New observable sequence event observed.
    ///
    /// - parameter tableView: Bound table view.
    /// - parameter observedEvent: Event
    func tableView(_ tableView: NSTableView, observedEvent: Event<Element>)
}

/// Marks data source as `NSTableView` reorderable reactive data source.
public protocol RxNSTableViewReorderableDataSourceType: AnyObject /*: NSTableViewDataSource */ {
    /// Register the table view for internal drag-and-drop reordering.
    func setupReordering(for tableView: NSTableView)

    /// Controls whether drag-and-drop reordering is currently allowed.
    var isReorderingEnabled: Bool { get set }

    /// Emits source and destination indexes when items have been reordered via drag-and-drop.
    var itemMoved: PublishSubject<(sourceIndexes: IndexSet, destinationIndex: Int)> { get }

    /// Emits the new complete items array (type-erased) after reordering.
    var modelMoved: PublishSubject<[Any]> { get }
}

