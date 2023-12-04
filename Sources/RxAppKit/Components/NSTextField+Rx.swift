import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSTextField {
    public var delegate: DelegateProxy<NSTextField, NSTextFieldDelegate> {
        RxNSTextFieldDelegateProxy.proxy(for: base)
    }

    public var text: ControlProperty<String> {
        controlProperty(forKeyPath: \.stringValue)
    }
}
