#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

extension NSMenu: @retroactive HasDelegate {
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

#endif
