import AppKit
import RxSwift
import RxCocoa

public protocol RxMenuItemRepresentable {
    var title: String { get }
    var keyEquivalent: String { get }
}

extension Reactive where Base: NSMenu {
    public var delegate: DelegateProxy<NSMenu, NSMenuDelegate> {
        RxNSMenuDelegateProxy.proxy(for: base)
    }

    public func setDelegate(_ delegate: NSMenuDelegate) -> Disposable {
        RxNSMenuDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
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

    public func items<Element: RxMenuItemRepresentable, Source: ObservableType>(source: Source)
        -> (_ itemProvider: @escaping (Element) -> Void)
        -> Disposable where Source.Element == [Element] {
        return { itemProvider in
            source.subscribe(onNext: { [weak base] items in
                guard let menu = base else { return }
                menu.removeAllItems()
                items.forEach { item in
                    let menuItem = NSMenuItem(title: item.title, action: #selector(proxy.run(_:)), keyEquivalent: item.keyEquivalent)
                    menuItem.target = proxy
                    menuItem.action = #selector(proxy.run(_:))
                    let actionBlock: () -> Any = {
                        itemProvider(item)
                        return item
                    }
                    menuItem.representedObject = actionBlock
                    menu.addItem(menuItem)
                }
            })
        }
    }

    private var proxy: RxNSMenuProxy {
        associatedValue { .init(menu: $0) }
    }

    public func itemSelected<T>(_ itemType: T.Type) -> ControlEvent<T> {
        let source = proxy.didSelectItem.compactMap { $0 as? T }
        return ControlEvent(events: source)
    }
}

private class RxNSMenuProxy {
    private unowned let menu: NSMenu

    init(menu: NSMenu) {
        self.menu = menu
    }

    let didSelectItem = PublishRelay<Any>()

    @objc func run(_ menuItem: NSMenuItem) {
        let item = (menuItem.representedObject as! () -> Any)()
        didSelectItem.accept(item)
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
