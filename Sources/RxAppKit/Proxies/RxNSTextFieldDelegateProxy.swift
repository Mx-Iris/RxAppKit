import AppKit
import RxSwift
import RxCocoa

extension NSTextField: HasDelegate {
    public typealias Delegate = NSTextFieldDelegate
}

class RxNSTextFieldDelegateProxy: DelegateProxy<NSTextField, NSTextFieldDelegate>, DelegateProxyType, NSTextFieldDelegate {
    /// Typed parent object.
    public private(set) weak var textField: NSTextField?

    /// Initializes `RxTextFieldDelegateProxy`
    ///
    /// - parameter textField: Parent object for delegate proxy.
    init(textField: NSTextField) {
        self.textField = textField
        super.init(parentObject: textField, delegateProxy: RxTextFieldDelegateProxy.self)
    }

    public static func registerKnownImplementations() {
        register { RxNSTextFieldDelegateProxy(textField: $0) }
        register { RxNSSearchFieldDelegateProxy(searchField: $0) }
    }

    fileprivate let textSubject = PublishSubject<String?>()

    // MARK: Delegate methods

    open func controlTextDidChange(_ notification: Notification) {
        let textField: NSTextField = castOrFatalError(notification.object)
        let nextValue = textField.stringValue
        textSubject.on(.next(nextValue))
        _forwardToDelegate?.controlTextDidChange?(notification)
    }
}
