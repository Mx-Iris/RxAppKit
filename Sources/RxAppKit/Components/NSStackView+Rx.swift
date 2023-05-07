import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSStackView {
    public var delegate: DelegateProxy<NSStackView, NSStackViewDelegate> {
        RxNSStackViewDelegateProxy.proxy(for: base)
    }
    
    public func setDelegate(_ delegate: NSStackViewDelegate) -> Disposable {
        RxNSStackViewDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }
    
    var willDetach: ControlEvent<[NSView]> {
        let source = delegate.methodInvoked(#selector(NSStackViewDelegate.stackView(_:willDetach:))).map { a in
            try castOrThrow([NSView].self, a[1])
        }
        return ControlEvent(events: source)
    }
    
    var didReattach: ControlEvent<[NSView]> {
        let source = delegate.methodInvoked(#selector(NSStackViewDelegate.stackView(_:didReattach:))).map { a in
            try castOrThrow([NSView].self, a[1])
        }
        return ControlEvent(events: source)
    }
}

extension NSStackView: HasDelegate {
    public typealias Delegate = NSStackViewDelegate
}

class RxNSStackViewDelegateProxy: DelegateProxy<NSStackView, NSStackViewDelegate>, DelegateProxyType, NSStackViewDelegate {
    public private(set) weak var stackView: NSStackView?
    
    init(stackView: NSStackView) {
        self.stackView = stackView
        super.init(parentObject: stackView, delegateProxy: RxNSStackViewDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        register { RxNSStackViewDelegateProxy(stackView: $0) }
    }
}
