import AppKit
import RxSwift
import RxCocoa

extension NSPopover: HasDelegate {
    public typealias Delegate = NSPopoverDelegate
}

extension Reactive where Base: NSPopover {
    public var delegate: DelegateProxy<NSPopover, NSPopoverDelegate> {
        RxNSPopoverDelegateProxy.proxy(for: base)
    }

    public func setDelegate(_ delegate: NSPopoverDelegate) -> Disposable {
        RxNSPopoverDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    public var willShow: ControlEvent<Void> {
        controlEventForNotification(Base.willShowNotification, object: base)
    }

    public var willClose: ControlEvent<NSPopover.CloseReason> {
        controlEventForNotification(Base.willCloseNotification, object: base) {
            try .init(rawValue: castOrThrow(String.self, $0.userInfo?[Base.closeReasonUserInfoKey]))
        }
    }

    public var didShow: ControlEvent<Void> {
        controlEventForNotification(Base.didShowNotification, object: base)
    }

    public var didClose: ControlEvent<Void> {
        controlEventForNotification(Base.didCloseNotification, object: base)
    }

    public var didDetach: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSPopoverDelegate.popoverDidDetach(_:))).map { _ in }
        return ControlEvent(events: source)
    }
}
