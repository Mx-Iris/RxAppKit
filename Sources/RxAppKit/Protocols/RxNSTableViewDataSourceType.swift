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

