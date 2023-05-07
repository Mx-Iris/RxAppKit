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
