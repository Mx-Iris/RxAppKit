import AppKit
import RxSwift
import RxCocoa

extension NSTabView: @retroactive HasDelegate {
    public typealias Delegate = NSTabViewDelegate
}

class RxNSTabViewDelegateProxy: DelegateProxy<NSTabView, NSTabViewDelegate>, DelegateProxyType, NSTabViewDelegate {
    public private(set) weak var tabView: NSTabView?

    init(tabView: NSTabView) {
        self.tabView = tabView
        super.init(parentObject: tabView, delegateProxy: RxNSTabViewDelegateProxy.self)
    }

    static func registerKnownImplementations() {
        register { RxNSTabViewDelegateProxy(tabView: $0) }
    }
}
