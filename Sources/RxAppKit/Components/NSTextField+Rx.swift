import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSTextField {
    var delegate: DelegateProxy<NSTextField, NSTextFieldDelegate> {
        RxNSTextFieldDelegateProxy.proxy(for: base)
    }
}
