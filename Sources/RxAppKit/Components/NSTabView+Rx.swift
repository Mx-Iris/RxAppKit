import AppKit
import RxSwift

public extension Reactive where Base: NSTabView {
    var delegate: DelegateProxy<NSTabView, NSTabViewDelegate> {
        RxNSTabViewDelegateProxy.proxy(for: base)
    }

    func setDelegate(_ delegate: NSTabViewDelegate) -> Disposable {
        RxNSTabViewDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    var willSelect: ControlEvent<NSTabViewItem> {
        let source = delegate.methodInvoked(#selector(NSTabViewDelegate.tabView(_:willSelect:))).map { a in
            try castOrThrow(NSTabViewItem.self, a[1])
        }
        return ControlEvent(events: source)
    }

    var didSelect: ControlEvent<NSTabViewItem> {
        let source = delegate.methodInvoked(#selector(NSTabViewDelegate.tabView(_:didSelect:))).map { a in
            try castOrThrow(NSTabViewItem.self, a[1])
        }
        return ControlEvent(events: source)
    }

    var didChangeNumber: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSTabViewDelegate.tabViewDidChangeNumberOfTabViewItems(_:))).map { _ in }
        return ControlEvent(events: source)
    }

    var items: Binder<[NSTabViewItem]> {
        .init(base) { target, tabViewItems in
            target.tabViewItems.forEach(target.removeTabViewItem(_:))
            tabViewItems.forEach(target.addTabViewItem(_:))
        }
    }
}
