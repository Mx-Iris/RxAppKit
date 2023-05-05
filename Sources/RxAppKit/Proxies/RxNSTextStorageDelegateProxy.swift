import AppKit
import RxSwift
import RxCocoa

extension NSTextStorage: HasDelegate {
    public typealias Delegate = NSTextStorageDelegate
}

open class RxNSTextStorageDelegateProxy
    : DelegateProxy<NSTextStorage, NSTextStorageDelegate>
    , DelegateProxyType {

    /// Typed parent object.
    public weak private(set) var textStorage: NSTextStorage?

    /// - parameter textStorage: Parent object for delegate proxy.
    public init(textStorage: NSTextStorage) {
        self.textStorage = textStorage
        super.init(parentObject: textStorage, delegateProxy: RxNSTextStorageDelegateProxy.self)
    }

    // Register known implementations
    public static func registerKnownImplementations() {
        self.register { RxNSTextStorageDelegateProxy(textStorage: $0) }
    }
}

extension RxNSTextStorageDelegateProxy: NSTextStorageDelegate {}
