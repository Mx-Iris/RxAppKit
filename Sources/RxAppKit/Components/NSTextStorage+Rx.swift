import AppKit
import RxSwift

extension Reactive where Base: NSTextStorage {

    /// Reactive wrapper for `delegate`.
    ///
    /// For more information take a look at `DelegateProxyType` protocol documentation.
    public var delegate: DelegateProxy<NSTextStorage, NSTextStorageDelegate> {
        return RxNSTextStorageDelegateProxy.proxy(for: base)
    }

    public var willProcessEditingRangeChangeInLength: Observable<(editedMask: NSTextStorageEditActions, editedRange: NSRange, delta: Int)> {
        return delegate
            .methodInvoked(#selector(NSTextStorageDelegate.textStorage(_:willProcessEditing:range:changeInLength:)))
            .map { a in
                let editedMask = NSTextStorageEditActions(rawValue: try castOrThrow(UInt.self, a[1]) )
                let editedRange = try castOrThrow(NSValue.self, a[2]).rangeValue
                let delta = try castOrThrow(Int.self, a[3])
                
                return (editedMask, editedRange, delta)
            }
    }
    
    /// Reactive wrapper for `delegate` message.
    public var didProcessEditingRangeChangeInLength: Observable<(editedMask: NSTextStorageEditActions, editedRange: NSRange, delta: Int)> {
        return delegate
            .methodInvoked(#selector(NSTextStorageDelegate.textStorage(_:didProcessEditing:range:changeInLength:)))
            .map { a in
                let editedMask = NSTextStorageEditActions(rawValue: try castOrThrow(UInt.self, a[1]) )
                let editedRange = try castOrThrow(NSValue.self, a[2]).rangeValue
                let delta = try castOrThrow(Int.self, a[3])
                
                return (editedMask, editedRange, delta)
            }
    }
}
