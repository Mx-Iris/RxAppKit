import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSPageController {
    var delegate: DelegateProxy<NSPageController, NSPageControllerDelegate> {
        RxNSPageControllDelegateProxy.proxy(for: base)
    }

    func setDelegate(_ delegate: NSPageControllerDelegate) -> Disposable {
        RxNSPageControllDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    var prepare: ControlEvent<NSViewController> {
        let source = delegate.methodInvoked(#selector(NSPageControllerDelegate.pageController(_:prepare:with:))).map { a in
            try castOrThrow(NSViewController.self, a[1])
        }
        return ControlEvent(events: source)
    }

    var didTransition: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSPageControllerDelegate.pageController(_:didTransitionTo:))).map { _ in }
        return ControlEvent(events: source)
    }

    var willStartLiveTransition: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSPageControllerDelegate.pageControllerWillStartLiveTransition(_:))).map { _ in }
        return ControlEvent(events: source)
    }

    var didEndLiveTransition: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSPageControllerDelegate.pageControllerDidEndLiveTransition(_:))).map { _ in }
        return ControlEvent(events: source)
    }
}
