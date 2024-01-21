import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSPageController {
    public var delegate: DelegateProxy<NSPageController, NSPageControllerDelegate> {
        RxNSPageControllDelegateProxy.proxy(for: base)
    }

    public func setDelegate(_ delegate: NSPageControllerDelegate) -> Disposable {
        RxNSPageControllDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    public var prepare: ControlEvent<NSViewController> {
        let source = delegate.methodInvoked(#selector(NSPageControllerDelegate.pageController(_:prepare:with:))).map { a in
            try castOrThrow(NSViewController.self, a[1])
        }
        return ControlEvent(events: source)
    }

    public var didTransition: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSPageControllerDelegate.pageController(_:didTransitionTo:))).map { _ in }
        return ControlEvent(events: source)
    }

    public var willStartLiveTransition: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSPageControllerDelegate.pageControllerWillStartLiveTransition(_:))).map { _ in }
        return ControlEvent(events: source)
    }

    public var didEndLiveTransition: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSPageControllerDelegate.pageControllerDidEndLiveTransition(_:))).map { _ in }
        return ControlEvent(events: source)
    }

    public func items<Item: PageControllerItem, Source: ObservableType>(_ source: Source)
        -> (_ itemProvider: @escaping (NSPageController, String, Item) -> NSViewController)
        -> Disposable where Source.Element == [Item] {
        return { itemProvider in
            let adapter = RxNSPageControllerAdapter<Item>(itemProvider: itemProvider)
            return self.items(adapter: adapter)(source)
        }
    }

    public func items<Adapter: RxNSPageControllerDelegateType & NSPageControllerDelegate, Source: ObservableType>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Adapter.Element == Source.Element {
        return { source in
            let adapterSubscription = RxNSPageControllDelegateProxy.proxy(for: base).setRequiredMethodsDelegate(adapter)
            let subscription = source.asObservable()
                .observe(on: MainScheduler.instance)
                .catch { error in
                    bindingError(error)
                    return .empty()
                }
                .concat(Observable.never())
                .take(until: base.rx.deallocated)
                .subscribe { [weak object = base] event in
                    guard let pageController = object else { return }
                    adapter.pageController(pageController, observedEvent: event)
                    switch event {
                    case let .error(error):
                        bindingError(error)
                        adapterSubscription.dispose()
                    case .completed:
                        adapterSubscription.dispose()
                    default:
                        break
                    }
                }
            return Disposables.create {
                adapterSubscription.dispose()
                subscription.dispose()
            }
        }
    }

    public var animateSelectedIndex: Binder<Int> {
        .init(base) { target, selectedIndex in
            NSAnimationContext.runAnimationGroup { _ in
                self.base.animator().selectedIndex = selectedIndex
            } completionHandler: {
                self.base.completeTransition()
            }
        }
    }
}
