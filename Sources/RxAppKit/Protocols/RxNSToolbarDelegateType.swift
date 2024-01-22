#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift

/// Marks data source as `NSToolbar` reactive data source enabling it to be used with one of the `bindTo` methods.
public protocol RxNSToolbarDelegateType /*: NSToolbarDelegate */ {
    /// Type of elements that can be bound to table view.
    associatedtype Element

    /// New observable sequence event observed.
    ///
    /// - parameter toolbar: Bound toolbar.
    /// - parameter observedEvent: Event
    func toolbar(_ toolbar: NSToolbar, observedEvent: Event<Element>)
}


#endif
