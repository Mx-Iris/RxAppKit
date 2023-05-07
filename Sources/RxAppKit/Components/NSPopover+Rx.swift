import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSPopover {
    var delegate: DelegateProxy<NSPopover, NSPopoverDelegate> {
        RxNSPopoverDelegateProxy.proxy(for: base)
    }

    func setDelegate(_ delegate: NSPopoverDelegate) -> Disposable {
        RxNSPopoverDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    var willShow: ControlEvent<Void> {
        controlEventForNotification(Base.willShowNotification, object: base)
    }

    var willClose: ControlEvent<NSPopover.CloseReason> {
        controlEventForNotification(Base.willCloseNotification, object: base) {
            try .init(rawValue: castOrThrow(String.self, $0.userInfo?[Base.closeReasonUserInfoKey]))
        }
    }

    var didShow: ControlEvent<Void> {
        controlEventForNotification(Base.didShowNotification, object: base)
    }

    var didClose: ControlEvent<Void> {
        controlEventForNotification(Base.didCloseNotification, object: base)
    }

    var didDetach: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSPopoverDelegate.popoverDidDetach(_:))).map { _ in }
        return ControlEvent(events: source)
    }
}

extension NSPopover: HasDelegate {
    public typealias Delegate = NSPopoverDelegate
}

class RxNSPopoverDelegateProxy: DelegateProxy<NSPopover, NSPopoverDelegate>, DelegateProxyType, NSPopoverDelegate {
    public private(set) weak var popover: NSPopover?

    init(popover: NSPopover) {
        self.popover = popover
        super.init(parentObject: popover, delegateProxy: RxNSPopoverDelegateProxy.self)
    }

    static func registerKnownImplementations() {
        register { RxNSPopoverDelegateProxy(popover: $0) }
    }
}
