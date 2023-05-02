import AppKit
import RxSwift

/// Marks data source as `NSBrowser` reactive data source enabling it to be used with one of the `bindTo` methods.
public protocol RxNSBrowserDelegateType /*: NSBrowserDelegate*/ {
    
    /// Type of elements that can be bound to table view.
    associatedtype Element
    
    /// New observable sequence event observed.
    ///
    /// - parameter tableView: Bound table view.
    /// - parameter observedEvent: Event
    func browser(_ browser: NSBrowser, observedEvent: Event<Element>)
}
