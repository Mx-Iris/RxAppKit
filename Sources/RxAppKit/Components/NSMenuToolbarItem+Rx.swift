#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

@available(macOS 14.0, *)
extension Reactive where Base: NSMenuToolbarItem {
    /// Binds section-grouped items to a menu toolbar item using NSMenuItem.sectionHeader.
    ///
    /// The binder element is `([Section], AnyHashable?)` — sections and the selected item's
    /// representedObject. Sets `state = .on` on the menu item matching the selected value.
    ///
    /// Usage with `Driver.combineLatest`:
    /// ```
    /// Driver.combineLatest(sectionsDriver, selectedIDDriver)
    ///     .drive(toolbarItem.rx.sectionItems(
    ///         sectionTitle: { $0.name },
    ///         items: { $0.items },
    ///         ...
    ///     ))
    /// ```
    public func sectionItems<Section, Item>(
        sectionTitle: @escaping (Section) -> String,
        items: @escaping (Section) -> [Item],
        itemTitle: @escaping (Item) -> String,
        itemImage: ((Item) -> NSImage?)? = nil,
        itemRepresentedObject: @escaping (Item) -> AnyHashable,
        configureMenuItem: ((NSMenuItem, Item) -> Void)? = nil
    ) -> Binder<([Section], AnyHashable?)> {
        Binder(base) { toolbarItem, value in
            let (sections, selectedRepresentedObject) = value
            let menu = toolbarItem.menu ?? NSMenu()

            menu.removeAllItems()

            let proxy = toolbarItem.rx.menuProxy

            for section in sections {
                let header = NSMenuItem.sectionHeader(title: sectionTitle(section))
                menu.addItem(header)

                for item in items(section) {
                    let representedObject = itemRepresentedObject(item)
                    let menuItem = NSMenuItem(title: itemTitle(item), action: #selector(proxy.run(_:)), keyEquivalent: "")
                    menuItem.target = proxy
                    menuItem.image = itemImage?(item)
                    menuItem.representedObject = representedObject
                    if let selectedRepresentedObject, representedObject == selectedRepresentedObject {
                        menuItem.state = .on
                    }
                    configureMenuItem?(menuItem, item)
                    menu.addItem(menuItem)
                }
            }

            toolbarItem.menu = menu
        }
    }

    /// Emits the representedObject of the clicked menu item.
    public func menuItemClick<T: Hashable>(_ type: T.Type = T.self) -> ControlEvent<T?> {
        let source = menuProxy.didSelectItem.map { $0.1 as? T }
        return ControlEvent(events: source)
    }

    fileprivate var menuProxy: RxNSMenuToolbarItemProxy {
        associatedValue { _ in RxNSMenuToolbarItemProxy() }
    }
}

/// Action trampoline for NSMenuToolbarItem menu item clicks.
class RxNSMenuToolbarItemProxy: NSObject {
    let didSelectItem = PublishRelay<(NSMenuItem, Any?)>()

    @objc func run(_ menuItem: NSMenuItem) {
        didSelectItem.accept((menuItem, menuItem.representedObject))
    }
}

#endif
