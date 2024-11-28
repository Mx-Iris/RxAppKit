import AppKit
import RxSwift
import RxCocoa

extension NSStackView: @retroactive HasDelegate {
    public typealias Delegate = NSStackViewDelegate
}

extension Reactive where Base: NSStackView {
    public var delegate: DelegateProxy<NSStackView, NSStackViewDelegate> {
        RxNSStackViewDelegateProxy.proxy(for: base)
    }
    
    public func setDelegate(_ delegate: NSStackViewDelegate) -> Disposable {
        RxNSStackViewDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }
    
    public var willDetach: ControlEvent<[NSView]> {
        let source = delegate.methodInvoked(#selector(NSStackViewDelegate.stackView(_:willDetach:))).map { a in
            try castOrThrow([NSView].self, a[1])
        }
        return ControlEvent(events: source)
    }
    
    public var didReattach: ControlEvent<[NSView]> {
        let source = delegate.methodInvoked(#selector(NSStackViewDelegate.stackView(_:didReattach:))).map { a in
            try castOrThrow([NSView].self, a[1])
        }
        return ControlEvent(events: source)
    }
}



