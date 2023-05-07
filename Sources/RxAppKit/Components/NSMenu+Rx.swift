import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSMenu {
    public var delegate: DelegateProxy<NSMenu, NSMenuDelegate> {
        RxNSMenuDelegateProxy.proxy(for: base)
    }

    public func setDelegate(_ delegate: NSMenuDelegate) -> Disposable {
        RxNSMenuDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    var willHighlight: ControlEvent<NSMenuItem?> {
        let source = delegate.methodInvoked(#selector(NSMenuDelegate.menu(_:willHighlight:))).map { a in
            try castOrThrow(NSMenuItem?.self, a[1])
        }
        return ControlEvent(events: source)
    }

    var willOpen: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSMenuDelegate.menuWillOpen(_:))).map { _ in
        }
        return ControlEvent(events: source)
    }

    var didClose: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSMenuDelegate.menuDidClose(_:))).map { _ in
        }
        return ControlEvent(events: source)
    }

    var needsUpdate: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSMenuDelegate.menuNeedsUpdate(_:))).map {
            _ in
        }
        return ControlEvent(events: source)
    }
}

extension NSMenu: HasDelegate {
    public typealias Delegate = NSMenuDelegate
}

class RxNSMenuDelegateProxy: DelegateProxy<NSMenu, NSMenuDelegate>, DelegateProxyType, NSMenuDelegate {
    public private(set) weak var menu: NSMenu?

    init(menu: NSMenu) {
        self.menu = menu
        super.init(parentObject: menu, delegateProxy: RxNSMenuDelegateProxy.self)
    }

    static func registerKnownImplementations() {
        register { RxNSMenuDelegateProxy(menu: $0) }
    }
}
