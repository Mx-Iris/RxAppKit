import AppKit
import RxSwift

extension Reactive where Base: NSTabView {
    
    public var selectedTabViewItemIndex: Binder<Int> {
        .init(base) { target, index in
            target.selectTabViewItem(at: index)
        }
    }
    
    public var delegate: DelegateProxy<NSTabView, NSTabViewDelegate> {
        RxNSTabViewDelegateProxy.proxy(for: base)
    }

    public func setDelegate(_ delegate: NSTabViewDelegate) -> Disposable {
        RxNSTabViewDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    public var willSelect: ControlEvent<NSTabViewItem> {
        let source = delegate.methodInvoked(#selector(NSTabViewDelegate.tabView(_:willSelect:))).map { a in
            try castOrThrow(NSTabViewItem.self, a[1])
        }
        return ControlEvent(events: source)
    }

    public var didSelect: ControlEvent<NSTabViewItem> {
        let source = delegate.methodInvoked(#selector(NSTabViewDelegate.tabView(_:didSelect:))).map { a in
            try castOrThrow(NSTabViewItem.self, a[1])
        }
        return ControlEvent(events: source)
    }

    public var didChangeNumber: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSTabViewDelegate.tabViewDidChangeNumberOfTabViewItems(_:))).map { _ in }
        return ControlEvent(events: source)
    }

    public func items() -> Binder<[NSTabViewItem]> {
        .init(base) { target, tabViewItems in
            target.tabViewItems.forEach(target.removeTabViewItem(_:))
            tabViewItems.forEach(target.addTabViewItem(_:))
        }
    }
}
