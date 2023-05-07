import AppKit
import RxSwift

/// Marks data source as `NSComboBox` reactive data source enabling it to be used with one of the `bindTo` methods.
public protocol RxNSComboBoxDataSourceType /*: NSTableViewDataSource */ {
    /// Type of elements that can be bound to combo box.
    associatedtype Element

    /// New observable sequence event observed.
    ///
    /// - parameter comboBox: Bound combo box.
    /// - parameter observedEvent: Event
    func comboBox(_ comboBox: NSComboBox, observedEvent: Event<Element>)
}
