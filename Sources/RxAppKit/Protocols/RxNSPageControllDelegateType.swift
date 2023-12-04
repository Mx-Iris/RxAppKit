import AppKit
import RxSwift

/// Marks data source as `NSPageController` reactive data source enabling it to be used with one of the `bindTo` methods.
public protocol RxNSPageControllerDelegateType {
    /// Type of elements that can be bound to table view.
    associatedtype Element

    /// New observable sequence event observed.
    ///
    /// - parameter pageController: Bound page Controller.
    /// - parameter observedEvent: Event
    func pageController(_ pageController: NSPageController, observedEvent: Event<Element>)
}
