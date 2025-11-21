import AppKit
import RxSwift
import RxCocoa

extension NSTextStorage: @retroactive HasDelegate {
    public typealias Delegate = NSTextStorageDelegate
}

class RxNSTextStorageDelegateProxy
    : DelegateProxy<NSTextStorage, NSTextStorageDelegate>
    , DelegateProxyType {
    /// Typed parent object.
    public private(set) weak var textStorage: NSTextStorage?

    /// - parameter textStorage: Parent object for delegate proxy.
    public init(textStorage: NSTextStorage) {
        self.textStorage = textStorage
        super.init(parentObject: textStorage, delegateProxy: RxNSTextStorageDelegateProxy.self)
    }

    // Register known implementations
    public static func registerKnownImplementations() {
        register { RxNSTextStorageDelegateProxy(textStorage: $0) }
    }
}

extension RxNSTextStorageDelegateProxy: NSTextStorageDelegate {}
