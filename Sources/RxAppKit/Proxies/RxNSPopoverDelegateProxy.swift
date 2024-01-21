import AppKit
import RxSwift
import RxCocoa

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
