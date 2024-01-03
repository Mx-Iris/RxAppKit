#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

class RxNSMenuProxy {
    private unowned let menu: NSMenu

    init(menu: NSMenu) {
        self.menu = menu
    }

    let didSelectItem = PublishRelay<(NSMenuItem, Any?)>()

    @objc func run(_ menuItem: NSMenuItem) {
        didSelectItem.accept((menuItem, menuItem.representedObject))
    }
}
#endif
