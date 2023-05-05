import AppKit
import RxSwift
import RxCocoa

extension NSPageController: HasDelegate {
    public typealias Delegate = NSPageControllerDelegate
}

class RxNSPageControllDelegateProxy: DelegateProxy<NSPageController, NSPageControllerDelegate>, DelegateProxyType, NSPageControllerDelegate {
    public private(set) weak var pageController: NSPageController?

    init(pageControll: NSPageController) {
        self.pageController = pageControll
        super.init(parentObject: pageControll, delegateProxy: RxNSPageControllDelegateProxy.self)
    }

    static func registerKnownImplementations() {
        register { RxNSPageControllDelegateProxy(pageControll: $0) }
    }
}
