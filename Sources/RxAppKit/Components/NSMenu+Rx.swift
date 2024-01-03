import AppKit
import RxSwift
import RxCocoa

public protocol RxMenuItemRepresentable {
    var title: String { get }
    var keyEquivalent: String { get }
}

extension RxMenuItemRepresentable {
    public var keyEquivalent: String { "" }
}

extension String: RxMenuItemRepresentable {
    public var title: String { self }
    public var keyEquivalent: String { "" }
}

extension Reactive where Base: NSMenu {
    public var delegate: DelegateProxy<NSMenu, NSMenuDelegate> {
        RxNSMenuDelegateProxy.proxy(for: base)
    }

    public func setDelegate(_ delegate: NSMenuDelegate) -> Disposable {
        RxNSMenuDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    public var willSendAction: ControlEvent<Void> {
        controlEventForNotification(Base.willSendActionNotification, object: base)
    }

    public var didSendAction: ControlEvent<Void> {
        controlEventForNotification(Base.didSendActionNotification, object: base)
    }

    public var didAddItem: ControlEvent<Int> {
        controlEventForNotification(Base.didAddItemNotification, object: base) {
            try castOrThrow(NSNumber.self, $0.userInfo?["NSMenuItemIndex"]).intValue
        }
    }

    public var didRemoveItem: ControlEvent<Int> {
        controlEventForNotification(Base.didRemoveItemNotification, object: base) {
            try castOrThrow(NSNumber.self, $0.userInfo?["NSMenuItemIndex"]).intValue
        }
    }

    public var didChangeItem: ControlEvent<Int> {
        controlEventForNotification(Base.didChangeItemNotification, object: base) {
            try castOrThrow(NSNumber.self, $0.userInfo?["NSMenuItemIndex"]).intValue
        }
    }

    public var didBeginTracking: ControlEvent<Void> {
        controlEventForNotification(Base.didBeginTrackingNotification, object: base)
    }

    public var didEndTracking: ControlEvent<Void> {
        controlEventForNotification(Base.didEndTrackingNotification, object: base)
    }

    public var willHighlight: ControlEvent<NSMenuItem?> {
        let source = delegate.methodInvoked(#selector(NSMenuDelegate.menu(_:willHighlight:))).map { a in
            try castOrThrow(NSMenuItem?.self, a[1])
        }
        return ControlEvent(events: source)
    }

    public var willOpen: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSMenuDelegate.menuWillOpen(_:))).map { _ in
        }
        return ControlEvent(events: source)
    }

    public var didClose: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSMenuDelegate.menuDidClose(_:))).map { _ in
        }
        return ControlEvent(events: source)
    }

    public var needsUpdate: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSMenuDelegate.menuNeedsUpdate(_:))).map {
            _ in
        }
        return ControlEvent(events: source)
    }

    public func items<Element: RxMenuItemRepresentable, Source: ObservableType, Collection: RandomAccessCollection>(source: Source)
        -> (_ itemConfiguration: @escaping (NSMenuItem, Element) -> Void)
        -> Disposable where Source.Element == Collection, Collection.Element == Element {
        return { itemConfiguration in
            source.subscribe(onNext: { [weak base] items in
                guard let menu = base else { return }
                menu.removeAllItems()
                items.forEach { item in
                    let menuItem = NSMenuItem(title: item.title, action: #selector(proxy.run(_:)), keyEquivalent: item.keyEquivalent)
                    menuItem.target = proxy
                    menuItem.action = #selector(proxy.run(_:))
                    menuItem.representedObject = item
                    itemConfiguration(menuItem, item)
                    menu.addItem(menuItem)
                }
            })
        }
    }

    private var proxy: RxNSMenuProxy {
        associatedValue { .init(menu: $0) }
    }

    public func itemSelected<T>(_ itemType: T.Type) -> ControlEvent<(menuItem: NSMenuItem, item: T)> {
        let source = proxy.didSelectItem.compactMap {
            if let item = $1 as? T {
                return (menuItem: $0, item: item)
            } else {
                return nil
            }
        }
        return ControlEvent(events: source)
    }

    public func itemSelectedOnState<T>(_ itemType: T.Type) -> ControlEvent<(menuItem: NSMenuItem, item: T)> {
        let source = itemSelected(T.self).do(onNext: { [weak base] element in
            guard let menu = base else { return }
            menu.items.forEach { $0.state = .off }
            element.menuItem.state = .on
        })
        return ControlEvent(events: source)
    }

    public func itemSelectedOnState() -> ControlEvent<NSMenuItem> {
        let source = itemSelectedOnState(Any?.self).map(\.menuItem)
        return ControlEvent(events: source)
    }

    public var onStateAtTag: Binder<Int> {
        .init(base) { menu, tag in
            guard let item = menu.item(withTag: tag) else { return }
            menu.items.forEach { $0.state = .off }
            item.state = .on
        }
    }

    public var onStateAtIndex: Binder<Int> {
        .init(base) { menu, index in
            menu.items.forEach { $0.state = .off }
            menu.items[index].state = .on
        }
    }

    public var onStateAtTitle: Binder<String> {
        .init(base) { menu, title in
            guard let item = menu.item(withTitle: title) else { return }

            menu.items.forEach { $0.state = .off }
            item.state = .on
        }
    }
}
